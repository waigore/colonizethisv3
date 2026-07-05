import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Shared feedstock id resolution and regiment counting for extraction targets
/// and bootstrap cost waivers (Refs #3877).
int regimentCountForPlayer(Game game, String playerId) {
  var count = 0;
  for (final unit in allUnitsFromWorld(game.worldState)) {
    if (unit.ownerId != playerId) continue;
    if (RegimentEconomyCatalog.byId.containsKey(unit.type)) {
      count++;
    }
  }
  return count;
}

/// Production-recipe feedstock commodity ids for recipes whose output is in
/// [neededOutputs]. Shared by the regiment-build-input and improvement-input
/// feedstock-extraction gates (Refs #3500).
Set<String> feedstockCommodityIdsForRecipeOutputs(
  Set<CommodityId> neededOutputs,
) {
  if (neededOutputs.isEmpty) return const <String>{};
  final feedstock = <String>{};
  for (final recipe in ProductionRecipesCatalog.all) {
    if (neededOutputs.contains(recipe.outputCommodityId)) {
      feedstock.addAll(recipe.inputQuantities.keys);
    }
  }
  return feedstock;
}
