/// Shared constants and helpers for the colonizethis_logic package.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const String kRegionOldWorld = 'oldWorld';
const String kRegionNewWorld = 'newWorld';

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

/// Safe player lookup by id. Returns null if not found.
extension GamePlayerLookup on Game {
  Player? playerById(String id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }
}
