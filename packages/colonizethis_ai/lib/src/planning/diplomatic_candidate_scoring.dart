import 'dart:math' as math;

import '../perception/perception_snapshot.dart';
import 'diplomatic_candidate_scoring_declare_war.dart';
import 'diplomatic_candidate_scoring_declare_war_context.dart';
import 'diplomatic_candidate_scoring_establish_overture.dart';
import 'diplomatic_candidate_scoring_offer_peace.dart';
import 'diplomatic_candidate_scoring_shared.dart';
import 'diplomatic_scoring_context.dart';
import 'goal_manager.dart';
import 'phase_planner_dispatch.dart';
import 'planning_imports.dart';
import 'planning_helpers.dart' show kDiplomaticDefaultBaseScore;
import 'war_desire_calculator.dart';

/// Bundles inputs for [computeDiplomaticCandidateScores] (Refs #3977 AC5).
final class DiplomaticCandidateScoringInput {
  const DiplomaticCandidateScoringInput({
    required this.candidates,
    required this.nationId,
    required this.game,
    required this.snapshot,
    required this.config,
    this.primaryGoal,
    this.sameTurnPriorDiplomaticOrders,
    this.phasePlan,
  });

  final List<DiplomaticOrder> candidates;
  final String nationId;
  final Game game;
  final AIWorldSnapshot snapshot;
  final AIConfig config;
  final StrategicGoal? primaryGoal;
  final Orders? sameTurnPriorDiplomaticOrders;
  final PhasePlanOutcome? phasePlan;
}

/// Pre-weighted-random scores for diplomatic order candidates (0 = suppressed).
/// Exposed for deterministic tests; [runDomainPlanners] uses the same values.
List<int> computeDiplomaticCandidateScores(
  DiplomaticCandidateScoringInput input,
) {
  final candidates = input.candidates;
  final nationId = input.nationId;
  final game = input.game;
  final snapshot = input.snapshot;
  final config = input.config;
  final primaryGoal = input.primaryGoal;
  final sameTurnPriorDiplomaticOrders = input.sameTurnPriorDiplomaticOrders;
  final phasePlan = input.phasePlan;
  final agendaId = config.hiddenAgendaId;
  final thresholds = resolveThresholds(
    config.personalityId,
    overrides: config.parameterOverrides,
  );
  var maxRelationForDeclareWar = getDeclareWarMaxRelationScore(agendaId);
  final behindVictoryPace =
      snapshot.conquest.provincesToVictory >
      kConquerScoreFloorProvincesToVictoryThreshold;
  final suppressGpDeclareWar =
      snapshot.conquest.provincesToVictory >
      kSuppressGpDeclareWarMinProvincesToVictory;
  final provinceOwner = getProvinceOwnerMap(game);
  final invadableOwners = <String>{
    for (final provinceId in snapshot.conquest.invadableProvinceIdsSorted)
      provinceOwner[provinceId] ?? '',
    for (final provinceId
        in snapshot.colonial.invadableNewWorldProvinceIdsSorted)
      provinceOwner[provinceId] ?? '',
  }..remove('');
  const warCooldownTurns = 4;
  const improveRelationsCooldownTurns = 2;
  final currentTurn = game.worldState.turnState.turnNumber;
  // Phase 6b (SPEC/program/worldstate-projection.md slice 7; Refs #3393):
  // replace the O(provinces x minors) nested old-world owner scan with the
  // memoised projection via the existing `_minorOwnsOldWorldProvinces` helper
  // (`ProvinceOwnerCache.ownsAnyInRegion(minorId, kRegionOldWorld)`).
  // Behaviour-preserving: the result is true iff some minor owns a non-empty
  // old-world province — exactly the prior `oldWorld.provinces.any` predicate
  // (minor ids are non-empty, and an empty/`null` owner never equals a minor id).
  final anyMinorOwnsOldWorld = game.minorNations.any(
    (m) => minorOwnsOldWorldProvinces(game, m.id),
  );
  final warDesireByTarget = <String, int>{};
  int memoizedWarDesire(String targetFactionId, num relationScore) {
    return warDesireByTarget.putIfAbsent(
      targetFactionId,
      () => computeWarDesireScore(
        game: game,
        nationId: nationId,
        targetFactionId: targetFactionId,
        relationScore: relationScore,
      ),
    );
  }

  final warDesireForTarget = memoizedWarDesire;

  return candidates.map((o) {
    var s = kDiplomaticDefaultBaseScore;
    switch (o.type) {
      case DiplomaticOrderType.offerPeace:
        s = scoreOfferPeaceDiplomaticOrder(
          DiplomaticScoringContext(
            order: o,
            nationId: nationId,
            game: game,
            snapshot: snapshot,
            provinceOwner: provinceOwner,
            currentTurn: currentTurn,
            sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
            warDesireForTarget: warDesireForTarget,
          ),
          OfferPeaceScoringParams(
            agendaId: agendaId,
            thresholds: thresholds,
            invadableOwners: invadableOwners,
          ),
        );
        break;
      case DiplomaticOrderType.alliance:
        s += getAgendaAllianceAcceptanceModifier(agendaId);
        s += (thresholds.allianceTendency - 50);
        break;
      case DiplomaticOrderType.breakAlliance:
        // Voluntary alliance break (Refs #3758 R6). Backstabber/warmonger lean
        // toward breaking (treaty-breaking modifier); the isolationist
        // "cancels alliances" so its negative alliance-acceptance modifier
        // inverts to a break boost, while peacemaker and high alliance-tendency
        // personalities resist. SPEC/ai/hidden-agendas.md § Treaty breaking.
        s += getAgendaTreatyBreakingModifier(agendaId);
        s -= getAgendaAllianceAcceptanceModifier(agendaId);
        s -= (thresholds.allianceTendency - 50);
        break;
      case DiplomaticOrderType.boycott:
        // Boycott colony trade embargo against another GP (Refs #3758 R5). A
        // hostile economic action: backstabber/warmonger agendas lean toward it
        // (treaty-breaking modifier), the peacemaker resists (peace-acceptance
        // +30 inverts to −30 while the warmonger −25 inverts to +25), and high
        // warLikelihood personalities lean toward it. Deeper trade-volume /
        // economic-damage weighting is a deferred follow-up (Refs #3758 R12).
        // SPEC/ai/hidden-agendas.md § Treaty breaking (Boycott scoring).
        s += getAgendaTreatyBreakingModifier(agendaId);
        s -= getAgendaPeaceAcceptanceModifier(agendaId);
        s += (thresholds.warLikelihood - 50);
        break;
      case DiplomaticOrderType.declareWar:
        s = scoreDeclareWarDiplomaticOrder(
          DeclareWarTargetContext.build(
            order: o,
            nationId: nationId,
            game: game,
            snapshot: snapshot,
            agendaId: agendaId,
            thresholds: thresholds,
            maxRelationForDeclareWar: maxRelationForDeclareWar,
            behindVictoryPace: behindVictoryPace,
            suppressGpDeclareWar: suppressGpDeclareWar,
            invadableOwners: invadableOwners,
            provinceOwner: provinceOwner,
            warCooldownTurns: warCooldownTurns,
            currentTurn: currentTurn,
            anyMinorOwnsOldWorld: anyMinorOwnsOldWorld,
            primaryGoal: primaryGoal,
            warDesireForTarget: warDesireForTarget,
            phasePlan: phasePlan,
          ),
          sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
        );
        break;
      case DiplomaticOrderType.establishOverture:
        s = scoreEstablishOvertureDiplomaticOrder(
          DiplomaticScoringContext(
            order: o,
            nationId: nationId,
            game: game,
            snapshot: snapshot,
            provinceOwner: provinceOwner,
            currentTurn: currentTurn,
            sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
            warDesireForTarget: warDesireForTarget,
          ),
          EstablishOvertureScoringParams(
            thresholds: thresholds,
            improveRelationsCooldownTurns: improveRelationsCooldownTurns,
          ),
        );
        break;
      default:
        break;
    }
    return s == 0 ? 0 : math.max(1, s);
  }).toList();
}
