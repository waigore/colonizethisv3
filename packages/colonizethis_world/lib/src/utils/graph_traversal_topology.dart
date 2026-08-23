import 'dart:collection';

import 'package:colonizethis_data/colonizethis_data.dart';

/// Canonical breadth-first traversal over a `MapTopology` graph, shared by the
/// sea-reachability planners (Refs #3403 Phase 2). The traversal owns frontier
/// expansion; callers pass the **cached** node-type and adjacency indexes
/// (`topologyNodeTypeById` / `topologyAdjacency` in `topology_helpers.dart`) so
/// no per-call `topology.nodes`/`topology.edges` rebuild happens on hot paths.
///
/// Expansion rules mirror the colonial sea-reachability contract
/// (SPEC/ai/ai-architecture.md § Colonial expansion):
///
///   * Every node in [sourceIds] is seeded at distance 0 and expanded.
///   * A province node is expanded (its neighbours enqueued) only when
///     [isExpandableProvince] returns true (owned anchors / owned territory).
///   * A sea-zone node is always expanded once, the first time it is reached.
///   * A province node for which [isForeignProvince] returns true is **collected
///     but not expanded** — it terminates that branch.
///
/// Each edge counts as distance 1. Neighbour iteration follows the insertion
/// order of the cached [adjacency] sets (built from `topology.edges` order), so
/// results are deterministic for fixed inputs (Refs #2509 Must-have #7).
///
/// Visitor callbacks are **observation-only** and cannot abort traversal:
///   * [onProvinceVisited] — fires once when an *expandable* province is first
///     enqueued, with its BFS distance.
///   * [onSeaVisited] — fires once when a sea zone is first enqueued.
///   * [onForeignProvinceDiscovered] — fires once, on the **first** time a
///     foreign province is reached. Because this is a uniform-weight FIFO BFS,
///     first discovery is also the shortest-distance discovery.
void bfsTopologyGraph({
  required Iterable<String> sourceIds,
  required Map<String, TopologyNodeType> nodeType,
  required Map<String, Set<String>> adjacency,
  required bool Function(String provinceId) isExpandableProvince,
  required bool Function(String provinceId) isForeignProvince,
  void Function(String provinceId, int distance)? onProvinceVisited,
  void Function(String seaZoneId, int distance)? onSeaVisited,
  void Function(String provinceId, int distance)? onForeignProvinceDiscovered,
}) {
  final visited = <String>{...sourceIds};
  final discoveredForeign = <String>{};
  final queue = Queue<_TopologyProbe>.from(
    sourceIds.map((id) => _TopologyProbe(id, 0)),
  );
  while (queue.isNotEmpty) {
    final cur = queue.removeFirst();
    final nextDistance = cur.distance + 1;
    for (final nb in adjacency[cur.id] ?? const <String>{}) {
      _visitTopologyNeighbor(
        nb: nb,
        distance: nextDistance,
        nodeType: nodeType,
        isExpandableProvince: isExpandableProvince,
        isForeignProvince: isForeignProvince,
        visited: visited,
        discoveredForeign: discoveredForeign,
        queue: queue,
        onProvinceVisited: onProvinceVisited,
        onSeaVisited: onSeaVisited,
        onForeignProvinceDiscovered: onForeignProvinceDiscovered,
      );
    }
  }
}

void _visitTopologyNeighbor({
  required String nb,
  required int distance,
  required Map<String, TopologyNodeType> nodeType,
  required bool Function(String provinceId) isExpandableProvince,
  required bool Function(String provinceId) isForeignProvince,
  required Set<String> visited,
  required Set<String> discoveredForeign,
  required Queue<_TopologyProbe> queue,
  required void Function(String provinceId, int distance)? onProvinceVisited,
  required void Function(String seaZoneId, int distance)? onSeaVisited,
  required void Function(String provinceId, int distance)?
  onForeignProvinceDiscovered,
}) {
  final nbType = nodeType[nb];
  if (nbType == null) return;

  if (nbType == TopologyNodeType.province) {
    if (isForeignProvince(nb) && discoveredForeign.add(nb)) {
      onForeignProvinceDiscovered?.call(nb, distance);
    }
    if (isExpandableProvince(nb) && visited.add(nb)) {
      onProvinceVisited?.call(nb, distance);
      queue.add(_TopologyProbe(nb, distance));
    }
    return;
  }
  if (nbType == TopologyNodeType.seaZone && visited.add(nb)) {
    onSeaVisited?.call(nb, distance);
    queue.add(_TopologyProbe(nb, distance));
  }
}

class _TopologyProbe {
  const _TopologyProbe(this.id, this.distance);

  final String id;
  final int distance;
}
