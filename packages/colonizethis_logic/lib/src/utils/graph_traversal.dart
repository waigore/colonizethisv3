import 'dart:collection';

/// Shared undirected graph traversals. Refactor slice for waigore/colonizethis#2071.
///
/// **Not a substitute for** domain-specific queues (e.g. tile connectivity with
/// per-edge transport caps in connectivity resolution).

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
  Set<T> universe,
) {
  final reachable = <T>{...seeds};
  final queue = Queue<T>()..addAll(seeds);
  while (queue.isNotEmpty) {
    final z = queue.removeFirst();
    for (final n in adjacency[z] ?? <T>{}) {
      if (!universe.contains(n)) continue;
      if (reachable.contains(n)) continue;
      reachable.add(n);
      queue.add(n);
    }
  }
  return reachable;
}
