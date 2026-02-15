/// Allowed terrain types per region. TDD 04b, SPEC/program/tile-map-generation.md.
/// Canonical source: Imperialism II Terrain and Development table (OW-only, NW-only, Both).
/// Phase 1: minimal mapping from current TerrainType enum; extend when terrain enum is expanded.

import 'terrain_type.dart';

/// Terrains allowed in the Old World (OW-only + Both from canonical table).
/// Phase 1: all current types; extend when adding e.g. Grain Farm, Open Range.
const List<TerrainType> oldWorldTerrains = [
  TerrainType.plains,
  TerrainType.forest,
  TerrainType.hills,
  TerrainType.mountain,
  TerrainType.swamp,
];

/// Terrains allowed in the New World (NW-only + Both from canonical table).
/// Phase 1: all current types; extend when adding e.g. Sugar Plantation, Desert.
const List<TerrainType> newWorldTerrains = [
  TerrainType.plains,
  TerrainType.forest,
  TerrainType.hills,
  TerrainType.mountain,
  TerrainType.swamp,
];

/// Returns the list of terrain types allowed for map generation in [regionId].
/// Recognized region ids: 'oldWorld', 'newWorld'. Unknown regions fall back to [oldWorldTerrains].
List<TerrainType> allowedTerrainsForRegion(String regionId) {
  switch (regionId) {
    case 'oldWorld':
      return oldWorldTerrains;
    case 'newWorld':
      return newWorldTerrains;
    default:
      return oldWorldTerrains;
  }
}
