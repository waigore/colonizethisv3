import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Internal topology helpers for AI perception snapshot building.
Set<String> neighborProvinceIdsFromTopology(
  MapTopology topology,
  Set<String> ownedFullIds,
  PlayerView view,
) {
  final nodesByFullId = <String, TopologyNode>{
    for (final n in topology.nodes) n.id: n,
  };
  final nodesByRegion = topologyNodesByRegionId(topology);
  final out = <String>{};
  for (final fullId in ownedFullIds) {
    final regionId = ProvinceId.regionIdFrom(fullId);
    final localId = ProvinceId.localIdFrom(fullId);
    for (final edge in topology.edges) {
      final otherEnd = otherEndOfEdgeForAnchor(
        edge,
        fullId: fullId,
        localId: localId,
      );
      if (otherEnd == null) continue;
      final neighborNode = _topologyNodeForRef(
        nodeRef: otherEnd,
        regionId: regionId,
        nodesByFullId: nodesByFullId,
        nodesByRegion: nodesByRegion,
      );
      if (neighborNode == null ||
          neighborNode.type != TopologyNodeType.province) {
        continue;
      }
      final neighborFullId = ProvinceId.isPrefixed(neighborNode.id)
          ? neighborNode.id
          : ProvinceId.full(neighborNode.regionId, neighborNode.id);
      if (!ownedFullIds.contains(neighborFullId)) {
        out.add(neighborFullId);
      }
    }
  }
  return out;
}

TopologyNode? _topologyNodeForRef({
  required String nodeRef,
  required String regionId,
  required Map<String, TopologyNode> nodesByFullId,
  required Map<String, Map<String, TopologyNode>> nodesByRegion,
}) {
  return nodesByFullId[nodeRef] ??
      nodesByFullId[ProvinceId.full(regionId, nodeRef)] ??
      nodesByRegion[regionId]?[nodeRef];
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

/// Matches [anchor] as full province id (`region|local`) or local id only.
String? otherEndOfEdgeForAnchor(
  TopologyEdge edge, {
  required String fullId,
  required String localId,
}) {
  if (edge.id1 == fullId || edge.id1 == localId) return edge.id2;
  if (edge.id2 == fullId || edge.id2 == localId) return edge.id1;
  return null;
}

/// Legacy helper for unprefixed topology edges in unit tests.
String? otherEndOfEdge(TopologyEdge edge, String localId) {
  return otherEndOfEdgeForAnchor(edge, fullId: localId, localId: localId);
}
