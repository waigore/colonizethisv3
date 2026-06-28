import 'package:colonizethis_models/colonizethis_models.dart';

import 'commodities.dart';
import 'tech_ids.dart';

/// Production recipes for Phase 2.
/// SPEC/game/production-recipes.md
class ProductionRecipe {
  const ProductionRecipe({
    required this.id,
    required this.outputCommodityId,
    required this.outputQuantity,
    required this.inputQuantities,
    required this.labourPerOutput,
    this.requiredTechId,
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

  /// Technology id this recipe requires before a player may use it, or `null`
  /// when the recipe is always available. Gating is per player and evaluated
  /// against the player's `techUnlocked` set. SPEC/game/production-recipes.md
  /// § Technology-gated recipes.
  final String? requiredTechId;
}

class ProductionRecipesCatalog {
  /// 2 timber + 2 iron → 1 castIron.
  static final ProductionRecipe castIronFromTimberIronCoal = ProductionRecipe(
    id: 'castIron_from_timber_iron_coal',
    outputCommodityId: CommodityCatalog.castIron.id,
    outputQuantity: 1,
    inputQuantities: {
      CommodityCatalog.timber.id: 2,
      CommodityCatalog.iron.id: 2,
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

  /// 2 cotton → 1 fabric. Tech-gated: requires `cotton_weaving` per player
  /// (SPEC/game/tech-tree-new-world.md, SPEC/game/production-recipes.md).
  static final ProductionRecipe fabricFromCotton = ProductionRecipe(
    id: 'fabric_from_cotton',
    outputCommodityId: CommodityCatalog.fabric.id,
    outputQuantity: 1,
    inputQuantities: {
      CommodityCatalog.cotton.id: 2,
    },
    labourPerOutput: 2,
    requiredTechId: kTechIdCottonWeaving,
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

  /// 2 timber → 1 lumber.
  static final ProductionRecipe lumberFromTimber = ProductionRecipe(
    id: 'lumber_from_timber',
    outputCommodityId: CommodityCatalog.lumber.id,
    outputQuantity: 1,
    inputQuantities: {
      CommodityCatalog.timber.id: 2,
    },
    labourPerOutput: 2,
  );

  /// 3 tobacco → 1 cigars.
  static final ProductionRecipe cigarsFromTobacco = ProductionRecipe(
    id: 'cigars_from_tobacco',
    outputCommodityId: CommodityCatalog.cigars.id,
    outputQuantity: 1,
    inputQuantities: {
      CommodityCatalog.tobacco.id: 3,
    },
    labourPerOutput: 3,
  );

  /// 2 furs → 1 furHats.
  static final ProductionRecipe furHatsFromFurs = ProductionRecipe(
    id: 'furHats_from_furs',
    outputCommodityId: CommodityCatalog.furHats.id,
    outputQuantity: 1,
    inputQuantities: {
      CommodityCatalog.furs.id: 2,
    },
    labourPerOutput: 2,
  );

  /// 2 castIron + 1 coal → 1 steel.
  static final ProductionRecipe steelFromCastIronCoal = ProductionRecipe(
    id: 'steel_from_castIron_coal',
    outputCommodityId: CommodityCatalog.steel.id,
    outputQuantity: 1,
    inputQuantities: {
      CommodityCatalog.castIron.id: 2,
      CommodityCatalog.coal.id: 1,
    },
    labourPerOutput: 5,
  );

  /// 3 timber → 1 paper.
  static final ProductionRecipe paperFromTimber = ProductionRecipe(
    id: 'paper_from_timber',
    outputCommodityId: CommodityCatalog.paper.id,
    outputQuantity: 1,
    inputQuantities: {
      CommodityCatalog.timber.id: 3,
    },
    labourPerOutput: 3,
  );

  /// 1 copper + 1 tin → 1 bronze.
  static final ProductionRecipe bronzeFromCopperTin = ProductionRecipe(
    id: 'bronze_from_copper_tin',
    outputCommodityId: CommodityCatalog.bronze.id,
    outputQuantity: 1,
    inputQuantities: {
      CommodityCatalog.copper.id: 1,
      CommodityCatalog.tin.id: 1,
    },
    labourPerOutput: 3,
  );

  /// All production recipes available in Phase 2.
  static final List<ProductionRecipe> all = [
    castIronFromTimberIronCoal,
    fabricFromWool,
    fabricFromCotton,
    refinedSugarFromSugarCane,
    lumberFromTimber,
    cigarsFromTobacco,
    furHatsFromFurs,
    steelFromCastIronCoal,
    paperFromTimber,
    bronzeFromCopperTin,
  ];

  /// Fast lookup by recipe id.
  static final Map<String, ProductionRecipe> byId = {
    for (final r in all) r.id: r,
  };

  /// Recipes grouped by their `outputCommodityId`, preserving [all] order
  /// within each commodity bucket.
  ///
  /// Built once from the static [all] list so callers that repeatedly need the
  /// recipes producing a given commodity avoid an O(recipes) scan per lookup.
  /// Returns an empty list for a commodity no recipe produces. Refs #3288.
  static final Map<CommodityId, List<ProductionRecipe>> byOutputCommodityId =
      () {
    final byOutput = <CommodityId, List<ProductionRecipe>>{};
    for (final r in all) {
      (byOutput[r.outputCommodityId] ??= <ProductionRecipe>[]).add(r);
    }
    return byOutput;
  }();

  /// Recipes whose output is [commodityId], in [all] order. Empty when none.
  /// O(1) lookup backed by [byOutputCommodityId]. Refs #3288.
  static List<ProductionRecipe> producing(CommodityId commodityId) =>
      byOutputCommodityId[commodityId] ?? const <ProductionRecipe>[];

  /// Whether [recipe] is available to a player with the given [techUnlocked]
  /// set. A recipe with no `requiredTechId` is always available. A tech-gated
  /// recipe is available only when its `requiredTechId` maps to `true` in
  /// [techUnlocked]; a `null`, missing, or `false` entry means locked.
  /// Gating is per player. SPEC/game/production-recipes.md
  /// § Technology-gated recipes.
  static bool isRecipeAvailableForPlayer(
    ProductionRecipe recipe,
    Map<String, bool>? techUnlocked,
  ) {
    final requiredTechId = recipe.requiredTechId;
    if (requiredTechId == null) return true;
    return techUnlocked?[requiredTechId] == true;
  }

  /// The subset of [all] available to a player with the given [techUnlocked]
  /// set, preserving [all] order. Recipes whose `requiredTechId` is not
  /// unlocked are excluded. SPEC/game/production-recipes.md
  /// § Technology-gated recipes.
  static List<ProductionRecipe> availableForPlayer(
    Map<String, bool>? techUnlocked,
  ) =>
      [
        for (final recipe in all)
          if (isRecipeAvailableForPlayer(recipe, techUnlocked)) recipe,
      ];
}
