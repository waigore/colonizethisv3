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

/// NW sea zones to mark [VisibilityLevel.fogged] during advanced-start step 8:
/// shortest S–S paths from [entrySeaZoneLocalIds] to every sea zone P–S adjacent
/// to [revealedProvinceLocalIds]. Unreachable targets are omitted.
List<String> advancedStartFoggedNwSeaZoneLocalIds({
  required MapTopology topologyNewWorld,
  required List<String> entrySeaZoneLocalIds,
  required Set<String> revealedProvinceLocalIds,
}) {
  if (entrySeaZoneLocalIds.isEmpty || revealedProvinceLocalIds.isEmpty) {
    return const [];
  }

  final targetSeas = <String>{};
  for (final localId in revealedProvinceLocalIds) {
    targetSeas.addAll(
      seaZoneIdsAdjacentToProvince(
        topologyNewWorld,
        localId,
        regionId: kRegionNewWorld,
      ),
    );
  }
  if (targetSeas.isEmpty) return const [];

  final parents = <String, String?>{};
  for (final entry in entrySeaZoneLocalIds) {
    parents[entry] = null;
  }
  final visited = <String>{...entrySeaZoneLocalIds};
  final queue = List<String>.from(entrySeaZoneLocalIds)..sort();
  var head = 0;

  while (head < queue.length && !targetSeas.every(visited.contains)) {
    final current = queue[head++];
    for (final next in adjacentSeaZoneIdsSeaOnly(topologyNewWorld, current)) {
      if (visited.add(next)) {
        parents[next] = current;
        queue.add(next);
      }
    }
  }

  final onPath = <String>{};
  for (final target in targetSeas) {
    if (!visited.contains(target)) continue;
    var node = target;
    while (true) {
      if (!onPath.add(node)) break;
      final parent = parents[node];
      if (parent == null) break;
      node = parent;
    }
  }

  return onPath.toList()..sort();
}
