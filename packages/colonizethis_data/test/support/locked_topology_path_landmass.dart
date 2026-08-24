import 'package:colonizethis_data/colonizethis_data.dart';

MapTopology lockedTopologyPathLandmass({
  required String prefix,
  required int size,
  required int seaBoundProvinceCount,
}) {
  assert(seaBoundProvinceCount >= 1);
  assert(seaBoundProvinceCount <= size);
  final nodes = <TopologyNode>[];
  final edges = <TopologyEdge>[];
  for (var i = 0; i < size; i++) {
    nodes.add(
      TopologyNode(
        id: '$prefix$i',
        regionId: kOldWorldRegionId,
        type: TopologyNodeType.province,
      ),
    );
  }
  for (var i = 0; i < size - 1; i++) {
    edges.add(TopologyEdge(id1: '$prefix$i', id2: '${prefix}${i + 1}'));
  }
  for (var s = 0; s < seaBoundProvinceCount; s++) {
    final seaId = '${prefix}sea$s';
    nodes.add(
      TopologyNode(
        id: seaId,
        regionId: kOldWorldRegionId,
        type: TopologyNodeType.seaZone,
      ),
    );
    edges.add(TopologyEdge(id1: '$prefix$s', id2: seaId));
  }
  return MapTopology(nodes: nodes, edges: edges);
}

MapTopology lockedTopologyMerge(List<MapTopology> parts) {
  final nodes = <TopologyNode>[];
  final edges = <TopologyEdge>[];
  for (final p in parts) {
    nodes.addAll(p.nodes);
    edges.addAll(p.edges);
  }
  return MapTopology(nodes: nodes, edges: edges);
}
