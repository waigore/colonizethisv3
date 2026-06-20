import 'dart:collection';

import 'package:colonizethis_data/colonizethis_data.dart';

/// Shared graph traversals. Refactor slice for waigore/colonizethis#2071.
///
/// Includes [propagateConnectivityBottleneckQueue] for capital connectivity
/// (per-edge transport caps; not the same as [breadthFirstReachableInSubgraph])
/// and [bfsTopologyGraph], the canonical topology-graph BFS shared by the
/// sea-reachability planners (Refs #3403 Phase 2).

/// Connected components of the subgraph induced by [subset].
///
/// Uses depth-first search with an explicit stack. The next component root is
/// [unseen.first] on a copy of [subset], matching prior [Set.first] behavior.
List<Set<T>> connectedComponentsInSubset<T>(
  Set<T> subset,
  Map<T, Set<T>> adjacency,
) {
  final unseen = subset.toSet();
  final components = <Set<T>>[];
  while (unseen.isNotEmpty) {
    final start = unseen.first;
    final comp = <T>{};
    final stack = <T>[start];
    while (stack.isNotEmpty) {
      final u = stack.removeLast();
      if (!unseen.remove(u)) continue;
      comp.add(u);
      for (final v in adjacency[u] ?? <T>{}) {
        if (!subset.contains(v)) continue;
        if (!unseen.contains(v)) continue;
        stack.add(v);
      }
    }
    components.add(comp);
  }
  return components;
}

/// Assigns integer landmass ids (0, 1, …) to each key in [neighbours], one id
/// per undirected connected component of the province adjacency graph.
///
/// Outer iteration order is [neighbours.keys] iteration order (map insertion
/// order), matching [game_setup_ownership] landmass labeling.
Map<T, int> landmassIdsFromProvinceAdjacency<T>(Map<T, Set<T>> neighbours) {
  final landmassByProvince = <T, int>{};
  var currentId = 0;
  for (final province in neighbours.keys) {
    if (landmassByProvince.containsKey(province)) continue;
    final stack = <T>[province];
    landmassByProvince[province] = currentId;
    while (stack.isNotEmpty) {
      final p = stack.removeLast();
      for (final n in neighbours[p] ?? <T>{}) {
        if (landmassByProvince.containsKey(n)) continue;
        landmassByProvince[n] = currentId;
        stack.add(n);
      }
    }
    currentId++;
  }
  return landmassByProvince;
}

/// Breadth-first expansion from [seeds] following undirected edges in
/// [adjacency], restricted to [universe]. Returns every vertex reached,
/// including seeds.
Set<T> breadthFirstReachableInSubgraph<T>(
  Iterable<T> seeds,
  Map<T, Set<T>> adjacency,
  Set<T> universe, {
  void Function()? onDequeue,
}) {
  final reachable = <T>{...seeds};
  final queue = Queue<T>()..addAll(seeds);
  while (queue.isNotEmpty) {
    final z = queue.removeFirst();
    onDequeue?.call();
    for (final n in adjacency[z] ?? <T>{}) {
      if (!universe.contains(n)) continue;
      if (reachable.contains(n)) continue;
      reachable.add(n);
      queue.add(n);
    }
  }
  return reachable;
}

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

/// Propagates tile connectivity using [queue], updating [pathCap] bottleneck
/// caps per neighbor (max candidate path min transport). Tiles may be re-queued
/// when their cap improves; this is **not** a plain undirected BFS.
///
/// Callers supply predicates and neighbor iteration; see
/// `connectivity_resolver.dart` § capital land connectivity.
void propagateConnectivityBottleneckQueue({
  required Queue<String> queue,
  required Set<String> connected,
  required Map<String, int> pathCap,
  required bool Function(String tileKey) shouldExpandEdgesFrom,
  required Iterable<String> Function(String tileKey) neighborsOf,
  required int Function(String neighborKey) transportLevelAt,
  void Function()? onDequeue,
}) {
  while (queue.isNotEmpty) {
    final key = queue.removeFirst();
    onDequeue?.call();
    if (!shouldExpandEdgesFrom(key)) continue;
    final bottleneckU = pathCap[key] ?? 0;
    for (final neighbor in neighborsOf(key)) {
      final transportN = transportLevelAt(neighbor);
      final candidate = bottleneckU < transportN ? bottleneckU : transportN;
      _relaxBottleneckNeighbor(
        neighbor: neighbor,
        candidate: candidate,
        connected: connected,
        pathCap: pathCap,
        queue: queue,
      );
    }
  }
}

void _relaxBottleneckNeighbor({
  required String neighbor,
  required int candidate,
  required Set<String> connected,
  required Map<String, int> pathCap,
  required Queue<String> queue,
}) {
  final existing = pathCap[neighbor] ?? -1;
  if (candidate > existing) {
    pathCap[neighbor] = candidate;
    connected.add(neighbor);
    queue.add(neighbor);
    return;
  }
  if (!connected.contains(neighbor)) {
    connected.add(neighbor);
    pathCap[neighbor] = candidate;
    queue.add(neighbor);
  }
}
