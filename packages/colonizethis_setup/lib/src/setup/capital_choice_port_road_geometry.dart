part of 'capital_choice.dart';

TopologyNode? _topologyNodeById(MapTopology topology, String id) {
  for (final n in topology.nodes) {
    if (n.id == id) return n;
  }
  return null;
}

Set<String> _seaZonesAdjacentToProvince(
  MapTopology topology,
  String provinceId,
) {
  final out = <String>{};
  for (final edge in topology.edges) {
    if (edge.id1 != provinceId && edge.id2 != provinceId) continue;
    final other = edge.id1 == provinceId ? edge.id2 : edge.id1;
    final node = _topologyNodeById(topology, other);
    if (node != null && node.type == TopologyNodeType.seaZone) out.add(other);
  }
  return out;
}

/// Province node ids in [topology]. Single source of truth for the
/// `topology.nodes.where(province).map(id).toSet()` construction the adjacency
/// scans previously recomputed independently per call; callers compute it once
/// per scan and thread it into the `_isTileAdjacentTo*` helpers.
Set<String> _provinceNodeIds(MapTopology topology) => topology.nodes
    .where((n) => n.type == TopologyNodeType.province)
    .map((n) => n.id)
    .toSet();

/// Visits the in-bounds 4-neighbor cell ids of ([x], [y]) in
/// [kGridNeighborsCardinal4] order, returning `true` as soon as [test] does.
/// Single neighbor-iteration skeleton shared by the adjacency scans.
bool _anyCardinalNeighborCell(
  int x,
  int y,
  TileMapResult map,
  bool Function(String cellId) test,
) {
  final w = map.width;
  final h = map.height;
  for (final d in kGridNeighborsCardinal4) {
    final nx = x + d.$1;
    final ny = y + d.$2;
    if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
    if (test(map.cell(nx, ny))) return true;
  }
  return false;
}

bool _isTileAdjacentToSea(
  int x,
  int y,
  TileMapResult map,
  MapTopology topology, {
  Set<String>? provinceIds,
}) {
  final ids = provinceIds ?? _provinceNodeIds(topology);
  return _anyCardinalNeighborCell(
    x,
    y,
    map,
    (cellId) => !ids.contains(cellId),
  );
}

bool _isTileAdjacentToOtherProvince(
  int x,
  int y,
  TileMapResult map,
  Set<String> provinceIds,
  String provinceId,
) {
  return _anyCardinalNeighborCell(
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
  final ids = provinceIds ?? _provinceNodeIds(topology);
  int? bestDist;
  int? bestX;
  int? bestY;
  for (var y = 0; y < map.height; y++) {
    for (var x = 0; x < map.width; x++) {
      if (map.cell(x, y) != provinceId) continue;
      if (!_isTileAdjacentToSeaZone(
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

bool _isTileAdjacentToSeaZone(
  int x,
  int y,
  TileMapResult map,
  MapTopology topology,
  String seaZoneId, {
  Set<String>? provinceIds,
}) {
  final ids = provinceIds ?? _provinceNodeIds(topology);
  final seaZoneLocal = seaZoneId.contains('|')
      ? seaZoneId.split('|').last
      : seaZoneId;
  return _anyCardinalNeighborCell(x, y, map, (cellId) {
    if (ids.contains(cellId)) return false;
    return cellId == seaZoneId || cellId == seaZoneLocal;
  });
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
