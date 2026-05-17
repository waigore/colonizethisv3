import 'package:colonizethis_ai/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'goal_manager.dart';
import '../perception/perception_snapshot.dart';
import '../util/ai_random_utils.dart';

final _log = packageLogger();

/// Invasion army moves after same-turn declare war. SPEC/ai/ai-architecture.md.
Orders runConquestArmyMovePlanner({
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
  String? declaredWarTargetFactionId,
}) {
  final armyMoveCandidates = suggestionAPI.suggestArmyMoveOrders(
    view,
    game,
    topology,
    orders,
  );
  if (armyMoveCandidates.isEmpty) {
    _log.d('conquest army move nationId=$nationId candidatesCount=0');
    return orders;
  }
  final filtered = filterArmyMoveOrdersByDiplomacy(
    game,
    nationId,
    armyMoveCandidates,
    draftOrders: orders,
  );
  if (filtered.isEmpty) {
    _log.d('conquest army move filtered empty nationId=$nationId');
    return orders;
  }
  final domainWeights = getDomainWeightsForLeader(config.personalityId);
  var weight =
      primaryGoal == StrategicGoal.conquer ||
          primaryGoal == StrategicGoal.defend
      ? domainWeights.military
      : primaryGoal == StrategicGoal.expand
      ? domainWeights.economy
      : 50;
  final provincesToVictory = snapshot.conquest.provincesToVictory;
  if (primaryGoal == StrategicGoal.conquer || provincesToVictory > 10) {
    weight = weight < 10 ? 10 : weight;
  }
  if (provincesToVictory > kConquerScoreFloorProvincesToVictoryThreshold &&
      weight < 10) {
    weight = 10;
  }
  if (weight < 10) {
    _log.d('conquest army move skipped nationId=$nationId weight=$weight');
    return orders;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final invadable = snapshot.conquest.invadableProvinceIdsSorted.toSet();
  final scores = filtered.map((m) {
    final destOwner = provinceOwner[m.destinationProvinceId] ?? '';
    var score = 1.0;
    if (declaredWarTargetFactionId != null &&
        destOwner == declaredWarTargetFactionId) {
      score += 50;
    } else {
      final rel = getRelation(game, nationId, destOwner);
      if (rel != null && rel.atWar) {
        score += kMovePreferEnemyTerritoryBonus.toDouble();
      }
    }
    if (invadable.contains(m.destinationProvinceId)) {
      score += 10;
    }
    if (snapshot.conquest.adjacentOwnerFactionIdsSorted.contains(destOwner)) {
      score += 8;
    }
    return score;
  }).toList();
  final idx = pickWeightedIndex(scores, seeds.militarySeed + 4000);
  if (idx == null) return orders;
  final selected = filtered[idx];
  _log.i(
    'conquest army move chosen nationId=$nationId '
    'armyId=${selected.armyId} destinationProvinceId=${selected.destinationProvinceId} '
    'declaredWarTarget=$declaredWarTargetFactionId',
  );
  return applyArmyMoveOrderForPlayer(orders, nationId, selected);
}
