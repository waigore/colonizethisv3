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
  });

  /// Which region(s) this resource may appear in.
  final Map<Resource, ResourceRegionRule> regionRule;

  /// For each resource, terrain types on which it may spawn.
  final Map<Resource, List<TerrainType>> allowedTerrains;

  /// Default market price; spawn weight is inverse (higher price = rarer).
  final Map<Resource, int> defaultMarketPrice;

  /// Spawn weight for weighted random: inverse to price. Normalized per call.
  double spawnWeight(Resource r) {
    final price = defaultMarketPrice[r] ?? 1;
    return price > 0 ? 1.0 / price : 1.0;
  }

  /// Returns the integer default market price for a `CommodityId` string when
  /// the id matches a [Resource] enum name (the raw-resource commodities
  /// `grain`, `meat`, `wool`, `horses`, `timber`, `iron`, `copper`, `tin`,
  /// `coal`, `sugarCane`, `tobacco`, `cotton`, `furs`, `spices`, `silver`,
  /// `gold`, `gems`, `diamonds`).
  ///
  /// Returns `null` for commodities not enumerated in
  /// [defaultMarketPrice] — currently the manufactured commodities
  /// (`bronze`, `castIron`, `fabric`, `lumber`, `paper`, `steel`,
  /// `refinedSugar`, `cigars`, `furHats`). Manufactured commodities derive
  /// their first market price from in-game discovery rather than from a
  /// fixed catalog entry; SPEC/game/world-market.md § Price discovery clamps
  /// their floor at the most recent persisted price (the helper at
  /// `world_market_phase._basePriceForCommodityId` returns 0 for unknown
  /// ids so the floor stays inert mid-game).
  ///
  /// Used by trade UI surfaces (and any future seed code) to render a
  /// catalog-grounded fallback when `WorldMarketState.prices` lacks an
  /// entry. The mapping `CommodityId == Resource.name` mirrors the
  /// convention enforced by the production pipeline (see
  /// `world_market_phase.dart`).
  int? defaultMarketPriceForCommodityId(String commodityId) {
    if (commodityId.isEmpty) return null;
    for (final entry in defaultMarketPrice.entries) {
      if (entry.key.name == commodityId) return entry.value;
    }
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
        Resource.timber: [TerrainType.forest],
        Resource.iron: [TerrainType.hills, TerrainType.mountain],
        Resource.copper: [TerrainType.hills, TerrainType.mountain],
        Resource.tin: [TerrainType.swamp],
        Resource.coal: [TerrainType.hills, TerrainType.mountain],
        Resource.sugarCane: [TerrainType.plains],
        Resource.tobacco: [TerrainType.plains],
        Resource.cotton: [TerrainType.plains],
        Resource.furs: [TerrainType.forest],
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
    );
  }
}
