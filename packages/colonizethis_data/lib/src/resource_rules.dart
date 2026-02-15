import 'resource.dart';
import 'terrain_type.dart';

/// Allowed region(s) for a resource. TDD 04b, GDD 04b.
enum ResourceRegionRule {
  oldWorldOnly,
  newWorldOnly,
  both,
}

/// Resource–region and resource–terrain rules plus default market price for spawn weights.
/// SPEC/program/tile-map-generation.md, TDD 04b. Phase 1: minimal config in code.
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

  /// Default Phase 1 rules: grain OW only on plains; timber both on forest; iron both on hills/mountain.
  static ResourceRules get defaultRules {
    return ResourceRules(
      regionRule: {
        Resource.grain: ResourceRegionRule.oldWorldOnly,
        Resource.timber: ResourceRegionRule.both,
        Resource.iron: ResourceRegionRule.both,
      },
      allowedTerrains: {
        Resource.grain: [TerrainType.plains],
        Resource.timber: [TerrainType.forest],
        Resource.iron: [TerrainType.hills, TerrainType.mountain],
      },
      defaultMarketPrice: {
        Resource.grain: 50,
        Resource.timber: 30,
        Resource.iron: 80,
      },
    );
  }
}
