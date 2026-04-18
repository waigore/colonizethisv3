import 'package:colonizethis_data/colonizethis_data.dart';

/// Single [MapTopology] with prefixed node ids (`regionId|localId`) and warp edges.
/// Mirrors [buildCombinedTopology] in colonizethis_logic (map package cannot depend on logic).
MapTopology combineRegionTopologies({
  required Map<String, MapTopology> topologyByRegion,
  List<WarpLink> warpLinks = const [],
}) {
  final nodes = <TopologyNode>[];
  final edges = <TopologyEdge>[];
  for (final entry in topologyByRegion.entries) {
    final regionId = entry.key;
    final topo = entry.value;
    for (final n in topo.nodes) {
      nodes.add(
        TopologyNode(id: '$regionId|${n.id}', regionId: regionId, type: n.type),
      );
    }
    for (final e in topo.edges) {
      edges.add(
        TopologyEdge(id1: '$regionId|${e.id1}', id2: '$regionId|${e.id2}'),
      );
    }
  }
  for (final link in warpLinks) {
    edges.add(TopologyEdge(id1: link.prefixedKey, id2: link.otherPrefixedKey));
  }
  return MapTopology(nodes: nodes, edges: edges);
}
