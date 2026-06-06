import 'dart:collection';

import 'package:colonizethis_data/colonizethis_data.dart'
    show MapTopology, TopologyNodeType;

/// Canonical region id the fleet-reach scenarios sail toward (Refs #2336).
///
/// Matches the `newWorld` region id used by `regionDisplayLabel('newWorld')`
/// in `MoveFleetDialog` and by the fleet-reach NW predicates in
/// `e2e_test_shared_fleet_reach_nw_predicates.dart`.
const String kE2eNewWorldRegionId = 'newWorld';

/// Picks the [candidates] sea-zone id with the shortest sea–sea topology
/// distance to any sea zone in [targetRegionId], so a fleet-reach turn moves
/// the fleet *toward* the New World warp instead of oscillating between
/// equidistant zones.
///
/// Background (Refs #2336 AC6/AC7): `MoveFleetDialog` lists only the fleet's
/// **adjacent** sea zones, sorted by display label. The pre-fix fleet-reach
/// helper tapped the alphabetically-first row when no cross-region warp row was
/// present. Because sea adjacency is symmetric, that undirected walk could
/// deterministically bounce between two zones and never reach a warp-adjacent
/// zone within the 35-turn budget, so the New World was never reached and the
/// fleet-reach scenarios failed. Ranking the presented candidates by their BFS
/// distance to the New World guarantees monotonic progress (each turn moves to
/// a strictly lower distance), which both fixes the reach and removes the
/// oscillation without any cross-turn state.
///
/// Algorithm: multi-source breadth-first search over **sea→sea** topology edges
/// starting from every sea zone whose `regionId == targetRegionId`, producing a
/// distance map; the candidate with the smallest distance wins. Pure over
/// [topology] (reads no globals); deterministic for fixed inputs.
///
/// Contract:
///
/// - Returns `null` when [candidates] is empty.
/// - Among reachable candidates, returns the one with the smallest distance to
///   [targetRegionId]; ties are broken by **ascending id** so selection is
///   deterministic.
/// - When no candidate can reach [targetRegionId] in [topology] (disconnected,
///   or the ids are absent from [topology]), returns the **ascending-first**
///   candidate so the caller still selects a deterministic destination rather
///   than failing — preserving the legacy `seaRadio.first`-style fallback.
String? e2eBestSeaZoneTowardRegion({
  required MapTopology topology,
  required Iterable<String> candidates,
  String targetRegionId = kE2eNewWorldRegionId,
}) {
  final sortedCandidates = candidates.toList()..sort();
  if (sortedCandidates.isEmpty) {
    return null;
  }

  final seaRegionById = <String, String>{};
  for (final node in topology.nodes) {
    if (node.type == TopologyNodeType.seaZone) {
      seaRegionById[node.id] = node.regionId;
    }
  }

  final seaAdjacency = <String, List<String>>{};
  for (final edge in topology.edges) {
    final a = edge.id1;
    final b = edge.id2;
    if (!seaRegionById.containsKey(a) || !seaRegionById.containsKey(b)) {
      continue;
    }
    (seaAdjacency[a] ??= <String>[]).add(b);
    (seaAdjacency[b] ??= <String>[]).add(a);
  }

  final distanceToTarget = <String, int>{};
  final queue = Queue<String>();
  for (final entry in seaRegionById.entries) {
    if (entry.value == targetRegionId) {
      distanceToTarget[entry.key] = 0;
      queue.add(entry.key);
    }
  }
  while (queue.isNotEmpty) {
    final current = queue.removeFirst();
    final currentDistance = distanceToTarget[current]!;
    for (final neighbour in seaAdjacency[current] ?? const <String>[]) {
      if (distanceToTarget.containsKey(neighbour)) {
        continue;
      }
      distanceToTarget[neighbour] = currentDistance + 1;
      queue.add(neighbour);
    }
  }

  String? best;
  int? bestDistance;
  for (final candidate in sortedCandidates) {
    final distance = distanceToTarget[candidate];
    if (distance == null) {
      continue;
    }
    if (bestDistance == null || distance < bestDistance) {
      bestDistance = distance;
      best = candidate;
    }
  }
  return best ?? sortedCandidates.first;
}
