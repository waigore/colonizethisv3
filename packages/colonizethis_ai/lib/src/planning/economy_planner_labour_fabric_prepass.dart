import 'package:colonizethis_economy/colonizethis_economy.dart';

import 'ai_commodity_ids.dart';
import 'economy_planner_labour_feedstock.dart';
import 'planning_imports.dart';
import 'recipe_scoring.dart';

/// Assigns the lowest-`id` feasible fabric recipe before the general greedy
/// pass when the castIron-labour peasant-recruit fabric path is active, so
/// scarce effective labour is not consumed by competing boosted recipes
/// (`castIron`, `lumber`) on the same turn (Refs #2847).
void assignCastIronLabourFabricPrePass({
  required Stockpile virtual,
  required int remainingLabour,
  required Map<CommodityId, int> feedstockReserve,
  required Set<String> feedstockReserveOutputIds,
  required Map<String, int> labourByRecipe,
  required void Function(Stockpile virtual, int remainingLabour) onStateUpdated,
  Map<String, bool>? techUnlocked,
}) {
  final fabricId = kAiCommodityIds.fabric;
  final fabricRecipes = ProductionRecipesCatalog.producing(fabricId).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  var nextVirtual = virtual;
  var nextRemainingLabour = remainingLabour;
  for (final recipe in fabricRecipes) {
    // Tech-locked fabric recipes (e.g. `fabric_from_cotton` without
    // `cotton_weaving`) are not assignable. Refs #3470 Slice C.
    if (!ProductionRecipesCatalog.isRecipeAvailableForPlayer(
      recipe,
      techUnlocked,
    )) {
      continue;
    }
    if (nextRemainingLabour < recipe.labourPerOutput) continue;
    final feasibilityStock =
        feedstockReserveOutputIds.contains(recipe.outputCommodityId)
        ? nextVirtual
        : stockpileWithFeedstockReserve(nextVirtual, feedstockReserve);
    final runs = feasibleRuns(
      recipe: recipe,
      stockpile: feasibilityStock,
      remainingLabour: nextRemainingLabour,
    );
    if (runs <= 0) continue;
    final labourUsed = runs * recipe.labourPerOutput;
    labourByRecipe[recipe.id] = (labourByRecipe[recipe.id] ?? 0) + labourUsed;
    nextRemainingLabour -= labourUsed;
    for (final entry in recipe.inputQuantities.entries) {
      nextVirtual = nextVirtual.applyDelta(entry.key, -entry.value * runs);
    }
    nextVirtual = nextVirtual.applyDelta(
      recipe.outputCommodityId,
      recipe.outputQuantity * runs,
    );
    onStateUpdated(nextVirtual, nextRemainingLabour);
    return;
  }
}
