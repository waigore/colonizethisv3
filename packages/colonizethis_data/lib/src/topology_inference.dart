// SPEC/program/tile-map-generation.md § Topology inference.

import 'map_topology.dart';
import 'tile_map_result.dart';
import 'topology_node.dart';

/// Infers MapTopology from a tile map result. SPEC/program/tile-map-generation.md § Topology inference.
/// Collects unique region ids from grid; classifies province vs sea zone; builds edges from adjacencies.
MapTopology inferTopologyFromTileMap(
  TileMapResult result,
  String regionId,
  String seaZoneId,
) {
  final ids = <String>{};
  for (var y = 0; y < result.height; y++) {
    for (var x = 0; x < result.width; x++) {
      ids.add(result.cell(x, y));
    }
  }

  final nodes = <TopologyNode>[];
  for (final id in ids) {
    final type = _isSeaZoneId(id)
        ? TopologyNodeType.seaZone
        : TopologyNodeType.province;
    nodes.add(TopologyNode(id: id, regionId: regionId, type: type));
  }

  final pairs = result.adjacentRegionPairs();
  final edges = <TopologyEdge>[];
  for (final pair in pairs) {
    final parts = pair.split('|');
    if (parts.length == 2) {
      edges.add(TopologyEdge(id1: parts[0], id2: parts[1]));
    }
  }

  return MapTopology(nodes: nodes..sort((a, b) => a.id.compareTo(b.id)), edges: edges);
}

/// Ids matching s + digits (e.g. s1, s2) are sea zones. Others are provinces.
bool _isSeaZoneId(String id) => RegExp(r'^s\d+$').hasMatch(id);
