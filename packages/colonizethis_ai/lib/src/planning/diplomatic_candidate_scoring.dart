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
import 'planning_helpers.dart' show gpFactionIdsAtWarWith;
import 'war_desire_calculator.dart';

part 'diplomatic_candidate_scoring_offer_peace.dart';
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
  final thresholds = getThresholdsForLeader(config.personalityId);
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
  final anyMinorOwnsOldWorld = game.worldState.oldWorld.provinces.any(
    (p) =>
        p.ownerId != null &&
        p.ownerId!.isNotEmpty &&
        game.minorNations.any((m) => m.id == p.ownerId),
  );
  final warDesireByTarget = <String, int>{};
  int warDesireForTarget(String targetFactionId, int relationScore) {
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
          final improveRelationsDesire = 100 - warDesire;
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

bool _isDecisionOnCooldown({
  required Game game,
  required String actorFactionId,
  required String targetFactionId,
  required List<DiplomaticEventType> eventTypes,
  required int cooldownTurns,
  required int currentTurn,
}) {
  for (final event in game.diplomaticHistoryEvents.reversed) {
    if (!eventTypes.contains(event.type)) continue;
    if (event.fromFactionId != actorFactionId) continue;
    if (event.toFactionId != targetFactionId) continue;
    return (currentTurn - event.turn) < cooldownTurns;
  }
  return false;
}
