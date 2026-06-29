import 'dart:math' as math;

import '../perception/perception_snapshot.dart';
import '../util/faction_query.dart';
import 'army_conquest_prep.dart';
import 'planning_imports.dart';
import 'expand_phase_planner.dart';
import 'goal_manager.dart';
import 'observer_goal_phase.dart';
import 'phase_planner_diplomacy_filter.dart';
import 'phase_planner_dispatch.dart';
import 'planning_helpers.dart'
    show
        anyInvadableProvinceOwnedByGreatPower,
        anyInvadableProvinceOwnedByMinor,
        atWarGreatPowerOrderTarget,
        atWarPeaceTargetBonus,
        factionOwnsInvadableOldWorldProvince,
        gpFactionIdsAtWarWith,
        hasRecentDiplomaticEventWithinCooldown,
        isAtWarWithAnyGreatPower,
        isOwnOldWorldBelowConquestQuota,
        isOwnOldWorldExpansionStalled,
        mutualExhaustedGpStalemateSideQualifies,
        orderTargetIsAtWarInvadableBlocker;
import 'war_desire_calculator.dart';

part 'diplomatic_candidate_scoring_offer_peace.dart';
part 'diplomatic_candidate_scoring_declare_war_context.dart';
part 'diplomatic_candidate_scoring_declare_war.dart';
part 'diplomatic_candidate_scoring_declare_war_bonuses.dart';

final _log = packageLogger();

/// Pre-weighted-random scores for diplomatic order candidates (0 = suppressed).
/// Exposed for deterministic tests; [runDomainPlanners] uses the same values.
List<int> computeDiplomaticCandidateScores({
  required List<DiplomaticOrder> candidates,
  required String nationId,
  required Game game,
  required AIWorldSnapshot snapshot,
  required AIConfig config,
  StrategicGoal? primaryGoal,
  Orders? sameTurnPriorDiplomaticOrders,
  PhasePlanOutcome? phasePlan,
}) {
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
    (m) => _minorOwnsOldWorldProvinces(game, m.id),
  );
  final warDesireByTarget = <String, int>{};
  int warDesireForTarget(String targetFactionId, num relationScore) {
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

  return candidates.map((o) {
    var s = 50;
    switch (o.type) {
      case DiplomaticOrderType.offerPeace:
        s = _scoreOfferPeaceDiplomaticOrder(
          order: o,
          nationId: nationId,
          game: game,
          snapshot: snapshot,
          agendaId: agendaId,
          thresholds: thresholds,
          provinceOwner: provinceOwner,
          invadableOwners: invadableOwners,
          warDesireForTarget: warDesireForTarget,
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
        s = _scoreDeclareWarDiplomaticOrder(
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
          sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
          phasePlan: phasePlan,
        );
        break;
      case DiplomaticOrderType.establishOverture:
        {
          if (shouldSuppressNewWorldColonialOrders(
                snapshot: snapshot,
                game: game,
              ) &&
              (isTribeFaction(game, o.targetFactionId) ||
                  snapshot.colonial.preferredColonialTargetFactionIdsSorted
                      .contains(o.targetFactionId) ||
                  snapshot.colonial.invadableNewWorldProvinceIdsSorted.any(
                    (pid) => provinceOwner[pid] == o.targetFactionId,
                  ))) {
            s = 0;
            break;
          }
          if (_isDecisionOnCooldown(
            game: game,
            actorFactionId: nationId,
            targetFactionId: o.targetFactionId,
            eventTypes: const [
              DiplomaticEventType.overtureAccepted,
              DiplomaticEventType.overtureRejected,
            ],
            cooldownTurns: improveRelationsCooldownTurns,
            currentTurn: currentTurn,
          )) {
            s = 0;
            break;
          }
          final rel = snapshot.relations[o.targetFactionId];
          final warDesire = warDesireForTarget(
            o.targetFactionId,
            rel?.score ?? 50,
          );
          var improveRelationsDesire = 100 - warDesire;
          // Decay-aware skip (Refs #3758 S8; #3753 R9.3/R9.4). A below-neutral
          // relation at peace drifts +relationDecayPerTurn toward equilibrium
          // 50 on its own at the end of the Diplomacy phase unless an event
          // changes the pair this turn (which blocks decay). When natural decay
          // will do the improving, the AI discounts its improve-relations
          // urgency by the share of the gap-to-equilibrium that one decay step
          // closes, so a pair decay restores to neutral next turn is credited
          // the full reduction while a deeply hostile pair is barely credited.
          // SPEC/ai/phase-planner-architecture.md § Decay-aware overture.
          if (rel != null &&
              rel.atPeace &&
              rel.score < relationScoreNeutral &&
              !_pairHasScheduledRelationEventThisTurn(
                sameTurnPriorDiplomaticOrders: sameTurnPriorDiplomaticOrders,
                nationId: nationId,
                targetFactionId: o.targetFactionId,
              )) {
            final num gap = relationScoreNeutral - rel.score;
            final num decayCovered = math.min(relationDecayPerTurn, gap);
            final reduction =
                (decayCovered / gap * kEstablishOvertureDecayCreditMax).round();
            improveRelationsDesire -= reduction;
          }
          s += (improveRelationsDesire - 50);
          s += (thresholds.allianceTendency - 50);
          if (snapshot.colonial.preferredColonialTargetFactionIdsSorted
              .contains(o.targetFactionId)) {
            s += kEstablishOvertureColonialTribeBonus;
          }
          final ownsInvadableNw = snapshot
              .colonial
              .invadableNewWorldProvinceIdsSorted
              .any((pid) => provinceOwner[pid] == o.targetFactionId);
          if (ownsInvadableNw && isTribeFaction(game, o.targetFactionId)) {
            s += kEstablishOvertureColonialInvadableOwnerBonus;
          }
          break;
        }
      default:
        break;
    }
    return s == 0 ? 0 : math.max(1, s);
  }).toList();
}

bool _minorOwnsOldWorldProvinces(Game game, String minorId) =>
    ProvinceOwnerCache.of(
      game.worldState,
    ).ownsAnyInRegion(minorId, kRegionOldWorld);

Set<String> _activeOldWorldMinorConflictIds({
  required Game game,
  required String nationId,
  required int currentTurn,
  required int warCooldownTurns,
}) {
  final conflicts = <String>{};
  for (final minor in game.minorNations) {
    if (!_minorOwnsOldWorldProvinces(game, minor.id)) {
      continue;
    }
    final rel = getRelation(game, nationId, minor.id);
    if (rel?.state == RelationState.atWar) {
      conflicts.add(minor.id);
      continue;
    }
    if (_isDecisionOnCooldown(
      game: game,
      actorFactionId: nationId,
      targetFactionId: minor.id,
      eventTypes: const [DiplomaticEventType.declareWar],
      cooldownTurns: warCooldownTurns,
      currentTurn: currentTurn,
    )) {
      conflicts.add(minor.id);
    }
  }
  return conflicts;
}

/// Predicts whether the (`nationId`, `targetFactionId`) relation pair will
/// receive a same-turn relation-delta event that blocks per-turn decay (Refs
/// #3753 R9.4). Uses the only deterministic planning-time signal available:
/// diplomatic orders earlier Full-AI players already committed this turn
/// ([sameTurnPriorDiplomaticOrders], keyed by acting player id). A prior order
/// from the target faction directed back at this AI lands an event on the
/// shared pair, so decay is skipped and the AI keeps full improve-relations
/// urgency. The predicate is intentionally conservative — any prior order from
/// the target toward this AI counts — so a false positive only preserves the
/// pre-existing (non-decay-aware) urgency. Returns false when no prior orders
/// are available.
bool _pairHasScheduledRelationEventThisTurn({
  required Orders? sameTurnPriorDiplomaticOrders,
  required String nationId,
  required String targetFactionId,
}) {
  if (sameTurnPriorDiplomaticOrders == null) return false;
  final targetOrders =
      sameTurnPriorDiplomaticOrders
          .diplomaticOrdersByPlayerId[targetFactionId] ??
      const <DiplomaticOrder>[];
  for (final order in targetOrders) {
    if (order.targetFactionId == nationId) return true;
  }
  return false;
}

bool _isDecisionOnCooldown({
  required Game game,
  required String actorFactionId,
  required String targetFactionId,
  required List<DiplomaticEventType> eventTypes,
  required int cooldownTurns,
  required int currentTurn,
}) => hasRecentDiplomaticEventWithinCooldown(
  game: game,
  currentTurn: currentTurn,
  cooldownTurns: cooldownTurns,
  matches: (event) =>
      eventTypes.contains(event.type) &&
      event.fromFactionId == actorFactionId &&
      event.toFactionId == targetFactionId,
);
