import 'dart:collection';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'player_view.dart';

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

  final queue = Queue<String>.from(owned);
  final visited = Set<String>.from(owned);
  final invadable = <String>{};

  while (queue.isNotEmpty) {
    final cur = queue.removeFirst();
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
  required Queue<String> queue,
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
