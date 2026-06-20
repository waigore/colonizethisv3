import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Terrain and tech rules for Rail Builder `build_rail`. SPEC/game/tech-tree-transport.md,
/// SPEC/game/extraction-and-improvements.md, SPEC/program/orders.md.

/// Resolves [TerrainType] for [tileKey] using [tileMapByRegion], or `null` if missing.
TerrainType? terrainTypeForTileKey(
  Map<String, TileMapResult>? tileMapByRegion,
  String tileKey,
) {
  final coords = parseTileKeyCoordinates(tileKey);
  if (coords == null) return null;
  final map = tileMapByRegion?[coords.regionId];
  if (map == null) return null;
  if (coords.x < 0 ||
      coords.y < 0 ||
      coords.x >= map.width ||
      coords.y >= map.height) {
    return null;
  }
  return map.terrainAt(coords.x, coords.y);
}

/// Returns `null` if the order is allowed; otherwise a rejection reason for the player.
String? rejectionReasonForBuildRailOrder({
  required Map<String, bool>? techUnlocked,
  required int roadLevel,
  required TerrainType? terrain,
}) {
  if (roadLevel != 1 && roadLevel != 2) {
    if (roadLevel >= 4) {
      return 'Tile already has maximum transport level';
    }
    return 'Railroad requires an existing road (transport level 1 or 2) on the tile';
  }
  if (terrain == null) {
    return 'Tile terrain data required for railroad work orders';
  }

  final t = techUnlocked ?? const <String, bool>{};
  final early = t[kTechIdEarlySteamEngine] == true;
  final later = t[kTechIdLaterSteamEngine] == true;
  final dynamite = t[kTechIdDynamite] == true;

  switch (terrain) {
    case TerrainType.plains:
    case TerrainType.hardwoodForest:
    case TerrainType.scrubForest:
    case TerrainType.desert:
      if (!early && !later && !dynamite) {
        return 'Early Steam Engine or later rail technology required for this terrain';
      }
      return null;
    case TerrainType.hills:
    case TerrainType.swamp:
      if (!later && !dynamite) {
        return 'Later Steam Engine or Dynamite required for rail on this terrain';
      }
      return null;
    case TerrainType.mountain:
      if (!dynamite) {
        return 'Dynamite required for rail in mountains';
      }
      return null;
  }
}
