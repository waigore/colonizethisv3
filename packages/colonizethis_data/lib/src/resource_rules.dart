import 'resource.dart';
import 'terrain_type.dart';

/// Allowed region(s) for a resource. TDD 04b, GDD 04b.
enum ResourceRegionRule {
  oldWorldOnly,
  newWorldOnly,
  both,
}

/// Resource–region and resource–terrain rules plus default market price for spawn weights.
/// SPEC/program/tile-map-gen-resources.md, SPEC/game/resource-terrain-region-rules.md.
class ResourceRules {
  ResourceRules({
    required this.regionRule,
    required this.allowedTerrains,
    required this.defaultMarketPrice,
    Map<String, int>? manufacturedDefaultMarketPrice,
  }) : manufacturedDefaultMarketPrice =
            manufacturedDefaultMarketPrice ?? const <String, int>{};

  /// Which region(s) this resource may appear in.
  final Map<Resource, ResourceRegionRule> regionRule;

  /// For each resource, terrain types on which it may spawn.
  final Map<Resource, List<TerrainType>> allowedTerrains;

  /// Default market price; spawn weight is inverse (higher price = rarer).
  final Map<Resource, int> defaultMarketPrice;

  /// Catalog base market price for manufactured commodities, keyed by
  /// `CommodityId` (string). Manufactured commodities have no [Resource]
  /// enum counterpart, so they live in a separate map.
  ///
  /// Per `SPEC/game/commodity-catalog.md` § *Manufactured base prices*, each
  /// value is the **sum of input prices** of the commodity's canonical
  /// recipe in [production-recipes.md](../game/production-recipes.md) — the
  /// break-even production cost from raw inputs at their default market
  /// prices, with no markup. Recipes accepting interchangeable raw inputs
  /// (e.g. `fabric` accepts either `wool` or `cotton`) use the cheaper of
  /// the two so the catalog floor matches the most efficient legitimate
  /// production path.
  ///
  /// Empty by default so callers constructing custom [ResourceRules] do
  /// not have to provide a manufactured table; see
  /// [defaultRules] for the canonical product map.
  final Map<String, int> manufacturedDefaultMarketPrice;

  /// Spawn weight for weighted random: inverse to price. Normalized per call.
  double spawnWeight(Resource r) {
    final price = defaultMarketPrice[r] ?? 1;
    return price > 0 ? 1.0 / price : 1.0;
  }

  /// Returns the integer catalog-published default market price for a
  /// `CommodityId` string.
  ///
  /// Resolution order:
  ///
  /// 1. **Raw-resource map** ([defaultMarketPrice]) when the id matches a
  ///    [Resource] enum name (the raw-resource commodities `grain`, `meat`,
  ///    `wool`, `horses`, `timber`, `iron`, `copper`, `tin`, `coal`,
  ///    `sugarCane`, `tobacco`, `cotton`, `furs`, `spices`, `silver`,
  ///    `gold`, `gems`, `diamonds`).
  /// 2. **Manufactured map** ([manufacturedDefaultMarketPrice]) when the id
  ///    matches a manufactured `CommodityId` (the nine tradeable
  ///    manufactured commodities `lumber`, `fabric`, `castIron`,
  ///    `refinedSugar`, `cigars`, `furHats`, `steel`, `paper`, `bronze`).
  ///    Values are derived from each commodity's canonical recipe input
  ///    cost per `SPEC/game/commodity-catalog.md` § *Manufactured base
  ///    prices* (Refs #3093 manufactured-default-prices slice).
  ///
  /// Returns `null` for the empty string, for unknown ids, and for
  /// non-tradeable raw-resource ids absent from both maps. The
  /// world-market price-discovery floor anchors on the **raw-resource**
  /// map only (see `world_market_phase._basePriceForCommodityId`), so
  /// adding manufactured fallback prices here does **not** widen the
  /// price-floor input — manufactured-commodity floors remain `0` until
  /// the SPEC is extended further.
  ///
  /// Used by trade UI surfaces, `effectiveMarketPriceForCommodityId`, the
  /// `TradeOrderValidator` bid spend gate, and the AI treasury planner to
  /// render a catalog-grounded fallback when `WorldMarketState.prices`
  /// lacks an entry. The mapping `CommodityId == Resource.name` for raw
  /// resources mirrors the convention enforced by the production pipeline
  /// (see `world_market_phase.dart`); manufactured ids use the string keys
  /// declared on `CommodityCatalog` directly.
  int? defaultMarketPriceForCommodityId(String commodityId) {
    if (commodityId.isEmpty) return null;
    for (final entry in defaultMarketPrice.entries) {
      if (entry.key.name == commodityId) return entry.value;
    }
    final manufactured = manufacturedDefaultMarketPrice[commodityId];
    if (manufactured != null) return manufactured;
    return null;
  }

  /// Whether resource [r] is allowed in region [regionId] (e.g. 'oldWorld', 'newWorld').
  bool isAllowedInRegion(Resource r, String regionId) {
    final rule = regionRule[r];
    if (rule == null) return false;
    switch (rule) {
      case ResourceRegionRule.oldWorldOnly:
        return regionId == 'oldWorld';
      case ResourceRegionRule.newWorldOnly:
        return regionId == 'newWorld';
      case ResourceRegionRule.both:
        return true;
    }
  }

  /// Whether resource [r] may spawn on terrain [t].
  bool isAllowedOnTerrain(Resource r, TerrainType t) {
    final list = allowedTerrains[r];
    return list != null && list.contains(t);
  }

  /// Full rules per Imperialism II Terrain and Development table.
  /// Region, terrain, and spawn-weight (inverse to default price) per resource.
  static ResourceRules get defaultRules {
    return ResourceRules(
      regionRule: {
        Resource.grain: ResourceRegionRule.oldWorldOnly,
        Resource.meat: ResourceRegionRule.oldWorldOnly,
        Resource.wool: ResourceRegionRule.oldWorldOnly,
        Resource.horses: ResourceRegionRule.oldWorldOnly,
        Resource.timber: ResourceRegionRule.both,
        Resource.iron: ResourceRegionRule.both,
        Resource.copper: ResourceRegionRule.both,
        Resource.tin: ResourceRegionRule.both,
        Resource.coal: ResourceRegionRule.both,
        Resource.sugarCane: ResourceRegionRule.newWorldOnly,
        Resource.tobacco: ResourceRegionRule.newWorldOnly,
        Resource.cotton: ResourceRegionRule.newWorldOnly,
        Resource.furs: ResourceRegionRule.newWorldOnly,
        Resource.spices: ResourceRegionRule.newWorldOnly,
        Resource.silver: ResourceRegionRule.newWorldOnly,
        Resource.gold: ResourceRegionRule.newWorldOnly,
        Resource.gems: ResourceRegionRule.newWorldOnly,
        Resource.diamonds: ResourceRegionRule.newWorldOnly,
      },
      allowedTerrains: {
        Resource.grain: [TerrainType.plains],
        Resource.meat: [TerrainType.plains],
        Resource.wool: [TerrainType.hills],
        Resource.horses: [TerrainType.plains],
        Resource.timber: [
          TerrainType.hardwoodForest,
          TerrainType.scrubForest,
        ],
        Resource.iron: [TerrainType.hills, TerrainType.mountain],
        Resource.copper: [TerrainType.hills, TerrainType.mountain],
        Resource.tin: [TerrainType.swamp],
        Resource.coal: [TerrainType.hills, TerrainType.mountain],
        Resource.sugarCane: [TerrainType.plains],
        Resource.tobacco: [TerrainType.plains],
        Resource.cotton: [TerrainType.plains],
        Resource.furs: [TerrainType.hardwoodForest],
        Resource.spices: [TerrainType.plains],
        Resource.silver: [TerrainType.hills],
        Resource.gold: [TerrainType.mountain],
        Resource.gems: [TerrainType.mountain],
        Resource.diamonds: [TerrainType.desert],
      },
      defaultMarketPrice: {
        Resource.grain: 50,
        Resource.meat: 45,
        Resource.wool: 40,
        Resource.horses: 60,
        Resource.timber: 30,
        Resource.iron: 80,
        Resource.copper: 70,
        Resource.tin: 75,
        Resource.coal: 90,
        Resource.sugarCane: 35,
        Resource.tobacco: 40,
        Resource.cotton: 45,
        Resource.furs: 55,
        Resource.spices: 50,
        Resource.silver: 100,
        Resource.gold: 166,
        Resource.gems: 250,
        Resource.diamonds: 500,
      },
      manufacturedDefaultMarketPrice:
          _defaultManufacturedMarketPrice,
    );
  }

  /// Canonical manufactured-commodity base prices, derived from the
  /// summed input cost of each commodity's canonical recipe in
  /// [production-recipes.md](../game/production-recipes.md) at the default
  /// raw-resource prices above. Per
  /// `SPEC/game/commodity-catalog.md` § *Manufactured base prices*.
  ///
  /// Derivation (sum of input prices, no markup; fabric uses the cheaper
  /// wool variant):
  ///
  /// | Commodity        | Recipe                                  | Base price |
  /// |------------------|-----------------------------------------|-----------:|
  /// | `lumber`         | `timber x 2` (30 * 2)                   | 60         |
  /// | `fabric`         | `wool x 2`   (40 * 2)                   | 80         |
  /// | `castIron`       | `timber x 2 + iron x 2` (60 + 160)      | 220        |
  /// | `refinedSugar`   | `sugarCane x 2` (35 * 2)                | 70         |
  /// | `cigars`         | `tobacco x 3` (40 * 3)                  | 120        |
  /// | `furHats`        | `furs x 2` (55 * 2)                     | 110        |
  /// | `steel`          | `castIron x 2 + coal x 1` (440 + 90)    | 530        |
  /// | `paper`          | `timber x 3` (30 * 3)                   | 90         |
  /// | `bronze`         | `copper x 1 + tin x 1` (70 + 75)        | 145        |
  static const Map<String, int> _defaultManufacturedMarketPrice =
      <String, int>{
    'lumber': 60,
    'fabric': 80,
    'castIron': 220,
    'refinedSugar': 70,
    'cigars': 120,
    'furHats': 110,
    'steel': 530,
    'paper': 90,
    'bronze': 145,
  };
}
