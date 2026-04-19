import 'map_topology.dart';
import 'topology_node.dart';

/// True if [provinceId] has at least one P–S edge in [topology].
bool isProvinceSeaBound(MapTopology topology, String provinceId) {
  for (final edge in topology.edges) {
    if (edge.id1 != provinceId && edge.id2 != provinceId) continue;
    final other = edge.id1 == provinceId ? edge.id2 : edge.id1;
    final node = _nodeById(topology, other);
    if (node != null && node.type == TopologyNodeType.seaZone) return true;
  }
  return false;
}

TopologyNode? _nodeById(MapTopology topology, String id) {
  for (final n in topology.nodes) {
    if (n.id == id) return n;
  }
  return null;
}
