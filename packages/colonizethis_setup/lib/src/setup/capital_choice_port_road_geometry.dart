part of 'capital_choice.dart';

bool _isTileAdjacentToSea(
  int x,
  int y,
  TileMapResult map,
  MapTopology topology, {
  Set<String>? provinceIds,
}) {
  final ids = provinceIds ?? provinceNodeIds(topology);
  return anyCardinalNeighborCell(x, y, map, (cellId) => !ids.contains(cellId));
}

bool _isTileAdjacentToOtherProvince(
  int x,
  int y,
  TileMapResult map,
  Set<String> provinceIds,
  String provinceId,
) {
  return anyCardinalNeighborCell(
    x,
    y,
    map,
    (cellId) => provinceIds.contains(cellId) && cellId != provinceId,
  );
}

(int, int)? _nearestCoastalTileInProvinceForSeaZone(
  TileMapResult map,
  String provinceId,
  int fromX,
  int fromY,
  MapTopology topology,
  String seaZoneId, {
  Set<String>? provinceIds,
}) {
  final ids = provinceIds ?? provinceNodeIds(topology);
  int? bestDist;
  int? bestX;
  int? bestY;
  for (var y = 0; y < map.height; y++) {
    for (var x = 0; x < map.width; x++) {
      if (map.cell(x, y) != provinceId) continue;
      if (!tileAdjacentToSeaZone(
        x,
        y,
        map,
        topology,
        seaZoneId,
        provinceIds: ids,
      )) {
        continue;
      }
      final dist = (x - fromX).abs() + (y - fromY).abs();
      if (bestDist == null || dist < bestDist) {
        bestDist = dist;
        bestX = x;
        bestY = y;
      }
    }
  }
  if (bestX == null || bestY == null) return null;
  return (bestX, bestY);
}

/// Shortest path on province tiles only (BFS). Returns ordered list (start .. end) inclusive.
/// Used for road placement from port to capital. SPEC/game/capital-and-connectivity § Capital Setup.
List<(int, int)> _shortestPathOnProvinceTiles(
  TileMapResult map,
  String localProvinceId,
  int fromX,
  int fromY,
  int toX,
  int toY,
) {
  if (fromX == toX && fromY == toY) return [(fromX, fromY)];
  final parents = bfsGridParents(
    startX: fromX,
    startY: fromY,
    width: map.width,
    height: map.height,
    passable: (x, y) => map.cell(x, y) == localProvinceId,
  );
  return reconstructGridPath(parents: parents, toX: toX, toY: toY) ??
      [(fromX, fromY)];
}
