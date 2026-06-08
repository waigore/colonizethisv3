/// Shared constants and helpers for the colonizethis_logic package.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart'
    show
        GamePlayerLookup,
        kGridNeighborsCardinal4,
        kRegionNewWorld,
        kRegionOldWorld;

export 'package:colonizethis_models/colonizethis_models.dart'
    show
        kUnitTypeBuilder,
        kUnitTypeEngineer,
        kUnitTypeExplorer,
        kUnitTypeMerchant,
        kUnitTypeRailBuilder,
        kUnitTypeSpy;
export 'package:colonizethis_world/colonizethis_world.dart'
    show
        GamePlayerLookup,
        kGridNeighborsCardinal4,
        kRegionNewWorld,
        kRegionOldWorld;

/// Work target string constants for work orders. Used across order suggestion,
/// validation, and application to avoid hardcoded string literals.
const String kWorkTargetStealTech = 'steal_tech';
const String kWorkTargetCounterSpy = 'counter_spy';
const String kWorkTargetPurchaseLand = 'purchase_land';
const String kWorkTargetExplore = 'explore';
const String kWorkTargetProspect = 'prospect';
const String kWorkTargetBuildImprovement = 'build_improvement';
const String kWorkTargetBuildRoad = 'build_road';
const String kWorkTargetBuildPort = 'build_port';
const String kWorkTargetBuildFort = 'build_fort';
const String kWorkTargetBuildRail = 'build_rail';
const String kWorkTargetUpgradeTown = 'upgrade_town';

/// Resource ids that count as minerals for work/purchase rules.
/// Shared across extraction, work orders, and order application helpers.
const Set<String> kMineralResourceIds = {
  'iron',
  'copper',
  'tin',
  'coal',
  'silver',
  'gold',
  'gems',
  'diamonds',
};

/// Per-terrain prospectability, derived from resource terrain rules:
/// any terrain that can host at least one mineral resource is prospectable.
final Map<TerrainType, bool> kProspectableByTerrainType = {
  for (final terrain in TerrainType.values)
    terrain: _buildProspectableTerrainsFromRules().contains(terrain),
};

Set<TerrainType> _buildProspectableTerrainsFromRules() {
  final rules = ResourceRules.defaultRules;
  final terrains = <TerrainType>{};
  for (final resource in Resource.values) {
    if (!kMineralResourceIds.contains(resource.name)) {
      continue;
    }
    terrains.addAll(rules.allowedTerrains[resource] ?? const <TerrainType>[]);
  }
  return terrains;
}

bool isProspectableTerrain(TerrainType terrain) =>
    kProspectableByTerrainType[terrain] ?? false;

bool isProspectableTerrainId(String? terrainTypeId) {
  if (terrainTypeId == null || terrainTypeId.isEmpty) {
    return false;
  }
  for (final terrain in TerrainType.values) {
    if (terrain.name == terrainTypeId) {
      return isProspectableTerrain(terrain);
    }
  }
  return false;
}
