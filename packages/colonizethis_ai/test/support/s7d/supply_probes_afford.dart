// S7-D feedstock affordability / labour probes (Refs #2847 / #4602 Slice E).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

export 'supply_probes_labour.dart';

/// True iff [playerId]'s stockpile can afford the level-0 `build_improvement`
/// material cost (the cost to raise an unimproved tile to level 1 — 1 lumber +
/// 1 cast iron, `work_order_costs.dart` § `workOrderCostBuildImprovement`).
bool affordsBuildImprovementLevelZero(Game game, String playerId) {
  final player = game.playerById(playerId);
  if (player == null) return false;
  final cost = workOrderCostBuildImprovement(0);
  for (final entry in cost.entries) {
    if (player.stockpile.quantityOf(entry.key) < entry.value) return false;
  }
  return true;
}

/// True iff [playerId]'s stockpile holds enough of the single [commodityId]
/// component to cover its share of the level-0 `build_improvement` material
/// cost (`work_order_costs.dart` § `workOrderCostBuildImprovement`).
bool affordsBuildImprovementComponent(
  Game game,
  String playerId,
  String commodityId,
) {
  final player = game.playerById(playerId);
  if (player == null) return false;
  final required = workOrderCostBuildImprovement(0)[commodityId];
  if (required == null) return false;
  return player.stockpile.quantityOf(commodityId) >= required;
}

/// True iff [stockpile] holds enough of every input commodity to run at least
/// one full output run of **any** recipe in [recipes].
bool stockpileAffordsAnyProductionRecipe(
  Stockpile stockpile,
  List<ProductionRecipe> recipes,
) {
  for (final recipe in recipes) {
    final affordsAll = recipe.inputQuantities.entries.every(
      (e) => stockpile.quantityOf(e.key) >= e.value,
    );
    if (affordsAll) return true;
  }
  return false;
}

/// Increments the per-GP [key] entry of a `<String, int>` diagnostic [counter]
/// by one, treating an absent entry as zero.
void bumpCounter(Map<String, int> counter, String key) =>
    counter[key] = (counter[key] ?? 0) + 1;

/// Builds a fresh zero-initialised per-GP `<String, int>` diagnostic counter
/// map keyed by every id in [gpIds].
Map<String, int> zeroPerGpCounter(List<String> gpIds) => {
  for (final gpId in gpIds) gpId: 0,
};
