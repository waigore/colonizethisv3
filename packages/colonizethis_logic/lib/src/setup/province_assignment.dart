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
/// [landmassIds] (optional) supplies P–P landmass ids per province for secondary
/// seeding, greedy leftover, and (when [lockBfsExpansionToLandmass] is true)
/// same-landmass neighbor filtering during BFS expansion.
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
  bool lockBfsExpansionToLandmass = true,
  bool requireContiguousWhenConstrained = false,
  bool strictSingleSeedGrowth = false,
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
        final nbrOrder = (neighbours[from] ?? const <String>{}).toList()
          ..sort();
        if (neighborShuffleRandom != null) {
          nbrOrder.shuffle(neighborShuffleRandom);
        }
        for (final nb in nbrOrder) {
          if (!available.contains(nb)) continue;
          // Optional: same-landmass as frontier (redundant for true P–P graphs).
          if (lockBfsExpansionToLandmass &&
              landmassIds != null &&
              landmassIds[nb] != landmassIds[from]) {
            continue;
          }
          // Check faction-specific landmass constraint (strict per-faction assignment)
          if (factionLandmassIds != null) {
            final allowedLandmass = factionLandmassIds[factionId];
            if (allowedLandmass != null &&
                landmassIds?[nb] != allowedLandmass) {
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

    if (!strictSingleSeedGrowth &&
        !anyProgress &&
        available.isNotEmpty &&
        totalAssigned < total) {
      final underTarget = factionIds
          .where((id) => assignedCount[id]! < targetPerFaction[id]!)
          .toList();
      if (underTarget.isNotEmpty) {
        // When factionLandmassIds is provided, only consider provinces on the faction's assigned landmass
        final sorted = available.toList()..sort();
        if (neighborShuffleRandom != null)
          sorted.shuffle(neighborShuffleRandom);
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
                if (provinceTouchesFaction(p, factionId, owners, neighbours)) {
                  seed = p;
                  break;
                }
              }
              if (seed == null) {
                if (requireContiguousWhenConstrained) {
                  throw StateError(
                    'assignTerritoriesByBfsGrowth: faction $factionId cannot grow '
                    'contiguously on landmass $allowedLandmass',
                  );
                }
                for (final p in sorted) {
                  if (landmassIds?[p] == allowedLandmass) {
                    seed = p;
                    break;
                  }
                }
              }
            } else {
              seed = sorted.isNotEmpty ? sorted.first : null;
            }
          } else if (landmassIds != null) {
            // Keep secondary seeds on the same P–P landmass as this faction's
            // existing provinces so one faction cannot sprawl onto a second
            // disconnected landmass (same-landmass swap repair cannot merge that).
            int? factionLm;
            for (final e in owners.entries) {
              if (e.value != factionId) continue;
              factionLm = landmassIds[e.key];
              break;
            }
            if (factionLm != null) {
              for (final p in sorted) {
                if (landmassIds[p] != factionLm) continue;
                if (provinceTouchesFaction(p, factionId, owners, neighbours)) {
                  seed = p;
                  break;
                }
              }
              if (seed == null) {
                for (final p in sorted) {
                  if (landmassIds[p] == factionLm) {
                    seed = p;
                    break;
                  }
                }
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
  if (!strictSingleSeedGrowth &&
      available.isNotEmpty &&
      totalAssigned < total) {
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
          if (requireContiguousWhenConstrained) {
            throw StateError(
              'assignTerritoriesByBfsGrowth: no contiguous claimant for $provinceId '
              'under factionLandmassIds constraints',
            );
          }
          for (final fid in factionIds) {
            final allowedLandmass = factionLandmassIds[fid];
            if (allowedLandmass != null &&
                allowedLandmass != provinceLandmass) {
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
        }
        chosenFactionId = bestFaction;
      } else if (landmassIds != null) {
        var minCount = 999999999;
        String? bestFaction;
        for (final fid in factionIds) {
          if (!provinceTouchesFaction(provinceId, fid, owners, neighbours)) {
            continue;
          }
          if (assignedCount[fid]! < minCount) {
            minCount = assignedCount[fid]!;
            bestFaction = fid;
          }
        }
        if (bestFaction == null) {
          // Neighbors may still be unassigned in this greedy pass; prefer a
          // faction that already owns on this province's P–P landmass.
          final plm = landmassIds[provinceId]!;
          minCount = 999999999;
          for (final fid in factionIds) {
            var ownsOnLm = false;
            for (final e in owners.entries) {
              if (e.value != fid) continue;
              if (landmassIds[e.key] == plm) {
                ownsOnLm = true;
                break;
              }
            }
            if (!ownsOnLm) continue;
            if (assignedCount[fid]! < minCount) {
              minCount = assignedCount[fid]!;
              bestFaction = fid;
            }
          }
        }
        if (bestFaction == null) {
          final sortedFactionIds = factionIds.toList()
            ..sort((a, b) => assignedCount[a]!.compareTo(assignedCount[b]!));
          bestFaction = sortedFactionIds.first;
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

/// Like [pickSimpleSeeds], but prefers provinces on P–P landmasses not yet used
/// by a seed so disjoint landmasses each receive growth early (New World tribes).
Map<String, String> pickLandmassSpacedSeeds({
  required List<String> factionIds,
  required List<String> candidateIds,
  required Set<String> available,
  required Map<String, int> landmassIds,
}) {
  final seeds = <String, String>{};
  final usedLandmasses = <int>{};
  for (final factionId in factionIds) {
    if (available.isEmpty) break;
    final seed =
        _firstAvailableOnUnusedLandmass(
          candidateIds: candidateIds,
          available: available,
          landmassIds: landmassIds,
          usedLandmasses: usedLandmasses,
        ) ??
        _firstAvailableCandidate(candidateIds, available);
    if (seed == null) break;
    seeds[seed] = factionId;
    available.remove(seed);
  }
  return seeds;
}

String? _firstAvailableOnUnusedLandmass({
  required List<String> candidateIds,
  required Set<String> available,
  required Map<String, int> landmassIds,
  required Set<int> usedLandmasses,
}) {
  for (final p in candidateIds) {
    if (!available.contains(p)) continue;
    final lm = landmassIds[p];
    if (lm == null || usedLandmasses.contains(lm)) continue;
    usedLandmasses.add(lm);
    return p;
  }
  return null;
}

String? _firstAvailableCandidate(
  List<String> candidateIds,
  Set<String> available,
) {
  for (final p in candidateIds) {
    if (available.contains(p)) return p;
  }
  return null;
}
