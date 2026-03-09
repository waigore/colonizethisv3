import 'package:colonizethis_data/colonizethis_data.dart';

/// Topology helpers shared by movement and connectivity. SPEC/game/map-topology.md.

/// All province node ids in [topology].
Set<String> provinceNodeIds(MapTopology topology) {
  return topology.nodes
      .where((n) => n.type == TopologyNodeType.province)
      .map((n) => n.id)
      .toSet();
}

/// Province node ids in [regionId] in [topology].
Set<String> provinceNodeIdsForRegion(MapTopology topology, String regionId) {
  return topology.nodes
      .where((n) =>
          n.regionId == regionId && n.type == TopologyNodeType.province)
      .map((n) => n.id)
      .toSet();
}

/// True when any topology node id uses prefixed form (regionId|localId).
bool topologyUsesPrefixedIds(MapTopology topology) {
  return topology.nodes.any((n) => n.id.contains('|'));
}

/// All sea zone node ids in [topology].
Set<String> seaZoneNodeIds(MapTopology topology) {
  return topology.nodes
      .where((n) => n.type == TopologyNodeType.seaZone)
      .map((n) => n.id)
      .toSet();
}

/// Sea zones reachable from [startSeaZoneIds] by following S–S edges in [topology].
/// SPEC/game/map-topology.md, capital-and-connectivity § Sea paths.
Set<String> seaZonesReachableBySeaPath(
  MapTopology topology,
  Set<String> startSeaZoneIds,
) {
  final seaZoneIds = seaZoneNodeIds(topology);
  final neighbours = <String, Set<String>>{};
  for (final e in topology.edges) {
    final a = e.id1;
    final b = e.id2;
    if (seaZoneIds.contains(a) && seaZoneIds.contains(b)) {
      neighbours.putIfAbsent(a, () => {}).add(b);
      neighbours.putIfAbsent(b, () => {}).add(a);
    }
  }
  final reachable = Set<String>.from(startSeaZoneIds);
  final queue = List<String>.from(startSeaZoneIds);
  while (queue.isNotEmpty) {
    final z = queue.removeAt(0);
    for (final n in neighbours[z] ?? {}) {
      if (reachable.contains(n)) continue;
      reachable.add(n);
      queue.add(n);
    }
  }
  return reachable;
}

/// Sea zone ids adjacent to province [provinceNodeId] in topology (P–S edges).
Set<String> seaZonesAdjacentToProvince(
  MapTopology topology,
  String provinceNodeId,
) {
  final seaZoneIds = seaZoneNodeIds(topology);
  final out = <String>{};
  for (final edge in topology.edges) {
    if (edge.id1 != provinceNodeId && edge.id2 != provinceNodeId) continue;
    final other = edge.id1 == provinceNodeId ? edge.id2 : edge.id1;
    if (seaZoneIds.contains(other)) out.add(other);
  }
  return out;
}

