import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Rival GP ids with a spy present that have unlocked [techId], sorted.
/// Used for passive RP boost during research (Refs #3834 R2, #4457).
List<String> spyResearchBoostRivalIdsForTech({
  required Game game,
  required String playerId,
  required String techId,
}) {
  if (techId.isEmpty) return const [];
  final rivalGpIdsWithSpy = <String>{};
  final ownerByProvince = ownerByProvinceIdMap(game.worldState);
  for (final u in game.worldState.allUnitsById.values) {
    if (u.ownerId != playerId) continue;
    if (!isSpyUnit(u.type)) continue;
    final territoryOwner = ownerByProvince[u.locationProvinceId];
    if (territoryOwner == null || territoryOwner == playerId) continue;
    if (game.playerById(territoryOwner) == null) continue;
    rivalGpIdsWithSpy.add(territoryOwner);
  }
  final qualifying = <String>[];
  for (final rivalId in rivalGpIdsWithSpy) {
    final rival = game.playerById(rivalId);
    if (rival?.techUnlocked?[techId] == true) qualifying.add(rivalId);
  }
  qualifying.sort();
  return qualifying;
}

/// Count of rival GPs with a spy present that have unlocked [techId].
/// Used for passive RP boost during research (Refs #3834 R2).
int spyResearchBoostGpCountForTech({
  required Game game,
  required String playerId,
  required String techId,
}) {
  return spyResearchBoostRivalIdsForTech(
    game: game,
    playerId: playerId,
    techId: techId,
  ).length;
}

/// Applies spy RP boost multiplier to base research points (Refs #3834 R2).
int applySpyResearchBoostToPoints({
  required int basePoints,
  required int qualifyingRivalGpCount,
}) {
  if (basePoints <= 0 || qualifyingRivalGpCount <= 0) return basePoints;
  final multiplier = 1.0 + qualifyingRivalGpCount * spyResearchBoostPerGp;
  return (basePoints * multiplier).round();
}
