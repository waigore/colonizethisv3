import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'commodity_totals.dart';

/// Town manufacturing clustering bonus — recipe eligibility and per-province
/// bonus math (Refs #3872; phase-7 split Refs #4049).
/// SPEC/game/extraction-and-improvements.md § Town manufacturing bonus.
///
/// Sibling libraries own the rest of the surface:
/// `town_manufacturing_delivered_raw.dart` (town-connected delivered-raw
/// province walk) and `town_manufacturing_bonus.dart` (game rollup,
/// overlay preview, and auto-offers bridge; also the re-export barrel).

const int kTownManufacturingBonusDivisor = 4;

/// Multiplier for qualifying [townDevelopmentLevel] values (2 → 1, 4 → 2).
int townManufacturingBonusMultiplier(int townDevelopmentLevel) {
  return switch (townDevelopmentLevel) {
    2 => 1,
    4 => 2,
    _ => 0,
  };
}

bool isTownManufacturingRecipeEligible(ProductionRecipe recipe) {
  for (final inputId in recipe.inputQuantities.keys) {
    final commodity = CommodityCatalog.byId[inputId];
    if (commodity == null ||
        commodity.category != CommodityCategory.rawMaterial) {
      return false;
    }
  }
  return true;
}

/// Per-province manufactured bonus quantities from town-connected delivered
/// raw extraction.
Map<CommodityId, int> computeTownManufacturingBonusForProvince({
  required int townDevelopmentLevel,
  required Map<CommodityId, int> townConnectedDeliveredRawByCommodity,
  required Map<String, bool>? techUnlocked,
}) {
  final multiplier = townManufacturingBonusMultiplier(townDevelopmentLevel);
  if (multiplier <= 0 || townConnectedDeliveredRawByCommodity.isEmpty) {
    return const {};
  }
  final bonus = <CommodityId, int>{};
  for (final recipe in ProductionRecipesCatalog.all) {
    if (!isTownManufacturingRecipeEligible(recipe)) continue;
    if (!ProductionRecipesCatalog.isRecipeAvailableForPlayer(
      recipe,
      techUnlocked,
    )) {
      continue;
    }
    var limiting = -1;
    for (final entry in recipe.inputQuantities.entries) {
      final rawQty = townConnectedDeliveredRawByCommodity[entry.key] ?? 0;
      limiting = limiting < 0
          ? rawQty
          : (rawQty < limiting ? rawQty : limiting);
    }
    if (limiting <= 0) continue;
    final outputQty =
        (limiting ~/ kTownManufacturingBonusDivisor) *
        multiplier *
        recipe.outputQuantity;
    if (outputQty <= 0) continue;
    addUnits(bonus, recipe.outputCommodityId, outputQty);
  }
  return bonus;
}
