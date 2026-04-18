/// Generic BFS territory assignment for province ownership.
/// Used by game_setup to assign Great Powers, Minor Nations, and Tribes.
library;

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

  final queues = <String, List<String>>{
    for (final id in factionIds) id: <String>[],
  };
  final assignedCount = <String, int>{
    for (final id in factionIds) id: 0,
  };
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
    anyProgress = false;

    final order = factionIds.toList()
      ..sort((a, b) => assignedCount[a]!.compareTo(assignedCount[b]!));

    for (final factionId in order) {
      if (assignedCount[factionId]! >= targetPerFaction[factionId]!) continue;
      if (totalAssigned >= total) break;
      final queue = queues[factionId]!;
      var expanded = false;

      while (queue.isNotEmpty && !expanded && totalAssigned < total) {
        final from = queue.removeAt(0);
        final nbrOrder = (neighbours[from] ?? const <String>{}).toList()..sort();
        if (neighborShuffleRandom != null) {
          nbrOrder.shuffle(neighborShuffleRandom);
        }
        for (final nb in nbrOrder) {
          if (!available.contains(nb)) continue;
          // Check landmass constraint (same landmass as neighbor)
          if (landmassIds != null && landmassIds[nb] != landmassIds[from]) {
            continue;
          }
          // Check faction-specific landmass constraint (strict per-faction assignment)
          if (factionLandmassIds != null) {
            final allowedLandmass = factionLandmassIds[factionId];
            if (allowedLandmass != null && landmassIds?[nb] != allowedLandmass) {
              continue;
            }
          }
          owners[nb] = factionId;
          available.remove(nb);
          queue.add(nb);
          assignedCount[factionId] = assignedCount[factionId]! + 1;
          totalAssigned++;
          anyProgress = true;
          expanded = true;
          break;
        }
      }
    }

    if (!anyProgress && available.isNotEmpty && totalAssigned < total) {
      final underTarget = factionIds
          .where((id) => assignedCount[id]! < targetPerFaction[id]!)
          .toList();
      if (underTarget.isNotEmpty) {
        // When factionLandmassIds is provided, only consider provinces on the faction's assigned landmass
        final sorted = available.toList()..sort();
        if (neighborShuffleRandom != null) sorted.shuffle(neighborShuffleRandom);
        for (final factionId in underTarget) {
          if (assignedCount[factionId]! >= targetPerFaction[factionId]!) {
            continue;
          }
          // Find a province on the faction's allowed landmass
          String? seed;
          if (factionLandmassIds != null) {
            final allowedLandmass = factionLandmassIds[factionId];
            if (allowedLandmass != null) {
              for (final p in sorted) {
                if (landmassIds?[p] != allowedLandmass) continue;
                if (provinceTouchesFaction(
                  p,
                  factionId,
                  owners,
                  neighbours,
                )                ) {
                  seed = p;
                  break;
                }
              }
              if (seed == null) {
                for (final p in sorted) {
                  if (landmassIds?[p] == allowedLandmass) {
                    seed = p;
                    break;
                  }
                }
              }
              if (seed == null) {
                throw StateError(
                  'assignTerritoriesByBfsGrowth: faction $factionId has no '
                  'province on landmass $allowedLandmass',
                );
              }
            } else {
              seed = sorted.isNotEmpty ? sorted.first : null;
            }
          } else {
            seed = sorted.isNotEmpty ? sorted.first : null;
          }
          if (sorted.isEmpty || totalAssigned >= total) break;
          if (seed == null) continue;
          if (!available.remove(seed)) continue;
          owners[seed] = factionId;
          queues[factionId]!.add(seed);
          assignedCount[factionId] = assignedCount[factionId]! + 1;
          totalAssigned++;
          anyProgress = true;
        }
      }
    }
  } while (anyProgress && available.isNotEmpty && totalAssigned < total);

  // Greedy leftover: assign remaining to faction with fewest provinces,
  // still respecting the total cap and faction landmass constraints.
  if (available.isNotEmpty && totalAssigned < total) {
    final remaining = available.toList()..sort();
    if (neighborShuffleRandom != null) remaining.shuffle(neighborShuffleRandom);
    while (remaining.isNotEmpty && totalAssigned < total) {
      final provinceId = remaining.removeAt(0);
      if (!available.remove(provinceId)) continue;
      // Find a faction that can legally claim this province (has landmass available)
      String chosenFactionId;
      if (factionLandmassIds != null) {
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
        if (bestFaction == null) {
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
        }
        if (bestFaction == null) {
          throw StateError(
            'assignTerritoriesByBfsGrowth: no faction can claim province $provinceId '
            'under factionLandmassIds constraints',
          );
        }
        chosenFactionId = bestFaction;
      } else {
        final sortedFactionIds = factionIds.toList()
          ..sort((a, b) => assignedCount[a]!.compareTo(assignedCount[b]!));
        chosenFactionId = sortedFactionIds.first;
      }
      final factionId = chosenFactionId;
      owners[provinceId] = factionId;
      queues[factionId]!.add(provinceId);
      assignedCount[factionId] = assignedCount[factionId]! + 1;
      totalAssigned++;
    }
  }

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
