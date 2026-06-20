// SPEC/program/tile-map-gen-resources.md § Topology inference.

import 'package:colonizethis_data/colonizethis_data.dart';

import '../map_pipe_string_util.dart';
import '../tile_map_grid.dart';

/// Infers MapTopology from a tile map result. SPEC/program/tile-map-gen-resources.md § Topology inference.
/// Collects unique region ids from grid; classifies province vs sea zone; builds edges from adjacencies.
MapTopology inferTopologyFromTileMap(TileMapResult result, String regionId) {
  final ids = <String>{};
  TileMapGrid.forEachIndex(result.height, result.width, (y, x) {
    ids.add(result.cell(x, y));
  });

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
    final parsed = mapPipeTryParseTwoPartPair(pair);
    if (parsed != null) {
      edges.add(TopologyEdge(id1: parsed.$1, id2: parsed.$2));
    }
  }

  return MapTopology(
    nodes: nodes..sort((a, b) => a.id.compareTo(b.id)),
    edges: edges,
  );
}

/// Ids matching s + digits (e.g. s1, s2) are sea zones. Others are provinces.
bool _isSeaZoneId(String id) => RegExp(r'^s\d+$').hasMatch(id);
