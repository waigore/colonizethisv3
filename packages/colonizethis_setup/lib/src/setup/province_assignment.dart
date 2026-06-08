/// Generic BFS territory assignment for province ownership.
/// Used by game_setup to assign Great Powers, Minor Nations, and Tribes.
library;

import 'dart:collection';
import 'dart:math';

/// True if [provinceId] shares a P–P edge with a province owned by [factionId].
bool provinceTouchesFaction(
  String provinceId,
  String factionId,
  Map<String, String> owners,
  Map<String, Set<String>> neighbours,
) {
  for (final n in neighbours[provinceId] ?? const <String>{}) {
    if (owners[n] == factionId) return true;
  }
  return false;
}

bool _neighborAssignableInBfs(
  String nb,
  String from,
  String factionId,
  Set<String> available,
  Map<String, int>? landmassIds,
  Map<String, int>? factionLandmassIds,
) {
  if (!available.contains(nb)) return false;
  if (landmassIds != null && landmassIds[nb] != landmassIds[from]) {
    return false;
  }
  final allowedLandmass = factionLandmassIds?[factionId];
  if (factionLandmassIds != null &&
      allowedLandmass != null &&
      landmassIds?[nb] != allowedLandmass) {
    return false;
  }
  return true;
}

String? _fallbackSeedForFaction({
  required String factionId,
  required List<String> sorted,
  required Map<String, int>? landmassIds,
  required Map<String, int>? factionLandmassIds,
  required Map<String, String> owners,
  required Map<String, Set<String>> neighbours,
}) {
  if (factionLandmassIds == null) {
    return sorted.isNotEmpty ? sorted.first : null;
  }
  final allowedLandmass = factionLandmassIds[factionId];
  if (allowedLandmass == null) {
    return sorted.isNotEmpty ? sorted.first : null;
  }
  for (final p in sorted) {
    if (landmassIds?[p] != allowedLandmass) continue;
    if (provinceTouchesFaction(p, factionId, owners, neighbours)) {
      return p;
    }
  }
  for (final p in sorted) {
    if (landmassIds?[p] == allowedLandmass) return p;
  }
  throw StateError(
    'assignTerritoriesByBfsGrowth: faction $factionId has no '
    'province on landmass $allowedLandmass',
  );
}

/// One round of fair BFS expansion plus optional seed recovery when stalled.
bool _runBfsGrowthRound({
  required List<String> factionIds,
  required Map<String, Set<String>> neighbours,
  required Map<String, int>? landmassIds,
  required Map<String, int>? factionLandmassIds,
  required Map<String, int> targetPerFaction,
  required Map<String, Queue<String>> queues,
  required Map<String, String> owners,
  required Set<String> available,
  required Map<String, int> assignedCount,
  required int total,
  required Random? neighborShuffleRandom,
}) {
  var anyProgress = false;
  var nextTotal = assignedCount.values.fold<int>(0, (a, b) => a + b);

  final order = factionIds.toList()
    ..sort((a, b) => assignedCount[a]!.compareTo(assignedCount[b]!));

  for (final factionId in order) {
    if (assignedCount[factionId]! >= targetPerFaction[factionId]!) continue;
    if (nextTotal >= total) break;
    final queue = queues[factionId]!;
    var expanded = false;

    while (queue.isNotEmpty && !expanded && nextTotal < total) {
      final from = queue.removeFirst();
      final nbrOrder = (neighbours[from] ?? const <String>{}).toList()
        ..sort();
      if (neighborShuffleRandom != null) {
        nbrOrder.shuffle(neighborShuffleRandom);
      }
      for (final nb in nbrOrder) {
        if (!_neighborAssignableInBfs(
          nb,
          from,
          factionId,
          available,
          landmassIds,
          factionLandmassIds,
        )) {
          continue;
        }
        owners[nb] = factionId;
        available.remove(nb);
        queue.add(nb);
        assignedCount[factionId] = assignedCount[factionId]! + 1;
        nextTotal++;
        anyProgress = true;
        expanded = true;
        break;
      }
    }
  }

  if (anyProgress || available.isEmpty || nextTotal >= total) {
    return anyProgress;
  }

  final underTarget = factionIds
      .where((id) => assignedCount[id]! < targetPerFaction[id]!)
      .toList();
  if (underTarget.isEmpty) return false;

  final sorted = available.toList()..sort();
  if (neighborShuffleRandom != null) sorted.shuffle(neighborShuffleRandom);
  for (final factionId in underTarget) {
    if (assignedCount[factionId]! >= targetPerFaction[factionId]!) {
      continue;
    }
    final seed = _fallbackSeedForFaction(
      factionId: factionId,
      sorted: sorted,
      landmassIds: landmassIds,
      factionLandmassIds: factionLandmassIds,
      owners: owners,
      neighbours: neighbours,
    );
    if (sorted.isEmpty || nextTotal >= total) break;
    if (seed == null) continue;
    if (!available.remove(seed)) continue;
    owners[seed] = factionId;
    queues[factionId]!.add(seed);
    assignedCount[factionId] = assignedCount[factionId]! + 1;
    nextTotal++;
    anyProgress = true;
  }
  return anyProgress;
}

int _greedyAssignRemainingTerritories({
  required Set<String> available,
  required Map<String, String> owners,
  required Map<String, Queue<String>> queues,
  required Map<String, int> assignedCount,
  required List<String> factionIds,
  required Map<String, Set<String>> neighbours,
  required Map<String, int>? landmassIds,
  required Map<String, int>? factionLandmassIds,
  required int total,
  required Random? neighborShuffleRandom,
  required int totalAssigned,
}) {
  var nextTotal = totalAssigned;
  if (available.isEmpty || nextTotal >= total) return nextTotal;

  final sortedRemaining = available.toList()..sort();
  if (neighborShuffleRandom != null) {
    sortedRemaining.shuffle(neighborShuffleRandom);
  }
  final remaining = Queue<String>()..addAll(sortedRemaining);
  while (remaining.isNotEmpty && nextTotal < total) {
    final provinceId = remaining.removeFirst();
    if (!available.remove(provinceId)) continue;

    final chosenFactionId = _greedyPickFactionForProvince(
      provinceId: provinceId,
      factionIds: factionIds,
      factionLandmassIds: factionLandmassIds,
      landmassIds: landmassIds,
      owners: owners,
      neighbours: neighbours,
      assignedCount: assignedCount,
    );

    owners[provinceId] = chosenFactionId;
    queues[chosenFactionId]!.add(provinceId);
    assignedCount[chosenFactionId] = assignedCount[chosenFactionId]! + 1;
    nextTotal++;
  }
  return nextTotal;
}

String _greedyPickFactionForProvince({
  required String provinceId,
  required List<String> factionIds,
  required Map<String, int>? factionLandmassIds,
  required Map<String, int>? landmassIds,
  required Map<String, String> owners,
  required Map<String, Set<String>> neighbours,
  required Map<String, int> assignedCount,
}) {
  if (factionLandmassIds == null) {
    final sortedFactionIds = factionIds.toList()
      ..sort((a, b) => assignedCount[a]!.compareTo(assignedCount[b]!));
    return sortedFactionIds.first;
  }
  final provinceLandmass = landmassIds?[provinceId];
  var minCount = 999999;
  String? bestFaction;
  for (final fid in factionIds) {
    final allowedLandmass = factionLandmassIds[fid];
    if (allowedLandmass != null && allowedLandmass != provinceLandmass) {
      continue;
    }
    if (!provinceTouchesFaction(provinceId, fid, owners, neighbours)) {
      continue;
    }
    if (assignedCount[fid]! < minCount) {
      minCount = assignedCount[fid]!;
      bestFaction = fid;
    }
  }
  if (bestFaction != null) return bestFaction;
  for (final fid in factionIds) {
    final allowedLandmass = factionLandmassIds[fid];
    if (allowedLandmass != null && allowedLandmass != provinceLandmass) {
      continue;
    }
    if (assignedCount[fid]! < minCount) {
      minCount = assignedCount[fid]!;
      bestFaction = fid;
    }
  }
  if (bestFaction == null) {
    throw StateError(
      'assignTerritoriesByBfsGrowth: no faction can claim province $provinceId '
      'under factionLandmassIds constraints',
    );
  }
  return bestFaction;
}

/// Assigns provinces to factions using fair multi-source BFS growth.
///
/// [neighbours] is the province adjacency graph.
/// [landmassIds] (optional) constrains BFS growth to same-landmass neighbors.
/// [factionLandmassIds] (optional) maps factionId -> allowed landmassId for strict per-faction assignment.
///   When provided, each faction can only claim provinces on their assigned landmass.
/// [factionIds] lists factions to assign to.
/// [seeds] maps provinceId -> factionId for initial seeds.
/// [targetPerFaction] maps factionId -> target province count.
/// [available] is the set of provinces to assign from. Modified in place.
/// [maxTotal] caps the total number of provinces to assign (defaults to [available].length).
/// [neighborShuffleRandom] when non-null shuffles neighbor visit order (deterministic reassignment).
///
/// Returns a map of provinceId -> factionId for all assigned provinces.
Map<String, String> assignTerritoriesByBfsGrowth({
  required Map<String, Set<String>> neighbours,
  Map<String, int>? landmassIds,
  Map<String, int>? factionLandmassIds,
  required List<String> factionIds,
  required Map<String, String> seeds,
  required Map<String, int> targetPerFaction,
  required Set<String> available,
  int? maxTotal,
  Random? neighborShuffleRandom,
}) {
  final owners = <String, String>{};
  final total = maxTotal ?? available.length;

  final queues = <String, Queue<String>>{
    for (final id in factionIds) id: Queue<String>(),
  };
  final assignedCount = <String, int>{for (final id in factionIds) id: 0};
  var totalAssigned = 0;

  for (final entry in seeds.entries) {
    final provinceId = entry.key;
    final factionId = entry.value;
    owners[provinceId] = factionId;
    available.remove(provinceId);
    queues[factionId]!.add(provinceId);
    assignedCount[factionId] = assignedCount[factionId]! + 1;
    totalAssigned++;
  }

  bool anyProgress;
  do {
    anyProgress = _runBfsGrowthRound(
      factionIds: factionIds,
      neighbours: neighbours,
      landmassIds: landmassIds,
      factionLandmassIds: factionLandmassIds,
      targetPerFaction: targetPerFaction,
      queues: queues,
      owners: owners,
      available: available,
      assignedCount: assignedCount,
      total: total,
      neighborShuffleRandom: neighborShuffleRandom,
    );
    totalAssigned = assignedCount.values.fold<int>(0, (a, b) => a + b);
  } while (anyProgress && available.isNotEmpty && totalAssigned < total);

  totalAssigned = _greedyAssignRemainingTerritories(
    available: available,
    owners: owners,
    queues: queues,
    assignedCount: assignedCount,
    factionIds: factionIds,
    neighbours: neighbours,
    landmassIds: landmassIds,
    factionLandmassIds: factionLandmassIds,
    total: total,
    neighborShuffleRandom: neighborShuffleRandom,
    totalAssigned: totalAssigned,
  );

  return owners;
}

/// Computes fair target counts: divides [total] among [count] factions,
/// distributing remainders to earlier factions.
Map<String, int> computeFairTargets(List<String> factionIds, int total) {
  final count = factionIds.length;
  if (count == 0) return {};
  final base = total ~/ count;
  var remainder = total % count;
  return {
    for (var i = 0; i < count; i++)
      factionIds[i]: base + (remainder-- > 0 ? 1 : 0),
  };
}

/// Picks one seed per faction from [candidateIds], consuming from available set.
Map<String, String> pickSimpleSeeds({
  required List<String> factionIds,
  required List<String> candidateIds,
  required Set<String> available,
}) {
  final seeds = <String, String>{};
  for (final factionId in factionIds) {
    if (available.isEmpty) break;
    final seed = candidateIds.firstWhere(
      (p) => available.contains(p),
      orElse: () => '',
    );
    if (seed.isEmpty) break;
    seeds[seed] = factionId;
  }
  return seeds;
}
