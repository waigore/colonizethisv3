/// Pure tile/grid helpers shared by the connectivity resolver and propagation
/// core. Standalone library (extracted from the former
/// `connectivity_resolver.dart` `part` chain, Refs #3544 Step 3); the helpers
/// are public so the standalone `connectivity_propagation.dart` and
/// `connectivity_resolver.dart` libraries can both call them via imports instead
/// of `part`-scoped privates. None of these are surfaced through the package
/// barrel, so they remain package-internal.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../world_constants.dart';
import 'port_seaboard_registry_key.dart';

/// True if the capital tile is adjacent to sea (seaboard). SPEC/game/capital-and-connectivity § Port connection to capital.
bool isCapitalTileOnSeaboard(
  CapitalTile capital,
  Map<String, TileMapResult> tileMapByRegion,
  Set<String> provinceIdsByType,
) {
  final map = tileMapByRegion[capital.regionId];
  if (map == null) return false;
  final w = map.width;
  final h = map.height;
  for (final d in kGridNeighborsCardinal4) {
    final nx = capital.x + d.$1;
    final ny = capital.y + d.$2;
    if (nx < 0 || nx >= w || ny < 0 || ny >= h) return true;
    final cellId = map.cell(nx, ny);
    if (!isLandProvinceGridCell(cellId, capital.regionId, provinceIdsByType)) {
      return true;
    }
  }
  return false;
}

/// Port tile key -> (fullProvinceId, seaZoneId). Built from portsByProvinceSeaboard.
/// Key format: fullProvinceId|seaZoneId (e.g. oldWorld|p1|sea1) or legacy provinceId|seaZoneId (2 parts).
Map<String, (String, String)> portToProvinceSeaZone(WorldState worldState) {
  final out = <String, (String, String)>{};
  for (final e in worldState.portsByProvinceSeaboard.entries) {
    final decoded = decodePortSeaboardRegistryKey(e.key);
    if (decoded == null) continue;
    out[e.value] = (decoded.fullProvinceId, decoded.seaZoneId);
  }
  return out;
}

/// Effective transport level at [tileKey]: ports count as level 4, otherwise the road level.
int transportLevelAtTile(
  WorldState worldState,
  String tileKey,
  Map<String, (String, String)> portTileToProvinceSeaZone,
) {
  if (portTileToProvinceSeaZone.containsKey(tileKey)) return 4;
  final r = worldState.tileState.roadLevel(tileKey);
  return r > 0 ? r : 0;
}

/// Full prefixed province id (`regionId|localId`) parsed from a tile key, or null.
String? fullProvinceIdFromTileKey(String tileKey) {
  final coords = parseTileKeyCoordinates(tileKey);
  if (coords == null) return null;
  return ProvinceId.full(coords.regionId, coords.provinceLocalId);
}

/// Grid `(x, y)` parsed from a tile key, or null when the key is malformed.
///
/// Shared null-guarded `parseTileKeyCoordinates` projection (Refs #3710) so the
/// naval/fog coastal-geometry paths do not re-roll their own local copies.
({int x, int y})? xyFromTileKey(String tileKey) {
  final coords = parseTileKeyCoordinates(tileKey);
  if (coords == null) return null;
  return (x: coords.x, y: coords.y);
}

/// Tile grids use local province ids (`p2`); [buildCombinedTopology] uses prefixed node ids (`oldWorld|p2`).
bool isLandProvinceGridCell(
  String localCellId,
  String regionId,
  Set<String> landProvinceNodeIds,
) {
  if (landProvinceNodeIds.contains(localCellId)) return true;
  return landProvinceNodeIds.contains(ProvinceId.full(regionId, localCellId));
}

/// Adjacent tile keys (4-neighbour). Includes tiles in same or neighbouring provinces (any land cell). Tile key uses neighbour's province id.
List<String> adjacentTileKeys(
  String regionId,
  String provinceId,
  int x,
  int y,
  TileMapResult map,
  Set<String> provinceIdsByType,
) {
  final out = <String>[];
  final w = map.width;
  final h = map.height;
  for (final d in kGridNeighborsCardinal4) {
    final nx = x + d.$1;
    final ny = y + d.$2;
    if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
    final cellId = map.cell(nx, ny);
    if (!isLandProvinceGridCell(cellId, regionId, provinceIdsByType)) continue;
    final fullProvinceId = '$regionId|$cellId';
    out.add(CapitalTile.tileKey(regionId, fullProvinceId, nx, ny));
  }
  return out;
}
