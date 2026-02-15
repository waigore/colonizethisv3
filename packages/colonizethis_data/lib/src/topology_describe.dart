// SPEC/program/map-data.md. Topology description, map summary, province list and detail.
// Library APIs only; no CLI or I/O.

import 'map_topology.dart';
import 'tile_map_result.dart';
import 'topology_node.dart';

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
