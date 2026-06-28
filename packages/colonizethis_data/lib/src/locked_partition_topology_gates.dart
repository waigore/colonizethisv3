// SPEC/program/locked-province-assigner.md — topology acceptance for locked OW/NW painting.
import 'map_topology.dart';
import 'topology_node.dart';

import 'topology_sea_bound.dart';

/// P–P province-only adjacency from [topology].
Map<String, Set<String>> provincePpNeighbours(MapTopology topology) {
  final provinces = {
    for (final n in topology.nodes)
      if (n.type == TopologyNodeType.province) n.id,
  };
  final neighbours = <String, Set<String>>{
    for (final id in provinces) id: <String>{},
  };
  for (final edge in topology.edges) {
    final a = edge.id1;
    final b = edge.id2;
    if (!provinces.contains(a) || !provinces.contains(b)) continue;
    neighbours[a]!.add(b);
    neighbours[b]!.add(a);
  }
  return neighbours;
}

/// Pushes the not-yet-[visited] P–P neighbours of [u] onto [stack].
void pushUnvisitedPpNeighbors(
  String u,
  Map<String, Set<String>> neighbours,
  Set<String> visited,
  List<String> stack,
) {
  for (final v in neighbours[u] ?? const <String>{}) {
    if (visited.contains(v)) continue;
    stack.add(v);
  }
}

/// Sorted multiset of P–P connected component sizes among province nodes.
List<int> ppLandComponentSizesSorted(MapTopology topology) {
  final neighbours = provincePpNeighbours(topology);
  if (neighbours.isEmpty) return const [];
  final visited = <String>{};
  final sizes = <int>[];
  for (final start in neighbours.keys) {
    if (visited.contains(start)) continue;
    var size = 0;
    final stack = <String>[start];
    while (stack.isNotEmpty) {
      final u = stack.removeLast();
      if (!visited.add(u)) continue;
      size++;
      pushUnvisitedPpNeighbors(u, neighbours, visited, stack);
    }
    sizes.add(size);
  }
  sizes.sort();
  return sizes;
}

bool _multisetEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// OW locked partition: `[13, 13, 17, 17]`.
bool oldWorldPartitionMatchesLockedProfile(MapTopology topology) {
  return _multisetEquals(ppLandComponentSizesSorted(topology), const [
    13,
    13,
    17,
    17,
  ]);
}

/// NW locked partition: `[6, 6, 9, 9]`.
bool newWorldPartitionMatchesLockedProfile(MapTopology topology) {
  return _multisetEquals(ppLandComponentSizesSorted(topology), const [
    6,
    6,
    9,
    9,
  ]);
}

/// Connected-component (landmass) summary over P–P province adjacency.
typedef LandmassInfo = ({
  int size,
  String minProvinceId,
  Set<String> provinces,
});

/// P–P connected components as [LandmassInfo], sorted by size desc then min id.
List<LandmassInfo> landmassesSortedDesc(Map<String, Set<String>> neighbours) {
  final visited = <String>{};
  final out = <LandmassInfo>[];
  for (final start in neighbours.keys.toList()..sort()) {
    if (visited.contains(start)) continue;
    final comp = <String>{};
    final stack = <String>[start];
    while (stack.isNotEmpty) {
      final u = stack.removeLast();
      if (!visited.add(u)) continue;
      comp.add(u);
      pushUnvisitedPpNeighbors(u, neighbours, visited, stack);
    }
    final minId = comp.reduce((a, b) => a.compareTo(b) < 0 ? a : b);
    out.add((size: comp.length, minProvinceId: minId, provinces: comp));
  }
  out.sort((a, b) {
    final c = b.size.compareTo(a.size);
    if (c != 0) return c;
    return a.minProvinceId.compareTo(b.minProvinceId);
  });
  return out;
}

/// Per-continent sea-bound count and role capacity checks for locked OW (#1830).
bool lockedOldWorldRoleFeasibilityHolds({
  required MapTopology topology,
  required Map<String, Set<String>> neighbours,
}) {
  final landmasses = landmassesSortedDesc(neighbours);
  if (landmasses.length != 4) return false;
  for (final lm in landmasses) {
    var sea = 0;
    for (final p in lm.provinces) {
      if (isProvinceSeaBound(topology, p)) sea++;
    }
    final big = lm.size >= 17;
    final needSea = big ? 2 : 1;
    if (sea < needSea) return false;
    final needCapacity = big ? 17 : 13;
    if (lm.size < needCapacity) return false;
  }
  return true;
}

/// Per-continent capacity for locked NW: 9+9+6+6 with 3 tribes on 9s and 2 on 6s.
bool lockedNewWorldRoleFeasibilityHolds({
  required MapTopology topology,
  required Map<String, Set<String>> neighbours,
}) {
  final landmasses = landmassesSortedDesc(neighbours);
  if (landmasses.length != 4) return false;
  for (final lm in landmasses) {
    if (lm.size != 9 && lm.size != 6) return false;
    final tribesOnContinent = lm.size == 9 ? 3 : 2;
    var sea = 0;
    for (final p in lm.provinces) {
      if (isProvinceSeaBound(topology, p)) sea++;
    }
    if (sea < tribesOnContinent) return false;
  }
  return true;
}
