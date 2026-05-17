import 'dart:math' as math;

import 'package:colonizethis_ai/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'goal_manager.dart';
import 'war_desire_calculator.dart';

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
}) {
  final agendaId = config.hiddenAgendaId;
  final thresholds = getThresholdsForLeader(config.personalityId);
  var maxRelationForDeclareWar = getDeclareWarMaxRelationScore(agendaId);
  final behindVictoryPace = snapshot.conquest.provincesToVictory >
      kConquerScoreFloorProvincesToVictoryThreshold;
  final suppressGpDeclareWar = snapshot.conquest.provincesToVictory >
      kSuppressGpDeclareWarMinProvincesToVictory;
  final provinceOwner = getProvinceOwnerMap(game);
  final invadableOwners = <String>{
    for (final provinceId in snapshot.conquest.invadableProvinceIdsSorted)
      provinceOwner[provinceId] ?? '',
  }..remove('');
  const warCooldownTurns = 4;
  const improveRelationsCooldownTurns = 2;
  final currentTurn = game.worldState.turnState.turnNumber;
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
        {
          final rel = snapshot.relations[o.targetFactionId];
          final warDesire = warDesireForTarget(
            o.targetFactionId,
            rel?.score ?? 50,
          );
          // Lower peace desire when current war desire remains high.
          s -= (warDesire - 50);
          if (_isMinorOrTribeFaction(game, o.targetFactionId) &&
              snapshot.threats.atWarWith.contains(o.targetFactionId) &&
              !invadableOwners.contains(o.targetFactionId)) {
            s += kOfferPeaceFutileMinorWarBonus;
          }
        }
        s += getAgendaPeaceAcceptanceModifier(agendaId);
        s += (thresholds.peaceTendency - 50);
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
          primaryGoal: primaryGoal,
          warDesireForTarget: warDesireForTarget,
        );
        break;
      case DiplomaticOrderType.establishOverture:
        {
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
          if (snapshot.colonial.preferredColonialTargetFactionIdsSorted
              .contains(o.targetFactionId)) {
            s += kEstablishOvertureColonialTribeBonus;
          }
          break;
        }
      default:
        break;
    }
    return s == 0 ? 0 : math.max(1, s);
  }).toList();
}

int _scoreDeclareWarDiplomaticOrder({
  required DiplomaticOrder order,
  required String nationId,
  required Game game,
  required AIWorldSnapshot snapshot,
  required String agendaId,
  required PersonalityThresholds thresholds,
  required int maxRelationForDeclareWar,
  required bool behindVictoryPace,
  required bool suppressGpDeclareWar,
  required Set<String> invadableOwners,
  required Map<String, String> provinceOwner,
  required int warCooldownTurns,
  required int currentTurn,
  required StrategicGoal? primaryGoal,
  required int Function(String targetFactionId, int relationScore)
  warDesireForTarget,
}) {
  final rel = snapshot.relations[order.targetFactionId];
  final relationScore = rel?.score ?? 50;
  final adjacentOwners = snapshot.conquest.adjacentOwnerFactionIdsSorted;
  final colonialAdjacent =
      snapshot.colonial.adjacentNewWorldOwnerFactionIdsSorted;
  final isAdjacentOwner = adjacentOwners.contains(order.targetFactionId);
  final isColonialAdjacentOwner =
      colonialAdjacent.contains(order.targetFactionId);
  final isMinorTarget = _isMinorOrTribeFaction(game, order.targetFactionId);
  final ownsInvadableNw = snapshot.colonial.invadableNewWorldProvinceIdsSorted
      .any((pid) => provinceOwner[pid] == order.targetFactionId);
  if (behindVictoryPace &&
      adjacentOwners.isNotEmpty &&
      !isAdjacentOwner &&
      !isColonialAdjacentOwner &&
      !(ownsInvadableNw && isMinorTarget)) {
    return kDeclareWarNonAdjacentSuppressedScore;
  }
  if (isMinorTarget &&
      !invadableOwners.contains(order.targetFactionId) &&
      !isColonialAdjacentOwner &&
      !ownsInvadableNw) {
    return kDeclareWarNonAdjacentSuppressedScore;
  }
  final isAdjacentGp =
      isAdjacentOwner && game.playerById(order.targetFactionId) != null;
  if (suppressGpDeclareWar && isAdjacentGp) {
    return kDeclareWarNonAdjacentSuppressedScore;
  }
  final effectiveMaxRelation = behindVictoryPace && isMinorTarget
      ? kDeclareWarMinorMaxRelationWhenFarFromVictory
      : behindVictoryPace && isAdjacentGp
      ? kDeclareWarGpMaxRelationWhenFarFromVictory
      : maxRelationForDeclareWar;
  if (relationScore > effectiveMaxRelation) {
    return 0;
  }
  if (_isDecisionOnCooldown(
    game: game,
    actorFactionId: nationId,
    targetFactionId: order.targetFactionId,
    eventTypes: const [DiplomaticEventType.declareWar],
    cooldownTurns: warCooldownTurns,
    currentTurn: currentTurn,
  )) {
    return 0;
  }
  var s = 50;
  final warDesire = warDesireForTarget(order.targetFactionId, relationScore);
  final targetProvinceCount = provinceCountOwnedBy(game, order.targetFactionId);
  final desiredTerritory = targetProvinceCount <= 0
      ? 1
      : ((warDesire / 25).round()).clamp(1, targetProvinceCount);
  s += getAgendaConquerModifier(agendaId);
  s += getAgendaTreatyBreakingModifier(agendaId);
  s += (thresholds.warLikelihood - 50);
  s += (warDesire - 50);
  if (!suppressGpDeclareWar &&
      snapshot.opportunities.weakNeighbors.contains(order.targetFactionId)) {
    s += getDeclareWarTargetBonusWeakerNeighbor(agendaId);
    if (game.playerById(order.targetFactionId) != null &&
        warDesire >= kDeclareWarGpWeakNeighborMinWarDesire) {
      s += kDeclareWarGpWeakNeighborBonus;
    }
  }
  if (snapshot.conquest.preferredConquestTargetFactionIdsSorted
      .contains(order.targetFactionId)) {
    s += 15;
  }
  if (ownsInvadableNw && isMinorTarget) {
    s += kDeclareWarColonialInvadableOwnerBonus;
  }
  if (isColonialAdjacentOwner && isMinorTarget) {
    s += kDeclareWarColonialAdjacentTribeBonus;
  }
  if (isAdjacentOwner) {
    s += kDeclareWarAdjacentOwnerBonus;
    if (behindVictoryPace && isMinorTarget) {
      s += kDeclareWarAdjacentMinorBonusWhenFarFromVictory;
    }
    if (isMinorTarget && invadableOwners.contains(order.targetFactionId)) {
      s += kDeclareWarMinorWithInvadableProvinceBonus;
    }
    if (isMinorTarget &&
        snapshot.conquest.oldWorldProvincesOwned <=
            kStalledOldWorldProvinceThreshold) {
      s += kDeclareWarStalledExpansionMinorBonus;
    }
    if (isMinorTarget && snapshot.conquest.oldWorldProvincesOwned >= 10) {
      s -= kDeclareWarSatedExpansionMinorPenalty;
    }
    if (!suppressGpDeclareWar && behindVictoryPace && isAdjacentGp) {
      s += kDeclareWarAdjacentGpBonusWhenFarFromVictory;
    }
    if (thresholds.warLikelihood <= kDeclareWarLowWarLikelihoodThreshold) {
      s += kDeclareWarLowWarLikelihoodAdjacentBonus;
    }
  }
  if (primaryGoal == StrategicGoal.conquer) {
    s += 20;
  }
  s += behindVictoryPace
      ? conquerScoreBonusForProvincesToVictory(
          snapshot.conquest.provincesToVictory,
        )
      : conquerScoreBonusForProvincesToVictory(
              snapshot.conquest.provincesToVictory,
            ) ~/
          4;
  if (rel?.level == RelationLevel.allied) {
    s += getDeclareWarTargetBonusAlly(agendaId);
  }
  _log.d(
    'diplomacy warDesire nationId=$nationId targetFactionId=${order.targetFactionId} '
    'warDesire=$warDesire desiredTerritory=$desiredTerritory',
  );
  return s;
}

bool _isMinorOrTribeFaction(Game game, String factionId) {
  return game.minorNations.any((m) => m.id == factionId) ||
      game.tribes.any((t) => t.id == factionId);
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
