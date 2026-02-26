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
