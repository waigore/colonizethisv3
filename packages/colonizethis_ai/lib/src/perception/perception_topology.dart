import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Internal topology helpers for AI perception snapshot building.
Set<String> neighborProvinceIdsFromTopology(
  MapTopology topology,
  Set<String> ownedFullIds,
  PlayerView view,
) {
  final nodesByRegion = topologyNodesByRegionId(topology);
  final out = <String>{};
  for (final fullId in ownedFullIds) {
    final regionId = ProvinceId.regionIdFrom(fullId);
    final localId = ProvinceId.localIdFrom(fullId);
    final nodesInRegion = nodesByRegion[regionId];
    if (nodesInRegion == null) continue;
    for (final edge in topology.edges) {
      final neighborLocalId = otherEndOfEdge(edge, localId);
      if (neighborLocalId == null) continue;
      final neighborNode = nodesInRegion[neighborLocalId];
      if (neighborNode == null ||
          neighborNode.type != TopologyNodeType.province) {
        continue;
      }
      final neighborFullId = ProvinceId.full(
        neighborNode.regionId,
        neighborNode.id,
      );
      if (!ownedFullIds.contains(neighborFullId)) out.add(neighborFullId);
    }
  }
  return out;
}

Map<String, Map<String, TopologyNode>> topologyNodesByRegionId(
  MapTopology topology,
) {
  final byRegion = <String, Map<String, TopologyNode>>{};
  for (final n in topology.nodes) {
    byRegion.putIfAbsent(n.regionId, () => <String, TopologyNode>{})[n.id] = n;
  }
  return byRegion;
}

String? otherEndOfEdge(TopologyEdge edge, String localId) {
  if (edge.id1 == localId) return edge.id2;
  if (edge.id2 == localId) return edge.id1;
  return null;
}
