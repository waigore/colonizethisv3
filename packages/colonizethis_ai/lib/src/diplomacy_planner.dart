import 'dart:math' as math;

import 'package:colonizethis_ai/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'util/ai_random_utils.dart';
import 'goal_manager.dart';
import 'social/hidden_agenda.dart';
import 'util/orders_extensions.dart';
import 'perception.dart';

final _log = packageLogger();

Orders runDiplomacyPlanner({
  required String nationId,
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders orders,
  required AIWorldSnapshot snapshot,
  required AIConfig config,
  required StrategicGoal primaryGoal,
  required AISeedBundle seeds,
  required OrderSuggestionAPI suggestionAPI,
}) {
  final domainWeights = getDomainWeightsForLeader(config.personalityId);
  final weight =
      primaryGoal == StrategicGoal.diplomacy ||
          primaryGoal == StrategicGoal.conquer ||
          primaryGoal == StrategicGoal.trade
      ? domainWeights.diplomacy
      : 40;
  if (weight < 25) {
    _log.d('diplomacy skipped nationId=$nationId weight=$weight < 25');
    return orders;
  }

  final diploCandidates = suggestionAPI.suggestDiplomaticOrders(
    view,
    game,
    topology,
    orders,
  );
  if (diploCandidates.isEmpty) return orders;

  final scores = computeDiplomaticCandidateScores(
    candidates: diploCandidates,
    nationId: nationId,
    game: game,
    snapshot: snapshot,
    config: config,
  );

  final candidateDesc = diploCandidates
      .map(
        (o) =>
            '${o.type.name}${o.type == DiplomaticOrderType.declareWar ? ":${o.targetFactionId}" : ""}',
      )
      .toList();
  _log.d(
    'diplomacy eval nationId=$nationId hiddenAgendaId=${config.hiddenAgendaId} '
    'candidates=$candidateDesc scores=$scores',
  );

  final idx = pickWeightedIndex(scores, seeds.diplomacySeed);
  if (idx == null) return orders;
  final chosen = diploCandidates[idx];
  _log.i(
    'diplomacy chosen nationId=$nationId '
    'type=${chosen.type}${chosen.type == DiplomaticOrderType.declareWar ? " targetFactionId=${chosen.targetFactionId}" : ""} score=${scores[idx]}',
  );
  return orders.appendDiplomaticOrders(nationId, [chosen]);
}

/// Pre–weighted-random scores for diplomatic order candidates (0 = suppressed).
/// Exposed for deterministic tests; [runDomainPlanners] uses the same values.
List<int> computeDiplomaticCandidateScores({
  required List<DiplomaticOrder> candidates,
  required String nationId,
  required Game game,
  required AIWorldSnapshot snapshot,
  required AIConfig config,
}) {
  final agendaId = config.hiddenAgendaId;
  final thresholds = getThresholdsForLeader(config.personalityId);
  final maxRelationForDeclareWar = getDeclareWarMaxRelationScore(agendaId);
  const warCooldownTurns = 4;
  const improveRelationsCooldownTurns = 2;
  final currentTurn = game.worldState.turnState.turnNumber;
  return candidates.map((o) {
    var s = 50;
    switch (o.type) {
      case DiplomaticOrderType.offerPeace:
        {
          final rel = snapshot.relations[o.targetFactionId];
          final warDesire = computeWarDesireScore(
            game: game,
            nationId: nationId,
            targetFactionId: o.targetFactionId,
            relationScore: rel?.score ?? 50,
          );
          // Lower peace desire when current war desire remains high.
          s -= (warDesire - 50);
        }
        s += getAgendaPeaceAcceptanceModifier(agendaId);
        s += (thresholds.peaceTendency - 50);
        break;
      case DiplomaticOrderType.alliance:
        s += getAgendaAllianceAcceptanceModifier(agendaId);
        s += (thresholds.allianceTendency - 50);
        break;
      case DiplomaticOrderType.declareWar:
        {
          final rel = snapshot.relations[o.targetFactionId];
          final relationScore = rel?.score ?? 50;
          if (relationScore > maxRelationForDeclareWar) {
            s = 0;
          } else {
            if (_isDecisionOnCooldown(
              game: game,
              actorFactionId: nationId,
              targetFactionId: o.targetFactionId,
              eventTypes: const [DiplomaticEventType.declareWar],
              cooldownTurns: warCooldownTurns,
              currentTurn: currentTurn,
            )) {
              s = 0;
              break;
            }
            final warDesire = computeWarDesireScore(
              game: game,
              nationId: nationId,
              targetFactionId: o.targetFactionId,
              relationScore: relationScore,
            );
            final targetProvinceCount = provinceCountOwnedBy(
              game,
              o.targetFactionId,
            );
            final desiredTerritory = targetProvinceCount <= 0
                ? 1
                : ((warDesire / 25).round()).clamp(1, targetProvinceCount);
            s += getAgendaConquerModifier(agendaId);
            s += getAgendaTreatyBreakingModifier(agendaId);
            s += (thresholds.warLikelihood - 50);
            s += (warDesire - 50);
            if (snapshot.opportunities.weakNeighbors.contains(
              o.targetFactionId,
            )) {
              s += getDeclareWarTargetBonusWeakerNeighbor(agendaId);
            }
            if (rel?.level == RelationLevel.allied) {
              s += getDeclareWarTargetBonusAlly(agendaId);
            }
            _log.d(
              'diplomacy warDesire nationId=$nationId targetFactionId=${o.targetFactionId} '
              'warDesire=$warDesire desiredTerritory=$desiredTerritory',
            );
          }
          break;
        }
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
          final warDesire = computeWarDesireScore(
            game: game,
            nationId: nationId,
            targetFactionId: o.targetFactionId,
            relationScore: rel?.score ?? 50,
          );
          final improveRelationsDesire = 100 - warDesire;
          s += (improveRelationsDesire - 50);
          break;
        }
      default:
        break;
    }
    return s == 0 ? 0 : math.max(1, s);
  }).toList();
}

int computeWarDesireScore({
  required Game game,
  required String nationId,
  required String targetFactionId,
  required int relationScore,
}) {
  final attackerPower = greatPowerPowerScore(game, nationId);
  final targetPower = greatPowerPowerScore(game, targetFactionId);
  final targetPowerSafe = targetPower <= 0 ? 1 : targetPower;
  final strengthRatio = attackerPower / targetPowerSafe;
  var score = 50;

  if (strengthRatio >= 1.35) {
    score += 30;
  } else if (strengthRatio >= 0.85) {
    score += 5;
  } else {
    score -= 25;
  }

  if (relationScore >= 70) {
    score -= 40;
  } else if (relationScore >= 50) {
    score -= 20;
  } else if (relationScore <= 25) {
    score += 10;
  }

  final targetIsMinorOrTribe =
      game.minorNations.any((m) => m.id == targetFactionId) ||
      game.tribes.any((t) => t.id == targetFactionId);
  if (targetIsMinorOrTribe) {
    score += _resourceNeedBonus(game, nationId, targetFactionId);
    score += _interventionRiskPenalty(game, nationId, targetFactionId);
    score += _invasionCapacityAdjustment(game, nationId, targetFactionId);
  }

  return score.clamp(0, 100);
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

int _resourceNeedBonus(Game game, String nationId, String targetFactionId) {
  final ownedResourceIds = <String>{};
  final player = game.playerById(nationId);
  if (player != null) {
    for (final entry in player.stockpile.quantities.entries) {
      if (entry.value > 0) ownedResourceIds.add(entry.key);
    }
  }
  final targetResourceIds = <String>{};
  final byRegion = game.worldState.tileKeysByRegionAndProvince;
  for (final p in allProvinces(game.worldState)) {
    if (p.ownerId != targetFactionId) continue;
    final tiles = byRegion[p.regionId]?[p.id] ?? const <String>[];
    for (final tileKey in tiles) {
      final resource = game.worldState.resourceByTileKey[tileKey];
      if (resource != null && resource.isNotEmpty) {
        targetResourceIds.add(resource);
      }
    }
  }
  final missing = targetResourceIds
      .where((id) => !ownedResourceIds.contains(id))
      .length;
  return (missing * 5).clamp(0, 15);
}

int _interventionRiskPenalty(
  Game game,
  String nationId,
  String targetFactionId,
) {
  var count = 0;
  for (final overture in game.overtureStates) {
    if (overture.targetId != targetFactionId) continue;
    if (overture.gpId == nationId) continue;
    if (!overture.hasEmbassy) continue;
    if (game.players.any((p) => p.id == overture.gpId)) count++;
  }
  return -(count * 8).clamp(0, 24);
}

int _invasionCapacityAdjustment(
  Game game,
  String nationId,
  String targetFactionId,
) {
  final ownRegiments = allUnitsFromWorld(
    game.worldState,
  ).where((u) => u.ownerId == nationId).length;
  final targetRegiments = allUnitsFromWorld(
    game.worldState,
  ).where((u) => u.ownerId == targetFactionId).length;
  var score = 0;
  if (ownRegiments < math.max(2, targetRegiments ~/ 2)) {
    score -= 20;
  } else if (ownRegiments > targetRegiments) {
    score += 10;
  }

  final ownRegionIds = allProvinces(
    game.worldState,
  ).where((p) => p.ownerId == nationId).map((p) => p.regionId).toSet();
  final targetRegionIds = allProvinces(
    game.worldState,
  ).where((p) => p.ownerId == targetFactionId).map((p) => p.regionId).toSet();
  final requiresOverseas = targetRegionIds.any(
    (id) => !ownRegionIds.contains(id),
  );
  if (requiresOverseas && shipCountForFaction(game, nationId) <= 0) {
    score -= 25;
  }

  final activeWars = game.diplomacyRelations
      .where((r) => r.involvesNation(nationId) && r.atWar)
      .length;
  if (activeWars >= 2) score -= 15;
  return score;
}
