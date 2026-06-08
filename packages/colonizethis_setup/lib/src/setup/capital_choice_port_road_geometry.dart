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

bool _isTileAdjacentToSea(
  int x,
  int y,
  TileMapResult map,
  MapTopology topology,
) {
  final provinceIds = topology.nodes
      .where((n) => n.type == TopologyNodeType.province)
      .map((n) => n.id)
      .toSet();
  final w = map.width;
  final h = map.height;
  for (final d in kGridNeighborsCardinal4) {
    final nx = x + d.$1;
    final ny = y + d.$2;
    if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
    final cellId = map.cell(nx, ny);
    if (!provinceIds.contains(cellId)) return true;
  }
  return false;
}

bool _isTileAdjacentToOtherProvince(
  int x,
  int y,
  TileMapResult map,
  Set<String> provinceIds,
  String provinceId,
) {
  final w = map.width;
  final h = map.height;
  for (final d in kGridNeighborsCardinal4) {
    final nx = x + d.$1;
    final ny = y + d.$2;
    if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
    final cellId = map.cell(nx, ny);
    if (!provinceIds.contains(cellId)) continue;
    if (cellId != provinceId) return true;
  }
  return false;
}

(int, int)? _nearestCoastalTileInProvinceForSeaZone(
  TileMapResult map,
  String provinceId,
  int fromX,
  int fromY,
  MapTopology topology,
  String seaZoneId,
) {
  int? bestDist;
  int? bestX;
  int? bestY;
  for (var y = 0; y < map.height; y++) {
    for (var x = 0; x < map.width; x++) {
      if (map.cell(x, y) != provinceId) continue;
      if (!_isTileAdjacentToSeaZone(x, y, map, topology, seaZoneId)) continue;
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
  String seaZoneId,
) {
  final provinceIds = topology.nodes
      .where((n) => n.type == TopologyNodeType.province)
      .map((n) => n.id)
      .toSet();
  final seaZoneLocal = seaZoneId.contains('|')
      ? seaZoneId.split('|').last
      : seaZoneId;
  final w = map.width;
  final h = map.height;
  for (final d in kGridNeighborsCardinal4) {
    final nx = x + d.$1;
    final ny = y + d.$2;
    if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
    final cellId = map.cell(nx, ny);
    if (provinceIds.contains(cellId)) continue;
    if (cellId == seaZoneId || cellId == seaZoneLocal) return true;
  }
  return false;
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
  final w = map.width;
  final h = map.height;
  final visited = <String>{};
  final parent = <String, (int, int)>{};
  final startKey = '$fromX|$fromY';
  visited.add(startKey);
  final queue = Queue<(int, int)>()..add((fromX, fromY));
  while (queue.isNotEmpty) {
    final (cx, cy) = queue.removeFirst();
    if (cx == toX && cy == toY) {
      final path = <(int, int)>[];
      var (px, py) = (toX, toY);
      while (true) {
        path.insert(0, (px, py));
        final key = '$px|$py';
        final p = parent[key];
        if (p == null) break;
        px = p.$1;
        py = p.$2;
      }
      return path;
    }
    for (final d in kGridNeighborsCardinal4) {
      final nx = cx + d.$1;
      final ny = cy + d.$2;
      if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;
      if (map.cell(nx, ny) != localProvinceId) continue;
      final nkey = '$nx|$ny';
      if (visited.contains(nkey)) continue;
      visited.add(nkey);
      parent[nkey] = (cx, cy);
      queue.add((nx, ny));
    }
  }
  return [(fromX, fromY)];
}
