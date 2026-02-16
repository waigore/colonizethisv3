import 'package:colonizethis_models/colonizethis_models.dart';

/// Commodity catalog and categories.
/// SPEC/game/commodity-catalog.md
enum CommodityCategory {
  food,
  rawMaterial,
  manufactured,
  luxury,
  riches,
  advanced,
}

class Commodity {
  const Commodity({
    required this.id,
    required this.category,
    this.displayName,
  });

  /// Canonical id, e.g. 'grain', 'castIron'.
  final CommodityId id;
  final CommodityCategory category;
  final String? displayName;
}

/// Canonical list of all commodities for Phase 2.
/// Ids must match SPEC/game/commodity-catalog.md exactly.
class CommodityCatalog {
  static const Commodity grain = Commodity(
    id: 'grain',
    category: CommodityCategory.food,
    displayName: 'Grain',
  );

  static const Commodity meat = Commodity(
    id: 'meat',
    category: CommodityCategory.food,
    displayName: 'Meat',
  );

  static const Commodity timber = Commodity(
    id: 'timber',
    category: CommodityCategory.rawMaterial,
    displayName: 'Timber',
  );

  static const Commodity iron = Commodity(
    id: 'iron',
    category: CommodityCategory.rawMaterial,
    displayName: 'Iron',
  );

  static const Commodity wool = Commodity(
    id: 'wool',
    category: CommodityCategory.rawMaterial,
    displayName: 'Wool',
  );

  static const Commodity cotton = Commodity(
    id: 'cotton',
    category: CommodityCategory.rawMaterial,
    displayName: 'Cotton',
  );

  static const Commodity coal = Commodity(
    id: 'coal',
    category: CommodityCategory.rawMaterial,
    displayName: 'Coal',
  );

  static const Commodity sugarCane = Commodity(
    id: 'sugarCane',
    category: CommodityCategory.rawMaterial,
    displayName: 'Sugar cane',
  );

  static const Commodity tobacco = Commodity(
    id: 'tobacco',
    category: CommodityCategory.rawMaterial,
    displayName: 'Tobacco',
  );

  static const Commodity furs = Commodity(
    id: 'furs',
    category: CommodityCategory.rawMaterial,
    displayName: 'Furs',
  );

  static const Commodity lumber = Commodity(
    id: 'lumber',
    category: CommodityCategory.manufactured,
    displayName: 'Lumber',
  );

  static const Commodity castIron = Commodity(
    id: 'castIron',
    category: CommodityCategory.manufactured,
    displayName: 'Cast iron',
  );

  static const Commodity fabric = Commodity(
    id: 'fabric',
    category: CommodityCategory.manufactured,
    displayName: 'Fabric',
  );

  static const Commodity refinedSugar = Commodity(
    id: 'refinedSugar',
    category: CommodityCategory.manufactured,
    displayName: 'Refined sugar',
  );

  static const Commodity cigars = Commodity(
    id: 'cigars',
    category: CommodityCategory.manufactured,
    displayName: 'Cigars',
  );

  static const Commodity furHats = Commodity(
    id: 'furHats',
    category: CommodityCategory.manufactured,
    displayName: 'Fur hats',
  );

  static const Commodity steel = Commodity(
    id: 'steel',
    category: CommodityCategory.manufactured,
    displayName: 'Steel',
  );

  static const Commodity paper = Commodity(
    id: 'paper',
    category: CommodityCategory.manufactured,
    displayName: 'Paper',
  );

  static const Commodity bronze = Commodity(
    id: 'bronze',
    category: CommodityCategory.manufactured,
    displayName: 'Bronze',
  );

  static const Commodity gold = Commodity(
    id: 'gold',
    category: CommodityCategory.riches,
    displayName: 'Gold',
  );

  static const Commodity silver = Commodity(
    id: 'silver',
    category: CommodityCategory.riches,
    displayName: 'Silver',
  );

  static const Commodity gems = Commodity(
    id: 'gems',
    category: CommodityCategory.riches,
    displayName: 'Gems',
  );

  static const Commodity diamonds = Commodity(
    id: 'diamonds',
    category: CommodityCategory.riches,
    displayName: 'Diamonds',
  );

  static const Commodity spices = Commodity(
    id: 'spices',
    category: CommodityCategory.advanced,
    displayName: 'Spices',
  );

  /// All commodities in the catalog.
  static const List<Commodity> all = [
    grain,
    meat,
    timber,
    iron,
    wool,
    cotton,
    coal,
    sugarCane,
    tobacco,
    furs,
    lumber,
    castIron,
    fabric,
    refinedSugar,
    cigars,
    furHats,
    steel,
    paper,
    bronze,
    gold,
    silver,
    gems,
    diamonds,
    spices,
  ];

  /// Fast lookup by id.
  static final Map<CommodityId, Commodity> byId = {
    for (final c in all) c.id: c,
  };
}

