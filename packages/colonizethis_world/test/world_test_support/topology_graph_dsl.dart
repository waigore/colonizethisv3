import 'package:colonizethis_data/colonizethis_data.dart';

/// Compact table-style topology graph builders for world test support
/// (Refs #3968). Prefer these over hand-rolled [TopologyNode]/[TopologyEdge]
/// lists in `topology_*_builders.dart`.

/// Single-region topology from province/sea id tables and undirected edges.
MapTopology topologyGraph({
  required String regionId,
  List<String> provinces = const [],
  List<String> seas = const [],
  List<(String, String)> edges = const [],
}) {
  return topologyGraphNodes(
    nodes: [
      for (final id in provinces)
        (id: id, regionId: regionId, type: TopologyNodeType.province),
      for (final id in seas)
        (id: id, regionId: regionId, type: TopologyNodeType.seaZone),
    ],
    edges: edges,
  );
}

/// Multi-region / mixed-id topology from explicit node rows and edges.
MapTopology topologyGraphNodes({
  required List<({String id, String regionId, TopologyNodeType type})> nodes,
  List<(String, String)> edges = const [],
}) {
  return MapTopology(
    nodes: [
      for (final n in nodes)
        TopologyNode(id: n.id, regionId: n.regionId, type: n.type),
    ],
    edges: [for (final e in edges) TopologyEdge(id1: e.$1, id2: e.$2)],
  );
}

/// Province node row for [topologyGraphNodes] (local or prefixed [id]).
({String id, String regionId, TopologyNodeType type}) provinceRow(
  String regionId,
  String id,
) => (id: id, regionId: regionId, type: TopologyNodeType.province);

/// Sea-zone node row for [topologyGraphNodes] (local or prefixed [id]).
({String id, String regionId, TopologyNodeType type}) seaRow(
  String regionId,
  String id,
) => (id: id, regionId: regionId, type: TopologyNodeType.seaZone);
