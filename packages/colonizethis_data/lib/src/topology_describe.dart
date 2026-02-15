// SPEC/program/map-data.md. Topology description, map summary, province list and detail.
// Library APIs only; no CLI or I/O.

import 'map_topology.dart';
import 'tile_map_result.dart';
import 'topology_node.dart';

/// Returns Graphviz DOT format for topology graph. SPEC/program/map-data.md § Topology graph visualization.
/// Use with `neato -n -Tpng` when positions are provided; otherwise `dot -Tpng`.
String topologyToDot(
  MapTopology topology, {
  Map<String, int>? tileCounts,
  Map<String, (double x, double y)>? positions,
  double posScale = 12.0,
}) {
  final buf = StringBuffer();
  buf.writeln('graph topology {');
  if (positions != null && positions.isNotEmpty) {
    buf.writeln('  layout=neato;');
  }
  buf.writeln('  node [shape=circle, width=0.2, height=0.2, fixedsize=true, fontsize=8];');
  for (final n in topology.nodes) {
    final shape = n.type == TopologyNodeType.seaZone ? 'box' : 'circle';
    final label = tileCounts != null && tileCounts.containsKey(n.id)
        ? '${n.id} (${tileCounts[n.id]})'
        : n.id;
    final attrs = <String>['shape=$shape', 'label="$label"'];
    if (positions != null && positions.containsKey(n.id)) {
      final (x, y) = positions[n.id]!;
      attrs.add('pos="${x * posScale},${y * posScale}!"');
    }
    buf.writeln('  ${_dotId(n.id)} [${attrs.join(", ")}];');
  }
  for (final e in topology.edges) {
    buf.writeln('  ${_dotId(e.id1)} -- ${_dotId(e.id2)};');
  }
  buf.writeln('}');
  return buf.toString();
}

/// Escape node id for DOT (quote if needed).
String _dotId(String id) {
  if (id.isEmpty) return '""';
  if (RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(id)) return id;
  return '"${id.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
}

/// Returns a formatted string describing the topology graph (nodes and edges).
String describeTopologyGraph(MapTopology topology) {
  final buf = StringBuffer();
  buf.writeln('Nodes (${topology.nodes.length}):');
  for (final n in topology.nodes) {
    final typeLabel = n.type == TopologyNodeType.province ? 'P' : 'S';
    buf.writeln('  $typeLabel ${n.id} (region: ${n.regionId})');
  }
  buf.writeln('');
  buf.writeln('Edges (${topology.edges.length}):');
  for (final e in topology.edges) {
    buf.writeln('  ${e.id1} <-> ${e.id2}');
  }
  return buf.toString();
}

/// Counts tiles per region id (node id) from a tile map result.
Map<String, int> computeTileCountsPerRegion(TileMapResult result) {
  final counts = <String, int>{};
  for (var y = 0; y < result.height; y++) {
    for (var x = 0; x < result.width; x++) {
      final id = result.cell(x, y);
      counts[id] = (counts[id] ?? 0) + 1;
    }
  }
  return counts;
}

/// Centroids (average x, y) per region id from the tile map. Used for map-aligned
/// topology graph layout. Y is flipped (height - 1 - y) so graph Y matches tile
/// map (top = small Y). SPEC/program/map-data.md § Topology graph visualization.
Map<String, (double x, double y)> computeCentroidsPerRegion(TileMapResult result) {
  final sumX = <String, double>{};
  final sumY = <String, double>{};
  final count = <String, int>{};
  for (var y = 0; y < result.height; y++) {
    final graphY = result.height - 1.0 - y;
    for (var x = 0; x < result.width; x++) {
      final id = result.cell(x, y);
      sumX[id] = (sumX[id] ?? 0) + x;
      sumY[id] = (sumY[id] ?? 0) + graphY;
      count[id] = (count[id] ?? 0) + 1;
    }
  }
  return {
    for (final id in count.keys) id: (sumX[id]! / count[id]!, sumY[id]! / count[id]!),
  };
}

/// Returns a formatted map summary: per node id, tile count.
String formatMapSummary(MapTopology topology, Map<String, int> tileCounts) {
  final buf = StringBuffer();
  buf.writeln('Map summary (tile count per province/sea zone):');
  for (final n in topology.nodes) {
    final count = tileCounts[n.id] ?? 0;
    final typeLabel = n.type == TopologyNodeType.province ? 'P' : 'S';
    buf.writeln('  $typeLabel ${n.id} (region: ${n.regionId}): $count tiles');
  }
  return buf.toString();
}

/// Entry for one province in the interactive province list.
class ProvinceListEntry {
  const ProvinceListEntry({
    required this.id,
    required this.regionId,
    required this.tileCount,
  });
  final String id;
  final String regionId;
  final int tileCount;
}

/// Returns the list of provinces (P nodes only) for interactive mode.
List<ProvinceListEntry> getProvinceListForInteractive(
  MapTopology topology, [
  Map<String, int>? tileCounts,
]) {
  final counts = tileCounts ?? {};
  return topology.nodes
      .where((n) => n.type == TopologyNodeType.province)
      .map((n) => ProvinceListEntry(
            id: n.id,
            regionId: n.regionId,
            tileCount: counts[n.id] ?? 0,
          ))
      .toList();
}

/// Returns a formatted province detail string.
/// [ownerId] null means "no owner". Improvements shown as "no improvement data" (Phase 1).
String formatProvinceDetail(
  String provinceId,
  MapTopology topology, {
  int? tileCount,
  String? ownerId,
}) {
  TopologyNode? node;
  for (final n in topology.nodes) {
    if (n.id == provinceId) {
      node = n;
      break;
    }
  }
  if (node == null) {
    return 'Province not found: $provinceId';
  }
  final owner = ownerId ?? 'no owner';
  final tiles = tileCount != null ? '$tileCount' : '—';
  return 'Province: ${node.id}\n'
      '  region: ${node.regionId}\n'
      '  owner: $owner\n'
      '  tiles: $tiles\n'
      '  improvements: no improvement data';
}
