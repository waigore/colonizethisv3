import 'package:colonizethis_models/colonizethis_models.dart';

import 'commodities.dart';

/// Production recipes for Phase 2.
/// SPEC/game/production-recipes.md
class ProductionRecipe {
  const ProductionRecipe({
    required this.id,
    required this.outputCommodityId,
    required this.outputQuantity,
    required this.inputQuantities,
    required this.labourPerOutput,
  });

  /// Stable id for referring to this recipe from logic or scripts.
  final String id;

  /// Output commodity id.
  final CommodityId outputCommodityId;

  /// Output quantity per run (usually 1).
  final int outputQuantity;

  /// Input commodity quantities per run.
  final Map<CommodityId, int> inputQuantities;

  /// Labour required per output unit.
  final int labourPerOutput;
}

class ProductionRecipesCatalog {
  /// 2 timber + 2 iron + 1 coal → 1 castIron.
  static final ProductionRecipe castIronFromTimberIronCoal = ProductionRecipe(
    id: 'castIron_from_timber_iron_coal',
    outputCommodityId: CommodityCatalog.castIron.id,
    outputQuantity: 1,
    inputQuantities: {
      CommodityCatalog.timber.id: 2,
      CommodityCatalog.iron.id: 2,
      CommodityCatalog.coal.id: 1,
    },
    labourPerOutput: 5,
  );

  /// 2 wool → 1 fabric.
  static final ProductionRecipe fabricFromWool = ProductionRecipe(
    id: 'fabric_from_wool',
    outputCommodityId: CommodityCatalog.fabric.id,
    outputQuantity: 1,
    inputQuantities: {
      CommodityCatalog.wool.id: 2,
    },
    labourPerOutput: 2,
  );

  /// 2 cotton → 1 fabric.
  static final ProductionRecipe fabricFromCotton = ProductionRecipe(
    id: 'fabric_from_cotton',
    outputCommodityId: CommodityCatalog.fabric.id,
    outputQuantity: 1,
    inputQuantities: {
      CommodityCatalog.cotton.id: 2,
    },
    labourPerOutput: 2,
  );

  /// 2 sugarCane → 1 refinedSugar.
  static final ProductionRecipe refinedSugarFromSugarCane = ProductionRecipe(
    id: 'refinedSugar_from_sugarCane',
    outputCommodityId: CommodityCatalog.refinedSugar.id,
    outputQuantity: 1,
    inputQuantities: {
      CommodityCatalog.sugarCane.id: 2,
    },
    labourPerOutput: 2,
  );

  /// Example lumber recipe: 2 timber → 1 lumber.
  static final ProductionRecipe lumberFromTimber = ProductionRecipe(
    id: 'lumber_from_timber',
    outputCommodityId: CommodityCatalog.lumber.id,
    outputQuantity: 1,
    inputQuantities: {
      CommodityCatalog.timber.id: 2,
    },
    labourPerOutput: 2,
  );

  /// All production recipes available in Phase 2.
  static final List<ProductionRecipe> all = [
    castIronFromTimberIronCoal,
    fabricFromWool,
    fabricFromCotton,
    refinedSugarFromSugarCane,
    lumberFromTimber,
  ];

  /// Fast lookup by recipe id.
  static final Map<String, ProductionRecipe> byId = {
    for (final r in all) r.id: r,
  };
}

