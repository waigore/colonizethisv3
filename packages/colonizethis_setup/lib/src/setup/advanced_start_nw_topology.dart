// Shared NW warp-entry helpers for advanced-start bootstrap. SPEC/game/advanced-starts.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

Map<String, Set<String>> advancedStartAdjacency(MapTopology topology) {
  final adj = <String, Set<String>>{
    for (final n in topology.nodes) n.id: <String>{},
  };
  for (final edge in topology.edges) {
    adj[edge.id1]!.add(edge.id2);
    adj[edge.id2]!.add(edge.id1);
  }
  return adj;
}

Map<String, TopologyNodeType> advancedStartNodeTypes(MapTopology topology) {
  return {for (final n in topology.nodes) n.id: n.type};
}

Set<String> advancedStartProvincesAdjacentToSeaZone(
  Map<String, Set<String>> adjacency,
  Map<String, TopologyNodeType> nodeTypes,
  String localSeaZoneId,
) {
  final adjacent = adjacency[localSeaZoneId];
  if (adjacent == null) return const {};
  return {
    for (final id in adjacent)
      if (nodeTypes[id] == TopologyNodeType.province) id,
  };
}

List<String> advancedStartNwSeaZonesFromCapital({
  required String capitalLocalProvinceId,
  required MapTopology topologyOldWorld,
  required List<WarpLink> warpLinks,
}) {
  final owAdj = advancedStartAdjacency(topologyOldWorld);
  final distances = <String, int>{capitalLocalProvinceId: 0};
  final queue = [capitalLocalProvinceId];
  var head = 0;
  while (head < queue.length) {
    final current = queue[head++];
    final nextDist = distances[current]! + 1;
    for (final next in owAdj[current] ?? const {}) {
      if (distances.containsKey(next)) continue;
      distances[next] = nextDist;
      queue.add(next);
    }
  }

  int? minDist;
  final candidateOwSeas = <String>{};
  for (final link in warpLinks) {
    if (link.regionId != kRegionOldWorld ||
        link.otherRegionId != kRegionNewWorld) {
      continue;
    }
    final dist = distances[link.seaZoneId];
    if (dist == null) continue;
    if (minDist == null || dist < minDist) {
      minDist = dist;
      candidateOwSeas.clear();
      candidateOwSeas.add(link.seaZoneId);
    } else if (dist == minDist) {
      candidateOwSeas.add(link.seaZoneId);
    }
  }

  final nwSeaLocalIds = <String>{};
  for (final link in warpLinks) {
    if (link.regionId != kRegionOldWorld ||
        link.otherRegionId != kRegionNewWorld) {
      continue;
    }
    if (candidateOwSeas.contains(link.seaZoneId)) {
      nwSeaLocalIds.add(link.otherSeaZoneId);
    }
  }
  return nwSeaLocalIds.toList()..sort();
}

List<String> advancedStartNwEntryProvinceLocalIds({
  required String capitalLocalProvinceId,
  required MapTopology topologyOldWorld,
  required MapTopology topologyNewWorld,
  required List<WarpLink> warpLinks,
}) {
  final nwSeaZones = advancedStartNwSeaZonesFromCapital(
    capitalLocalProvinceId: capitalLocalProvinceId,
    topologyOldWorld: topologyOldWorld,
    warpLinks: warpLinks,
  );
  if (nwSeaZones.isEmpty) return const [];

  final nwAdj = advancedStartAdjacency(topologyNewWorld);
  final nwTypes = advancedStartNodeTypes(topologyNewWorld);
  final entryProvinces = <String>{};
  for (final seaId in nwSeaZones) {
    entryProvinces.addAll(
      advancedStartProvincesAdjacentToSeaZone(nwAdj, nwTypes, seaId),
    );
  }
  return entryProvinces.toList()..sort();
}

List<String> advancedStartFloodFillProvinces({
  required Map<String, Set<String>> provinceNeighbours,
  required List<String> seedLocalIds,
  required int targetCount,
  bool Function(String localProvinceId)? accept,
  Set<String>? blockedLocalIds,
}) {
  if (targetCount <= 0 || seedLocalIds.isEmpty) return const [];

  final blocked = blockedLocalIds ?? const {};
  final visited = <String>{...seedLocalIds};
  final queue = List<String>.from(seedLocalIds)..sort();
  final collected = <String>[];

  var head = 0;
  while (head < queue.length && collected.length < targetCount) {
    final current = queue[head++];
    if (blocked.contains(current)) continue;
    if (accept != null && !accept(current)) continue;
    collected.add(current);
    final nextIds = provinceNeighbours[current]?.toList() ?? const [];
    nextIds.sort();
    for (final next in nextIds) {
      if (visited.add(next)) {
        queue.add(next);
      }
    }
  }

  return collected;
}
