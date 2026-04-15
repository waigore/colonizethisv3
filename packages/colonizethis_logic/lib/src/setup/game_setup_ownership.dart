part of 'game_setup.dart';

Map<String, Set<String>> _provinceNeighboursFromTopology(MapTopology topology) {
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

/// Computes a landmass id (connected component id) per province based on P–P adjacency.
Map<String, int> _landmassIdsFromNeighbours(
  Map<String, Set<String>> neighbours,
) {
  final landmassByProvince = <String, int>{};
  var currentId = 0;
  for (final province in neighbours.keys) {
    if (landmassByProvince.containsKey(province)) continue;
    final queue = <String>[province];
    landmassByProvince[province] = currentId;
    while (queue.isNotEmpty) {
      final p = queue.removeLast();
      for (final n in neighbours[p] ?? const <String>{}) {
        if (landmassByProvince.containsKey(n)) continue;
        landmassByProvince[n] = currentId;
        queue.add(n);
      }
    }
    currentId++;
  }
  return landmassByProvince;
}

Game _assignCapitalsForFactions({
  required Game game,
  required List<String> factionIds,
  required List<Province> provinces,
  required String regionId,
  required MapTopology topology,
  required TileMapResult tileMap,
  required Map<String, TileMapResult> tileMapByRegion,
  required bool requireSeaBound,
  required Game Function(
    Game,
    String,
    String,
    CapitalTile,
    MapTopology,
    Map<String, TileMapResult>,
  )
  setCapitalFn,
}) {
  for (final factionId in factionIds) {
    final owned = provinces
        .where((p) => p.ownerId == factionId)
        .map((p) => p.id)
        .toList();
    if (owned.isEmpty) continue;
    final (provinceId, tile) = pickCapitalForFaction(
      owned,
      regionId,
      topology,
      tileMap,
      requireSeaBound: requireSeaBound,
    );
    game = setCapitalFn(
      game,
      factionId,
      provinceId,
      tile,
      topology,
      tileMapByRegion,
    );
  }
  return game;
}

/// Upper bound on how many OW provinces all Great Powers can own together when each GP
/// is confined to one P–P landmass and each GP needs a sea-bound seed on that landmass.
/// Uses the union of landmasses that receive at least one GP; spreading GPs across
/// separate landmasses maximizes that union (see SPEC/game/game-setup.md).
int _maxFeasibleGpProvinceBudgetOnLandmasses({
  required Map<int, int> landmassSizes,
  required Map<int, int> seaBoundCountByLandmass,
  required int gpCount,
}) {
  final eligible =
      landmassSizes.keys
          .where((lm) => (seaBoundCountByLandmass[lm] ?? 0) >= 1)
          .toList()
        ..sort((a, b) => landmassSizes[b]!.compareTo(landmassSizes[a]!));

  if (eligible.isEmpty) {
    return 0;
  }

  final totalSeaSlots = eligible.fold<int>(
    0,
    (sum, lm) => sum + (seaBoundCountByLandmass[lm] ?? 0),
  );
  if (totalSeaSlots < gpCount) {
    return 0;
  }

  if (gpCount <= eligible.length) {
    return eligible
        .take(gpCount)
        .fold<int>(0, (sum, lm) => sum + landmassSizes[lm]!);
  }

  return eligible.fold<int>(0, (sum, lm) => sum + landmassSizes[lm]!);
}

/// Result of greedy GP→landmass assignment (largest-targets first).
typedef _GpLandmassPackResult = ({
  Map<String, int> gpLandmassAssignments,
  Map<String, int> targetPerGp,
  List<String> sortedGpIds,
});

/// Tries to place each GP on one landmass with sea-cap and per-landmass target sums.
_GpLandmassPackResult? _tryPackGpsOntoLandmassesGreedy({
  required List<String> gpIds,
  required int gpProvinceBudget,
  required Map<int, int> landmassSizes,
  required List<int> sortedLandmasses,
  required Map<int, int> seaBoundCountByLandmass,
}) {
  final targetPerGp = computeFairTargets(gpIds, gpProvinceBudget);
  final gpLandmassAssignments = <String, int>{};
  final targetUsedOnLandmass = <int, int>{
    for (final lm in landmassSizes.keys) lm: 0,
  };
  final gpCountOnLandmass = <int, int>{
    for (final lm in landmassSizes.keys) lm: 0,
  };

  final sortedGpIds = gpIds.toList()
    ..sort((a, b) => targetPerGp[b]!.compareTo(targetPerGp[a]!));

  for (final gpId in sortedGpIds) {
    final target = targetPerGp[gpId]!;
    int? bestLm;
    var bestSlack = 1 << 30;
    for (final lm in sortedLandmasses) {
      final seaCap = seaBoundCountByLandmass[lm] ?? 0;
      if (gpCountOnLandmass[lm]! >= seaCap) continue;
      if (targetUsedOnLandmass[lm]! + target > landmassSizes[lm]!) continue;
      final slack = landmassSizes[lm]! - (targetUsedOnLandmass[lm]! + target);
      if (slack < bestSlack) {
        bestSlack = slack;
        bestLm = lm;
      }
    }
    if (bestLm == null) {
      return null;
    }
    gpLandmassAssignments[gpId] = bestLm;
    targetUsedOnLandmass[bestLm] = targetUsedOnLandmass[bestLm]! + target;
    gpCountOnLandmass[bestLm] = gpCountOnLandmass[bestLm]! + 1;
  }

  return (
    gpLandmassAssignments: gpLandmassAssignments,
    targetPerGp: targetPerGp,
    sortedGpIds: sortedGpIds,
  );
}

/// Largest budget in [gpCount, cap] for which [computeFairTargets] + greedy packing succeeds.
int _largestFeasibleGpProvinceBudgetByPacking({
  required List<String> gpIds,
  required int gpCount,
  required int cap,
  required Map<int, int> landmassSizes,
  required List<int> sortedLandmasses,
  required Map<int, int> seaBoundCountByLandmass,
}) {
  var lo = gpCount;
  var hi = cap;
  var best = gpCount - 1;
  while (lo <= hi) {
    final mid = (lo + hi) ~/ 2;
    final pack = _tryPackGpsOntoLandmassesGreedy(
      gpIds: gpIds,
      gpProvinceBudget: mid,
      landmassSizes: landmassSizes,
      sortedLandmasses: sortedLandmasses,
      seaBoundCountByLandmass: seaBoundCountByLandmass,
    );
    if (pack != null) {
      best = mid;
      lo = mid + 1;
    } else {
      hi = mid - 1;
    }
  }
  return best;
}

Map<String, String> _assignOldWorldOwnershipContiguous({
  required Map<String, Set<String>> neighbours,
  required List<String> provinceIds,
  required List<String> seaBoundProvinceIds,
  required List<String> gpIds,
  required List<String> minorIds,
  required int minProvincesPerMinor,
  Random? assignmentRandom,
}) {
  final landmassIds = _landmassIdsFromNeighbours(neighbours);

  final gpCount = gpIds.length;
  final minorCount = minorIds.length;
  final lockedOwLayout =
      gpCount == 6 &&
      minorCount == 6 &&
      provinceIds.length == 60 &&
      minProvincesPerMinor == 3;

  final totalOw = provinceIds.length;
  final reservedForMinors = minorCount * minProvincesPerMinor;
  final availableForGps = totalOw - reservedForMinors;
  if (availableForGps < gpCount) {
    throw SetupConfigConstraintException(
      code: 'insufficient_old_world_budget_for_great_powers',
      details:
          'Old World has $totalOw provinces but after reserving $reservedForMinors '
          'for $minorCount minors only $availableForGps remain for $gpCount Great Powers',
    );
  }

  // Compute landmass sizes and map landmassId -> list of province IDs
  final landmassToProvinces = <int, List<String>>{};
  for (final pid in provinceIds) {
    final lm = landmassIds[pid]!;
    landmassToProvinces.putIfAbsent(lm, () => <String>[]).add(pid);
  }
  final landmassSizes = landmassToProvinces.map(
    (k, v) => MapEntry(k, v.length),
  );
  final sortedLandmasses = landmassSizes.keys.toList()
    ..sort((a, b) => landmassSizes[b]!.compareTo(landmassSizes[a]!));
  if (lockedOwLayout) {
    final landmassesByRole = sortedLandmasses.toList()
      ..sort((a, b) {
        final sizeCmp = landmassSizes[b]!.compareTo(landmassSizes[a]!);
        if (sizeCmp != 0) return sizeCmp;
        final aMin = (landmassToProvinces[a]!..sort()).first;
        final bMin = (landmassToProvinces[b]!..sort()).first;
        return aMin.compareTo(bMin);
      });
    if (landmassesByRole.length != 4) {
      _log.w(
        'locked OW continent-role assignment skipped; partition is $landmassSizes',
      );
    } else {
      final continentFactions = <int, List<String>>{
        landmassesByRole[0]: [gpIds[0], gpIds[1], minorIds[0]],
        landmassesByRole[1]: [gpIds[2], gpIds[3], minorIds[1]],
        landmassesByRole[2]: [gpIds[4], minorIds[2], minorIds[3]],
        landmassesByRole[3]: [gpIds[5], minorIds[4], minorIds[5]],
      };
      final targetPerFaction = <String, int>{};
      for (final entry in continentFactions.entries) {
        final lm = entry.key;
        final factions = entry.value;
        final fair = computeFairTargets(factions, landmassSizes[lm]!);
        targetPerFaction.addAll(fair);
      }
      final gpLandmassAssignments = <String, int>{
        gpIds[0]: landmassesByRole[0],
        gpIds[1]: landmassesByRole[0],
        gpIds[2]: landmassesByRole[1],
        gpIds[3]: landmassesByRole[1],
        gpIds[4]: landmassesByRole[2],
        gpIds[5]: landmassesByRole[3],
      };
      final targetPerGp = <String, int>{
        for (final gpId in gpIds) gpId: targetPerFaction[gpId]!,
      };
      final gpSeeds = _selectGpSeedsForLandmass(
        gpIdsInAssignmentOrder: gpIds,
        seaBoundProvinceIds: seaBoundProvinceIds,
        landmassIds: landmassIds,
        gpLandmassAssignments: gpLandmassAssignments,
        seedShuffleRandom: assignmentRandom,
      );
      final gpAvailable = provinceIds.toSet();
      final gpOwners = assignTerritoriesByBfsGrowth(
        neighbours: neighbours,
        landmassIds: landmassIds,
        factionLandmassIds: gpLandmassAssignments,
        factionIds: gpIds,
        seeds: gpSeeds,
        targetPerFaction: targetPerGp,
        available: gpAvailable,
        maxTotal: targetPerGp.values.fold<int>(0, (a, b) => a + b),
        neighborShuffleRandom: assignmentRandom,
      );
      final owners = Map<String, String>.from(gpOwners);
      final minorLandmassAssignments = <String, int>{
        minorIds[0]: landmassesByRole[0],
        minorIds[1]: landmassesByRole[1],
        minorIds[2]: landmassesByRole[2],
        minorIds[3]: landmassesByRole[2],
        minorIds[4]: landmassesByRole[3],
        minorIds[5]: landmassesByRole[3],
      };
      final targetPerMinor = <String, int>{
        for (final minorId in minorIds) minorId: targetPerFaction[minorId]!,
      };
      final remainingForMinors = gpAvailable.toList()..sort();
      final minorSeeds = pickSimpleSeeds(
        factionIds: minorIds,
        candidateIds: remainingForMinors.where((provinceId) {
          final lm = landmassIds[provinceId];
          if (lm == null) return false;
          return minorLandmassAssignments.values.contains(lm);
        }).toList(),
        available: gpAvailable,
      );
      final minorOwners = assignTerritoriesByBfsGrowth(
        neighbours: neighbours,
        landmassIds: landmassIds,
        factionLandmassIds: minorLandmassAssignments,
        factionIds: minorIds,
        seeds: minorSeeds,
        targetPerFaction: targetPerMinor,
        available: gpAvailable,
        maxTotal: 18,
        neighborShuffleRandom: assignmentRandom,
      );
      owners.addAll(minorOwners);
      return owners;
    }
  }

  // Sea-bound slots per landmass (each GP needs one sea-bound seed on its landmass).
  final seaBoundCountByLandmass = <int, int>{};
  for (final pid in seaBoundProvinceIds) {
    final lm = landmassIds[pid]!;
    seaBoundCountByLandmass[lm] = (seaBoundCountByLandmass[lm] ?? 0) + 1;
  }

  final maxGpProvincesByTopology = _maxFeasibleGpProvinceBudgetOnLandmasses(
    landmassSizes: landmassSizes,
    seaBoundCountByLandmass: seaBoundCountByLandmass,
    gpCount: gpCount,
  );
  if (maxGpProvincesByTopology < gpCount) {
    throw SetupTopologyDataException(
      code: 'old_world_gp_assignment_infeasible',
      details:
          'Old World GP assignment infeasible: topology allows at most '
          '$maxGpProvincesByTopology province(s) for $gpCount Great Power(s) under the '
          'one-landmass-per-GP rule (sea-bound slots per landmass: $seaBoundCountByLandmass)',
    );
  }

  final cap = min(availableForGps, maxGpProvincesByTopology);
  // Fair targets must pack into landmasses: sum of targets per landmass ≤ |L|, and
  // (# GPs on L) ≤ sea-bound slots on L. Union-only caps are insufficient when
  // gpCount > landmassCount (e.g. three GPs on two continents).
  final gpProvinceBudget = _largestFeasibleGpProvinceBudgetByPacking(
    gpIds: gpIds,
    gpCount: gpCount,
    cap: cap,
    landmassSizes: landmassSizes,
    sortedLandmasses: sortedLandmasses,
    seaBoundCountByLandmass: seaBoundCountByLandmass,
  );
  if (gpProvinceBudget < gpCount) {
    throw SetupTopologyDataException(
      code: 'old_world_gp_landmass_packing_failed',
      details:
          'Old World GP landmass packing failed: no feasible fair target budget for '
          '$gpCount Great Power(s) within cap $cap. Landmass sizes: $landmassSizes, '
          'sea-bound per landmass: $seaBoundCountByLandmass',
    );
  }

  final pack = _tryPackGpsOntoLandmassesGreedy(
    gpIds: gpIds,
    gpProvinceBudget: gpProvinceBudget,
    landmassSizes: landmassSizes,
    sortedLandmasses: sortedLandmasses,
    seaBoundCountByLandmass: seaBoundCountByLandmass,
  );
  if (pack == null) {
    throw StateError(
      'GP landmass pack unexpectedly null at budget $gpProvinceBudget',
    );
  }
  final gpLandmassAssignments = pack.gpLandmassAssignments;
  final targetPerGp = pack.targetPerGp;
  final sortedGpIds = pack.sortedGpIds;

  // Seed selection for Great Powers: one sea-bound province per GP, from their assigned landmass
  final gpSeeds = _selectGpSeedsForLandmass(
    gpIdsInAssignmentOrder: sortedGpIds,
    seaBoundProvinceIds: seaBoundProvinceIds,
    landmassIds: landmassIds,
    gpLandmassAssignments: gpLandmassAssignments,
    seedShuffleRandom: assignmentRandom,
  );

  final gpAvailable = provinceIds.toSet();

  // Pass faction landmass constraints to BFS for strict per-landmass assignment
  final gpOwners = assignTerritoriesByBfsGrowth(
    neighbours: neighbours,
    landmassIds: landmassIds,
    factionLandmassIds: gpLandmassAssignments,
    factionIds: gpIds,
    seeds: gpSeeds,
    targetPerFaction: targetPerGp,
    available: gpAvailable,
    maxTotal: gpProvinceBudget,
    neighborShuffleRandom: assignmentRandom,
  );

  for (final gpId in gpIds) {
    final expectedLm = gpLandmassAssignments[gpId];
    if (expectedLm == null) continue;
    for (final e in gpOwners.entries) {
      if (e.value != gpId) continue;
      final pidLm = landmassIds[e.key];
      if (pidLm != expectedLm) {
        throw StateError(
          'GP $gpId violates one-continent rule: province ${e.key} is on '
          'landmass $pidLm but GP is assigned to $expectedLm',
        );
      }
    }
  }

  // Remaining provinces go to minors.
  final owners = Map<String, String>.from(gpOwners);
  if (minorCount > 0 && gpAvailable.isNotEmpty) {
    final remainingForMinors = gpAvailable.toList()..sort();
    if (assignmentRandom != null) remainingForMinors.shuffle(assignmentRandom);
    final targetPerMinor = computeFairTargets(
      minorIds,
      remainingForMinors.length,
    );
    final minorSeeds = pickSimpleSeeds(
      factionIds: minorIds,
      candidateIds: remainingForMinors,
      available: gpAvailable,
    );
    final minorOwners = assignTerritoriesByBfsGrowth(
      neighbours: neighbours,
      landmassIds: landmassIds,
      factionIds: minorIds,
      seeds: minorSeeds,
      targetPerFaction: targetPerMinor,
      available: gpAvailable,
      neighborShuffleRandom: assignmentRandom,
    );
    owners.addAll(minorOwners);
  }

  return owners;
}

/// Selects GP seeds: one sea-bound province per GP, from their assigned landmass.
/// [gpIdsInAssignmentOrder] must match the order used when building [gpLandmassAssignments]
/// so sea-bound consumption is deterministic.
Map<String, String> _selectGpSeedsForLandmass({
  required List<String> gpIdsInAssignmentOrder,
  required List<String> seaBoundProvinceIds,
  required Map<String, int> landmassIds,
  required Map<String, int> gpLandmassAssignments,
  Random? seedShuffleRandom,
}) {
  final gpCount = gpIdsInAssignmentOrder.length;

  // Group sea-bound provinces by landmass (sorted lists; we remove from front).
  final seaBoundByLandmass = <int, List<String>>{};
  for (final pid in seaBoundProvinceIds) {
    final lm = landmassIds[pid]!;
    seaBoundByLandmass.putIfAbsent(lm, () => <String>[]).add(pid);
  }
  for (final list in seaBoundByLandmass.values) {
    list.sort();
    if (seedShuffleRandom != null) list.shuffle(seedShuffleRandom);
  }

  final gpSeeds = <String, String>{};

  for (final gpId in gpIdsInAssignmentOrder) {
    final assignedLandmass = gpLandmassAssignments[gpId];
    if (assignedLandmass == null) {
      throw SetupTopologyDataException(
        code: 'missing_gp_landmass_assignment',
        details:
            'Great Power $gpId has no landmass assignment; cannot pick sea-bound seed',
      );
    }
    final seaBoundOnLandmass = seaBoundByLandmass[assignedLandmass];
    if (seaBoundOnLandmass == null || seaBoundOnLandmass.isEmpty) {
      throw NoSeaBoundCapitalProvinceException(
        details:
            'No sea-bound province left on landmass $assignedLandmass for Great Power $gpId',
      );
    }
    final seedProv = seaBoundOnLandmass.removeAt(0);
    gpSeeds[seedProv] = gpId;
  }

  if (gpSeeds.length != gpCount) {
    throw NoSeaBoundCapitalProvinceException(
      details:
          'Not enough sea-bound provinces to seed all Great Powers on their landmasses: '
          'have ${gpSeeds.length}, need $gpCount',
    );
  }

  return gpSeeds;
}

Map<String, String> _assignNewWorldOwnershipContiguous({
  required MapTopology topologyNewWorld,
  required List<String> provinceIds,
  required List<String> tribeIds,
}) {
  if (tribeIds.isEmpty) {
    return {for (final p in provinceIds) p: ''};
  }

  final neighbours = _provinceNeighboursFromTopology(topologyNewWorld);
  final sorted = provinceIds.toList()..sort();
  final available = provinceIds.toSet();
  final targetPerTribe = computeFairTargets(tribeIds, provinceIds.length);
  final seeds = pickSimpleSeeds(
    factionIds: tribeIds,
    candidateIds: sorted,
    available: available,
  );

  return assignTerritoriesByBfsGrowth(
    neighbours: neighbours,
    factionIds: tribeIds,
    seeds: seeds,
    targetPerFaction: targetPerTribe,
    available: available,
  );
}
