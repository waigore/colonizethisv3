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

/// Non-owned provinces reachable from GP-owned anchors through owned provinces
/// and sea zones (including warp S–S links). Foreign provinces are collected but
/// not expanded through. SPEC/ai/ai-architecture.md § Colonial expansion.
Set<String> reachableNonOwnedProvinceIdsViaSeas(
  MapTopology topology,
  Set<String> anchorProvinceIds,
  PlayerView view, {
  String? regionIdFilter,
}) {
  final nodeType = <String, TopologyNodeType>{
    for (final n in topology.nodes) n.id: n.type,
  };
  final adj = <String, Set<String>>{};
  for (final e in topology.edges) {
    adj.putIfAbsent(e.id1, () => <String>{}).add(e.id2);
    adj.putIfAbsent(e.id2, () => <String>{}).add(e.id1);
  }

  final owned = <String>{};
  for (final id in anchorProvinceIds) {
    if (view.provincesById[id]?.ownerId == view.playerId) {
      owned.add(id);
    }
  }

  final queue = List<String>.from(owned);
  final visited = Set<String>.from(owned);
  final invadable = <String>{};

  while (queue.isNotEmpty) {
    final cur = queue.removeAt(0);
    for (final nb in adj[cur] ?? const <String>{}) {
      _visitSeaReachableNeighbor(
        nb: nb,
        nodeType: nodeType,
        view: view,
        regionIdFilter: regionIdFilter,
        visited: visited,
        queue: queue,
        invadable: invadable,
      );
    }
  }
  return invadable;
}

void _visitSeaReachableNeighbor({
  required String nb,
  required Map<String, TopologyNodeType> nodeType,
  required PlayerView view,
  required String? regionIdFilter,
  required Set<String> visited,
  required List<String> queue,
  required Set<String> invadable,
}) {
  if (visited.contains(nb)) return;
  final nbType = nodeType[nb];
  if (nbType == null) return;

  if (nbType == TopologyNodeType.province) {
    final ownerId = view.provincesById[nb]?.ownerId;
    final isOwn = ownerId == view.playerId;
    if (!isOwn &&
        ownerId != null &&
        ownerId.isNotEmpty &&
        (regionIdFilter == null ||
            ProvinceId.regionIdFrom(nb) == regionIdFilter)) {
      invadable.add(nb);
    }
    if (isOwn) {
      visited.add(nb);
      queue.add(nb);
    }
    return;
  }
  if (nbType == TopologyNodeType.seaZone) {
    visited.add(nb);
    queue.add(nb);
  }
}
