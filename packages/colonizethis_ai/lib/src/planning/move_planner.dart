import 'package:colonizethis_ai/package_logger.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'goal_manager.dart';
import '../util/ai_random_utils.dart';
import '../util/orders_extensions.dart';

final _log = packageLogger();

Orders runMovePlanner({
  required String nationId,
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders orders,
  required AIConfig config,
  required StrategicGoal primaryGoal,
  required AISeedBundle seeds,
  required OrderSuggestionAPI suggestionAPI,
}) {
  final moveCandidates = suggestionAPI.suggestMoveOrders(
    view,
    game,
    topology,
    orders,
  );
  if (moveCandidates.isEmpty) return orders;
  final filtered = filterMoveOrdersByDiplomacy(game, nationId, moveCandidates);
  if (filtered.isEmpty) return orders;
  final domainWeights = getDomainWeightsForLeader(config.personalityId);
  final weight =
      primaryGoal == StrategicGoal.conquer ||
          primaryGoal == StrategicGoal.defend
      ? domainWeights.military
      : primaryGoal == StrategicGoal.expand
      ? domainWeights.economy
      : 50;
  _log.d(
    'move eval nationId=$nationId weight=$weight '
    'filteredCount=${filtered.length}',
  );
  if (weight < 20) {
    _log.d('move skipped nationId=$nationId weight < 20');
    return orders;
  }
  final provinceOwner = getProvinceOwnerMap(game);
  final scores = filtered.map((m) {
    final destProv = Unit.provinceIdFromTileKey(m.destinationTileKey);
    final destOwner = destProv != null ? provinceOwner[destProv] : null;
    if (destOwner == null || destOwner == nationId) return 1.0;
    final rel = getRelation(game, nationId, destOwner);
    final atWar = rel != null && rel.atWar;
    return 1.0 + (atWar ? kMovePreferEnemyTerritoryBonus.toDouble() : 0);
  }).toList();
  _log.d('move scores nationId=$nationId scores=$scores');
  final idx = pickWeightedIndex(scores, seeds.militarySeed);
  if (idx == null) return orders;
  final selected = [filtered[idx]];
  _log.i(
    'move chosen nationId=$nationId '
    'unitId=${selected.first.unitId} destinationTileKey=${selected.first.destinationTileKey}',
  );
  return orders.appendMoveOrders(nationId, selected);
}

Orders runArmyMovePlanner({
  required String nationId,
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders orders,
  required AIConfig config,
  required StrategicGoal primaryGoal,
  required AISeedBundle seeds,
  required OrderSuggestionAPI suggestionAPI,
  int provincesToVictory = 0,
}) {
  final armyMoveCandidates = suggestionAPI.suggestArmyMoveOrders(
    view,
    game,
    topology,
    orders,
  );
  if (armyMoveCandidates.isEmpty) {
    _log.d('army move eval nationId=$nationId candidatesCount=0');
    return orders;
  }
  final filtered = filterArmyMoveOrdersByDiplomacy(
    game,
    nationId,
    armyMoveCandidates,
  );
  if (filtered.isEmpty) {
    _log.d('army move filtered empty nationId=$nationId');
    return orders;
  }
  final domainWeights = getDomainWeightsForLeader(config.personalityId);
  final weight =
      primaryGoal == StrategicGoal.conquer ||
          primaryGoal == StrategicGoal.defend
      ? domainWeights.military
      : primaryGoal == StrategicGoal.expand
      ? domainWeights.economy
      : 50;
  final minWeight =
      primaryGoal == StrategicGoal.conquer || provincesToVictory > 10 ? 10 : 20;
  if (weight < minWeight) {
    _log.d(
      'army move skipped nationId=$nationId weight=$weight < $minWeight',
    );
    return orders;
  }
  _log.d(
    'army move eval nationId=$nationId weight=$weight '
    'filteredCount=${filtered.length}',
  );
  final provinceOwner = getProvinceOwnerMap(game);
  final scores = filtered.map((m) {
    final destOwner = provinceOwner[m.destinationProvinceId];
    if (destOwner == null || destOwner == nationId) return 1.0;
    final rel = getRelation(game, nationId, destOwner);
    final atWar = rel != null && rel.atWar;
    return 1.0 + (atWar ? kMovePreferEnemyTerritoryBonus.toDouble() : 0);
  }).toList();
  final idx = pickWeightedIndex(scores, seeds.militarySeed + 2000);
  if (idx == null) return orders;
  final selected = filtered[idx];
  _log.i(
    'army move chosen nationId=$nationId '
    'armyId=${selected.armyId} destinationProvinceId=${selected.destinationProvinceId}',
  );
  return applyArmyMoveOrderForPlayer(orders, nationId, selected);
}
