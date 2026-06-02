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

/// Non-owned provinces reachable from GP-owned anchors through owned provinces
/// and sea zones (including warp S-S links), keyed by their BFS topology
/// distance from the **nearest** owned anchor. Foreign provinces are
/// collected but not expanded through (same termination contract as
/// [reachableNonOwnedProvinceIdsViaSeas]).
///
/// The distance is measured as **edges traversed in the topology graph**:
/// owned-to-sea-zone counts as 1, sea-to-foreign-province as 1 more, etc.
/// A foreign province sharing a direct province-province border with an
/// owned anchor therefore has distance 1, and a New World province
/// reached via the canonical owned-anchor -> OW sea zone -> NW sea zone
/// -> NW colony route has distance 3.
///
/// When the same foreign province is reachable via multiple paths the
/// **shortest** distance wins (BFS first-discovery semantics with each
/// edge weighted 1). The result is deterministic for fixed inputs
/// (Refs #2509 Must-have #7) -- BFS visits topology neighbors in the
/// insertion order of [MapTopology.edges], which is stable across runs
/// for a given map.
///
/// Refs #2509 § COLONIAL phase planner § planColonialAcquisition --
/// "For each unowned-visible newWorld| province (sorted by adjacency
/// distance to owned territory)". This helper supplies the
/// adjacency-distance key the acquisition planner uses to break ties
/// between candidate NW provinces.
Map<String, int> reachableNonOwnedProvinceDistancesViaSeas(
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

  final queue = Queue<_DistanceProbe>.from(
    owned.map((id) => _DistanceProbe(id, 0)),
  );
  final visited = Set<String>.from(owned);
  final invadable = <String, int>{};

  while (queue.isNotEmpty) {
    final cur = queue.removeFirst();
    final nextDistance = cur.distance + 1;
    for (final nb in adj[cur.id] ?? const <String>{}) {
      _visitSeaReachableNeighborWithDistance(
        nb: nb,
        distance: nextDistance,
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

class _DistanceProbe {
  const _DistanceProbe(this.id, this.distance);

  final String id;
  final int distance;
}

void _visitSeaReachableNeighborWithDistance({
  required String nb,
  required int distance,
  required Map<String, TopologyNodeType> nodeType,
  required PlayerView view,
  required String? regionIdFilter,
  required Set<String> visited,
  required Queue<_DistanceProbe> queue,
  required Map<String, int> invadable,
}) {
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
      final existing = invadable[nb];
      if (existing == null || distance < existing) {
        invadable[nb] = distance;
      }
    }
    if (isOwn && !visited.contains(nb)) {
      visited.add(nb);
      queue.add(_DistanceProbe(nb, distance));
    }
    return;
  }
  if (nbType == TopologyNodeType.seaZone) {
    if (visited.contains(nb)) return;
    visited.add(nb);
    queue.add(_DistanceProbe(nb, distance));
  }
}
