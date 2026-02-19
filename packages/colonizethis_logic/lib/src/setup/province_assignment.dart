/// Generic BFS territory assignment for province ownership.
/// Used by game_setup to assign Great Powers, Minor Nations, and Tribes.

/// Assigns provinces to factions using fair multi-source BFS growth.
///
/// [neighbours] is the province adjacency graph.
/// [landmassIds] (optional) constrains BFS growth to same-landmass neighbors.
/// [factionIds] lists factions to assign to.
/// [seeds] maps provinceId -> factionId for initial seeds.
/// [targetPerFaction] maps factionId -> target province count.
/// [available] is the set of provinces to assign from. Modified in place.
/// [maxTotal] caps the total number of provinces to assign (defaults to [available].length).
///
/// Returns a map of provinceId -> factionId for all assigned provinces.
Map<String, String> assignTerritoriesByBfsGrowth({
  required Map<String, Set<String>> neighbours,
  Map<String, int>? landmassIds,
  required List<String> factionIds,
  required Map<String, String> seeds,
  required Map<String, int> targetPerFaction,
  required Set<String> available,
  int? maxTotal,
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
        for (final nb in neighbours[from] ?? const <String>{}) {
          if (!available.contains(nb)) continue;
          if (landmassIds != null && landmassIds[nb] != landmassIds[from]) {
            continue;
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
        final sorted = available.toList()..sort();
        for (final factionId in underTarget) {
          if (assignedCount[factionId]! >= targetPerFaction[factionId]!) {
            continue;
          }
          if (sorted.isEmpty || totalAssigned >= total) break;
          final seed = sorted.removeAt(0);
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
  // still respecting the total cap.
  if (available.isNotEmpty && totalAssigned < total) {
    final remaining = available.toList()..sort();
    while (remaining.isNotEmpty && totalAssigned < total) {
      final provinceId = remaining.removeAt(0);
      if (!available.remove(provinceId)) continue;
      factionIds.sort(
          (a, b) => assignedCount[a]!.compareTo(assignedCount[b]!));
      final factionId = factionIds.first;
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
