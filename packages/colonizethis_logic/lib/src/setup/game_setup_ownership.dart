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

/// Exact locked-role OW ownership (pairing search); null if no layout works.
Map<String, String>? _tryLockedOldWorldExactOwnershipPairings({
  required Map<String, Set<String>> neighbours,
  required List<int> landmassesByRole,
  required Map<int, List<String>> landmassToProvinces,
  required List<String> seaBoundProvinceIds,
  required List<String> gpIds,
  required List<String> minorIds,
  required int gpTarget,
  required int minorTarget,
}) {
  final seaBoundGlobal = seaBoundProvinceIds.toSet();
  final lm17Slot0 = landmassesByRole[0];
  final lm17Slot1 = landmassesByRole[1];
  Map<String, String>? tryLockedLayout({
    required List<(int, int)> seventeenPairing,
    required bool flipSeventeenPairs,
    required bool swap13Pair,
  }) {
    final lm13First = swap13Pair
        ? landmassesByRole[3]
        : landmassesByRole[2];
    final lm13Second = swap13Pair
        ? landmassesByRole[2]
        : landmassesByRole[3];
    final firstPair = flipSeventeenPairs
        ? seventeenPairing[1]
        : seventeenPairing[0];
    final secondPair = flipSeventeenPairs
        ? seventeenPairing[0]
        : seventeenPairing[1];
    final gpLandmassAssignments = <String, int>{
      gpIds[firstPair.$1]: lm17Slot0,
      gpIds[firstPair.$2]: lm17Slot0,
      gpIds[secondPair.$1]: lm17Slot1,
      gpIds[secondPair.$2]: lm17Slot1,
      gpIds[4]: lm13First,
      gpIds[5]: lm13Second,
    };
    final minorLandmassAssignments = <String, int>{
      minorIds[0]: lm17Slot0,
      minorIds[1]: lm17Slot1,
      minorIds[2]: lm13First,
      minorIds[3]: lm13First,
      minorIds[4]: lm13Second,
      minorIds[5]: lm13Second,
    };
    final owners = <String, String>{};
    for (final landmassId in landmassesByRole) {
      final factionIdsForLandmass =
          <String>[
            ...gpLandmassAssignments.entries
                .where((entry) => entry.value == landmassId)
                .map((entry) => entry.key),
            ...minorLandmassAssignments.entries
                .where((entry) => entry.value == landmassId)
                .map((entry) => entry.key),
          ]..sort((a, b) {
            final ta = a.startsWith('gp') ? gpTarget : minorTarget;
            final tb = b.startsWith('gp') ? gpTarget : minorTarget;
            final cmp = tb.compareTo(ta);
            if (cmp != 0) return cmp;
            return a.compareTo(b);
          });
      final targetPerFaction = <String, int>{
        for (final fid in factionIdsForLandmass)
          fid: fid.startsWith('gp') ? gpTarget : minorTarget,
      };
      final landProvinces = List<String>.from(
        landmassToProvinces[landmassId]!,
      )..sort();
      final seaBoundHere = landProvinces.where(seaBoundGlobal.contains).toSet();
      final mustIncludeSeaBoundFor = <String, Set<String>>{
        for (final fid in factionIdsForLandmass.where(
          (id) => id.startsWith('gp'),
        ))
          fid: seaBoundHere,
      };
      final landmassOwners = _assignExactLandmassTryFactionOrders(
        allNeighbours: neighbours,
        landmassProvinceIds: landProvinces,
        baseFactionOrderDesc: factionIdsForLandmass,
        targetPerFaction: targetPerFaction,
        mustIncludeAnyOfByFaction: mustIncludeSeaBoundFor,
      );
      if (landmassOwners == null) {
        return null;
      }
      owners.addAll(landmassOwners);
    }
    return owners;
  }

  const seventeenPairings = <List<(int, int)>>[
    [(0, 1), (2, 3)],
    [(0, 2), (1, 3)],
    [(0, 3), (1, 2)],
  ];
  for (final pairing in seventeenPairings) {
    for (var flip17 = 0; flip17 < 2; flip17++) {
      for (final swap13 in <bool>[false, true]) {
        final attempt = tryLockedLayout(
          seventeenPairing: pairing,
          flipSeventeenPairs: flip17 == 1,
          swap13Pair: swap13,
        );
        if (attempt != null) {
          return attempt;
        }
      }
    }
  }
  return null;
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
      const gpTarget = 7;
      const minorTarget = 3;
      final requiredByLandmass = <int, int>{
        landmassesByRole[0]: gpTarget + gpTarget + minorTarget, // 17
        landmassesByRole[1]: gpTarget + gpTarget + minorTarget, // 17
        landmassesByRole[2]: gpTarget + minorTarget + minorTarget, // 13
        landmassesByRole[3]: gpTarget + minorTarget + minorTarget, // 13
      };
      for (final entry in requiredByLandmass.entries) {
        final actual = landmassSizes[entry.key] ?? 0;
        if (actual < entry.value) {
          throw SetupTopologyDataException(
            code: 'locked_ow_role_split_infeasible',
            details:
                'Landmass ${entry.key} has $actual provinces but role split needs '
                '${entry.value} for hard quotas (GP=7, minor=3).',
          );
        }
      }
      final lockedOwners = _tryLockedOldWorldExactOwnershipPairings(
        neighbours: neighbours,
        landmassesByRole: landmassesByRole,
        landmassToProvinces: landmassToProvinces,
        seaBoundProvinceIds: seaBoundProvinceIds,
        gpIds: gpIds,
        minorIds: minorIds,
        gpTarget: gpTarget,
        minorTarget: minorTarget,
      );
      if (lockedOwners == null) {
        throw StateError(
          'locked OW assignment could not satisfy contiguous ownership '
          'for any GP pairing, 13-landmass swap, or same-target faction order',
        );
      }
      return lockedOwners;
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
  Random? assignmentRandom,
}) {
  if (tribeIds.isEmpty) {
    return {for (final p in provinceIds) p: ''};
  }

  final neighbours = _provinceNeighboursFromTopology(topologyNewWorld);
  final landmassIds = _landmassIdsFromNeighbours(neighbours);
  final sorted = provinceIds.toList()..sort();
  final candidateIds = List<String>.from(sorted);
  if (assignmentRandom != null) {
    candidateIds.shuffle(assignmentRandom);
  }
  final factionOrder = List<String>.from(tribeIds);
  if (assignmentRandom != null) {
    factionOrder.shuffle(assignmentRandom);
  }
  final available = provinceIds.toSet();
  final lockedNwLayout = tribeIds.length == 10 && provinceIds.length == 30;
  if (lockedNwLayout) {
    final provincesByLandmass = <int, List<String>>{};
    for (final provinceId in provinceIds) {
      final landmassId = landmassIds[provinceId];
      if (landmassId == null) continue;
      provincesByLandmass
          .putIfAbsent(landmassId, () => <String>[])
          .add(provinceId);
    }
    final sortedLandmasses = provincesByLandmass.keys.toList()
      ..sort((a, b) {
        final sizeCmp = provincesByLandmass[b]!.length.compareTo(
          provincesByLandmass[a]!.length,
        );
        if (sizeCmp != 0) return sizeCmp;
        final aMin = (provincesByLandmass[a]!..sort()).first;
        final bMin = (provincesByLandmass[b]!..sort()).first;
        return aMin.compareTo(bMin);
      });
    if (sortedLandmasses.length != 4) {
      throw SetupTopologyDataException(
        code: 'locked_nw_role_split_infeasible',
        details:
            'Expected 4 New World landmasses, got ${sortedLandmasses.length}.',
      );
    }
    final requiredByLandmass = <int, int>{
      sortedLandmasses[0]: 9,
      sortedLandmasses[1]: 9,
      sortedLandmasses[2]: 6,
      sortedLandmasses[3]: 6,
    };
    for (final entry in requiredByLandmass.entries) {
      final actual = provincesByLandmass[entry.key]?.length ?? 0;
      if (actual != entry.value) {
        throw SetupTopologyDataException(
          code: 'locked_nw_partition_mismatch',
          details:
              'Landmass ${entry.key} has $actual provinces but locked profile requires ${entry.value}.',
        );
      }
    }
    final tribeLandmassAssignments = <String, int>{
      tribeIds[0]: sortedLandmasses[0],
      tribeIds[1]: sortedLandmasses[0],
      tribeIds[2]: sortedLandmasses[0],
      tribeIds[3]: sortedLandmasses[1],
      tribeIds[4]: sortedLandmasses[1],
      tribeIds[5]: sortedLandmasses[1],
      tribeIds[6]: sortedLandmasses[2],
      tribeIds[7]: sortedLandmasses[2],
      tribeIds[8]: sortedLandmasses[3],
      tribeIds[9]: sortedLandmasses[3],
    };
    final owners = <String, String>{};
    for (final landmassId in sortedLandmasses) {
      final tribeIdsForLandmass =
          tribeLandmassAssignments.entries
              .where((entry) => entry.value == landmassId)
              .map((entry) => entry.key)
              .toList()
            ..sort();
      final targetPerFaction = <String, int>{
        for (final tribeId in tribeIdsForLandmass) tribeId: 3,
      };
      final landProvinces = List<String>.from(
        provincesByLandmass[landmassId]!,
      )..sort();
      final landmassOwners = _assignExactLandmassTryFactionOrders(
        allNeighbours: neighbours,
        landmassProvinceIds: landProvinces,
        baseFactionOrderDesc: tribeIdsForLandmass,
        targetPerFaction: targetPerFaction,
      );
      if (landmassOwners == null) {
        throw StateError(
          'locked NW assignment could not satisfy contiguous ownership '
          'on landmass $landmassId',
        );
      }
      owners.addAll(landmassOwners);
    }
    return owners;
  }

  final targetPerTribe = computeFairTargets(tribeIds, provinceIds.length);
  final seeds = pickLandmassSpacedSeeds(
    factionIds: tribeIds,
    candidateIds: candidateIds,
    available: available,
    landmassIds: landmassIds,
  );
  return assignTerritoriesByBfsGrowth(
    neighbours: neighbours,
    landmassIds: landmassIds,
    lockBfsExpansionToLandmass: false,
    factionIds: factionOrder,
    seeds: seeds,
    targetPerFaction: targetPerTribe,
    available: available,
    neighborShuffleRandom: assignmentRandom,
  );
}

/// All permutations of [ids] (length ≤ 6 in this codebase).
List<List<String>> _permutationsOf(List<String> ids) {
  if (ids.isEmpty) {
    return [const <String>[]];
  }
  if (ids.length == 1) {
    return [ids.toList()];
  }
  final out = <List<String>>[];
  for (var i = 0; i < ids.length; i++) {
    final head = ids[i];
    final rest = List<String>.from(ids)..removeAt(i);
    for (final tail in _permutationsOf(rest)) {
      out.add([head, ...tail]);
    }
  }
  return out;
}

/// [baseOrderDesc] is non-increasing by [targetPerFaction]; yields every
/// order that only permutes within equal-target runs (SPEC: within-continent
/// tie-break; geometry may require trying those permutations).
Iterable<List<String>> _permutationsPreservingTargetOrder(
  List<String> baseOrderDesc,
  Map<String, int> targetPerFaction,
) sync* {
  if (baseOrderDesc.isEmpty) {
    yield const [];
    return;
  }
  final bands = <List<String>>[];
  for (final id in baseOrderDesc) {
    if (bands.isEmpty) {
      bands.add([id]);
      continue;
    }
    final prevTarget = targetPerFaction[bands.last.first] ?? 0;
    final curTarget = targetPerFaction[id] ?? 0;
    if (prevTarget == curTarget) {
      bands.last.add(id);
    } else {
      bands.add([id]);
    }
  }
  Iterable<List<String>> combine(int bi, List<String> prefix) sync* {
    if (bi >= bands.length) {
      yield prefix;
      return;
    }
    for (final perm in _permutationsOf(bands[bi])) {
      yield* combine(bi + 1, [...prefix, ...perm]);
    }
  }

  yield* combine(0, []);
}

bool _listIdenticalStrings(List<String> a, List<String> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

Map<String, String>? _assignExactLandmassTryFactionOrders({
  required Map<String, Set<String>> allNeighbours,
  required List<String> landmassProvinceIds,
  required List<String> baseFactionOrderDesc,
  required Map<String, int> targetPerFaction,
  Map<String, Set<String>> mustIncludeAnyOfByFaction = const {},
}) {
  final direct = _assignExactConnectedOwnershipForLandmass(
    allNeighbours: allNeighbours,
    landmassProvinceIds: landmassProvinceIds,
    orderedFactionIds: baseFactionOrderDesc,
    targetPerFaction: targetPerFaction,
    mustIncludeAnyOfByFaction: mustIncludeAnyOfByFaction,
  );
  if (direct != null) {
    return direct;
  }
  for (final order in _permutationsPreservingTargetOrder(
    baseFactionOrderDesc,
    targetPerFaction,
  )) {
    if (_listIdenticalStrings(order, baseFactionOrderDesc)) {
      continue;
    }
    final r = _assignExactConnectedOwnershipForLandmass(
      allNeighbours: allNeighbours,
      landmassProvinceIds: landmassProvinceIds,
      orderedFactionIds: order,
      targetPerFaction: targetPerFaction,
      mustIncludeAnyOfByFaction: mustIncludeAnyOfByFaction,
    );
    if (r != null) {
      return r;
    }
  }
  return null;
}

Map<String, String>? _assignExactConnectedOwnershipForLandmass({
  required Map<String, Set<String>> allNeighbours,
  required List<String> landmassProvinceIds,
  required List<String> orderedFactionIds,
  required Map<String, int> targetPerFaction,
  Map<String, Set<String>> mustIncludeAnyOfByFaction = const {},
}) {
  final available = {...landmassProvinceIds};
  final memo = <String, Map<String, String>?>{};
  return _assignExactConnectedOwnershipRecursive(
    allNeighbours: allNeighbours,
    available: available,
    orderedFactionIds: orderedFactionIds,
    targetPerFaction: targetPerFaction,
    mustIncludeAnyOfByFaction: mustIncludeAnyOfByFaction,
    index: 0,
    memo: memo,
  );
}

String _exactOwnershipMemoKey(int index, Set<String> available) {
  final sorted = available.toList()..sort();
  return '$index|${sorted.join(':')}';
}

Map<String, String>? _assignExactConnectedOwnershipRecursive({
  required Map<String, Set<String>> allNeighbours,
  required Set<String> available,
  required List<String> orderedFactionIds,
  required Map<String, int> targetPerFaction,
  required Map<String, Set<String>> mustIncludeAnyOfByFaction,
  required int index,
  required Map<String, Map<String, String>?> memo,
}) {
  if (index >= orderedFactionIds.length) {
    return available.isEmpty ? <String, String>{} : null;
  }
  final factionId = orderedFactionIds[index];
  final target = targetPerFaction[factionId] ?? 0;
  if (target <= 0) {
    return _assignExactConnectedOwnershipRecursive(
      allNeighbours: allNeighbours,
      available: available,
      orderedFactionIds: orderedFactionIds,
      targetPerFaction: targetPerFaction,
      mustIncludeAnyOfByFaction: mustIncludeAnyOfByFaction,
      index: index + 1,
      memo: memo,
    );
  }
  if (target > available.length) {
    return null;
  }
  final memoKey = _exactOwnershipMemoKey(index, available);
  if (memo.containsKey(memoKey)) {
    final cached = memo[memoKey];
    if (cached == null) {
      return null;
    }
    return Map<String, String>.from(cached);
  }
  final mustInclude = mustIncludeAnyOfByFaction[factionId] ?? const <String>{};
  final subsets = _connectedSubsetsOfSize(
    available: available,
    neighbours: allNeighbours,
    targetSize: target,
    mustIncludeAnyOf: mustInclude,
  );
  final subsetList = subsets.toList();
  if (mustInclude.isNotEmpty) {
    int subsetScore(Set<String> s) {
      var score = 0;
      for (final p in s) {
        if (mustInclude.contains(p)) {
          score += 10000;
        }
        score += allNeighbours[p]?.length ?? 0;
      }
      return score;
    }

    subsetList.sort((a, b) => subsetScore(b).compareTo(subsetScore(a)));
  }
  final remainingTarget = orderedFactionIds
      .skip(index + 1)
      .fold<int>(0, (sum, id) => sum + (targetPerFaction[id] ?? 0));
  for (final subset in subsetList) {
    final remaining = <String>{...available}..removeAll(subset);
    if (remaining.length < remainingTarget) {
      continue;
    }
    final next = _assignExactConnectedOwnershipRecursive(
      allNeighbours: allNeighbours,
      available: remaining,
      orderedFactionIds: orderedFactionIds,
      targetPerFaction: targetPerFaction,
      mustIncludeAnyOfByFaction: mustIncludeAnyOfByFaction,
      index: index + 1,
      memo: memo,
    );
    if (next == null) continue;
    final merged = Map<String, String>.from(next);
    for (final provinceId in subset) {
      merged[provinceId] = factionId;
    }
    memo[memoKey] = merged;
    return merged;
  }
  memo[memoKey] = null;
  return null;
}

/// Caps worst-case enumeration on large landmasses (keeps CI / AC-13 runtime bounded).
const int _kMaxConnectedSubsetResultsLargeLandmass = 8192;

List<Set<String>> _connectedSubsetsOfSize({
  required Set<String> available,
  required Map<String, Set<String>> neighbours,
  required int targetSize,
  Set<String> mustIncludeAnyOf = const <String>{},
  int? maxResults,
}) {
  final effectiveMax = maxResults ??
      (available.length <= 12 ? 65536 : _kMaxConnectedSubsetResultsLargeLandmass);
  final availableSorted = available.toList()
    ..sort((a, b) {
      final da = neighbours[a]?.length ?? 0;
      final db = neighbours[b]?.length ?? 0;
      final c = db.compareTo(da);
      if (c != 0) {
        return c;
      }
      return a.compareTo(b);
    });
  final out = <Set<String>>[];
  for (final root in availableSorted) {
    if (out.length >= effectiveMax) {
      break;
    }
    final initial = <String>{root};
    final frontier = <String>{
      for (final n in neighbours[root] ?? const <String>{})
        if (available.contains(n)) n,
    };
    _expandConnectedSubset(
      available: available,
      neighbours: neighbours,
      targetSize: targetSize,
      current: initial,
      frontier: frontier,
      root: root,
      mustIncludeAnyOf: mustIncludeAnyOf,
      out: out,
      maxResults: effectiveMax,
    );
  }
  return out;
}

void _expandConnectedSubset({
  required Set<String> available,
  required Map<String, Set<String>> neighbours,
  required int targetSize,
  required Set<String> current,
  required Set<String> frontier,
  required String root,
  required Set<String> mustIncludeAnyOf,
  required List<Set<String>> out,
  required int maxResults,
}) {
  if (out.length >= maxResults) {
    return;
  }
  if (current.length == targetSize) {
    if (mustIncludeAnyOf.isEmpty || current.any(mustIncludeAnyOf.contains)) {
      if (out.length < maxResults) {
        out.add({...current});
      }
    }
    return;
  }
  if (current.length + frontier.length < targetSize) {
    return;
  }
  final frontierSorted = frontier.toList()..sort();
  for (final next in frontierSorted) {
    if (out.length >= maxResults) {
      return;
    }
    if (next.compareTo(root) < 0) continue;
    final nextCurrent = <String>{...current, next};
    final nextFrontier = <String>{...frontier}..remove(next);
    for (final n in neighbours[next] ?? const <String>{}) {
      if (!available.contains(n) || nextCurrent.contains(n)) continue;
      if (n.compareTo(root) < 0) continue;
      nextFrontier.add(n);
    }
    _expandConnectedSubset(
      available: available,
      neighbours: neighbours,
      targetSize: targetSize,
      current: nextCurrent,
      frontier: nextFrontier,
      root: root,
      mustIncludeAnyOf: mustIncludeAnyOf,
      out: out,
      maxResults: maxResults,
    );
  }
}
