part of 'connectivity_resolver.dart';

/// True if the capital tile is adjacent to sea (seaboard). SPEC/game/capital-and-connectivity § Port connection to capital.
bool _isCapitalTileOnSeaboard(
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
    if (!_isLandProvinceGridCell(cellId, capital.regionId, provinceIdsByType)) {
      return true;
    }
  }
  return false;
}

/// Port tile key -> (fullProvinceId, seaZoneId). Built from portsByProvinceSeaboard.
/// Key format: fullProvinceId|seaZoneId (e.g. oldWorld|p1|sea1) or legacy provinceId|seaZoneId (2 parts).
Map<String, (String, String)> _portToProvinceSeaZone(WorldState worldState) {
  final out = <String, (String, String)>{};
  for (final e in worldState.portsByProvinceSeaboard.entries) {
    final decoded = decodePortSeaboardRegistryKey(e.key);
    if (decoded == null) continue;
    out[e.value] = (decoded.fullProvinceId, decoded.seaZoneId);
  }
  return out;
}

int _transportLevelAtTile(
  WorldState worldState,
  String tileKey,
  Map<String, (String, String)> portTileToProvinceSeaZone,
) {
  if (portTileToProvinceSeaZone.containsKey(tileKey)) return 4;
  final r = worldState.tileState.roadLevel(tileKey);
  return r > 0 ? r : 0;
}

String? _fullProvinceIdFromTileKey(String tileKey) {
  final coords = parseTileKeyCoordinates(tileKey);
  if (coords == null) return null;
  return '${coords.regionId}|${coords.provinceLocalId}';
}

/// Tile grids use local province ids (`p2`); [buildCombinedTopology] uses prefixed node ids (`oldWorld|p2`).
bool _isLandProvinceGridCell(
  String localCellId,
  String regionId,
  Set<String> landProvinceNodeIds,
) {
  if (landProvinceNodeIds.contains(localCellId)) return true;
  return landProvinceNodeIds.contains(ProvinceId.full(regionId, localCellId));
}

/// Adjacent tile keys (4-neighbour). Includes tiles in same or neighbouring provinces (any land cell). Tile key uses neighbour's province id.
List<String> _adjacentTileKeys(
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
    if (!_isLandProvinceGridCell(cellId, regionId, provinceIdsByType)) continue;
    final fullProvinceId = '$regionId|$cellId';
    out.add(CapitalTile.tileKey(regionId, fullProvinceId, nx, ny));
  }
  return out;
}
