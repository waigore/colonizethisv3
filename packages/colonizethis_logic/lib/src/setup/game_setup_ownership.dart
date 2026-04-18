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

void _pushSubsetNeighbors(
  String u,
  Set<String> nodes,
  Set<String> unseen,
  Map<String, Set<String>> neighbours,
  List<String> stack,
) {
  for (final v in neighbours[u] ?? const <String>{}) {
    if (!nodes.contains(v)) continue;
    if (!unseen.contains(v)) continue;
    stack.add(v);
  }
}

List<Set<String>> _ppComponentsInSubset(
  Set<String> nodes,
  Map<String, Set<String>> neighbours,
) {
  final unseen = nodes.toSet();
  final comps = <Set<String>>[];
  while (unseen.isNotEmpty) {
    final start = unseen.first;
    final comp = <String>{};
    final stack = <String>[start];
    while (stack.isNotEmpty) {
      final u = stack.removeLast();
      if (!unseen.remove(u)) continue;
      comp.add(u);
      _pushSubsetNeighbors(u, nodes, unseen, neighbours, stack);
    }
    comps.add(comp);
  }
  return comps;
}

List<String> _lockedGrowthOrder(
  List<String> factionIds,
  Map<String, int> targetPerFaction,
) {
  final list = List<String>.from(factionIds)
    ..sort((a, b) {
      final c = targetPerFaction[b]!.compareTo(targetPerFaction[a]!);
      if (c != 0) return c;
      return a.compareTo(b);
    });
  return list;
}

List<MapEntry<int, List<String>>> _landmassEntriesSortedBySize(
  Map<int, List<String>> landmassToProvinces,
) {
  final list = landmassToProvinces.entries.toList()
    ..sort((a, b) {
      final c = b.value.length.compareTo(a.value.length);
      if (c != 0) return c;
      final amin = a.value.reduce((x, y) => x.compareTo(y) < 0 ? x : y);
      final bmin = b.value.reduce((x, y) => x.compareTo(y) < 0 ? x : y);
      return amin.compareTo(bmin);
    });
  return list;
}

List<String> _lockedMinorIdsOnSortedLandmassIndex({
  required int landmassIndexSorted,
  required List<String> minorIdsSorted,
}) {
  if (minorIdsSorted.length != 6) return const [];
  switch (landmassIndexSorted) {
    case 0:
      return [minorIdsSorted[0]];
    case 1:
      return [minorIdsSorted[1]];
    case 2:
      return [minorIdsSorted[2], minorIdsSorted[3]];
    case 3:
      return [minorIdsSorted[4], minorIdsSorted[5]];
    default:
      return const [];
  }
}

Map<String, String> _assignFactionsSingleComponentLocked({
  required List<String> factionIds,
  required Set<String> universe,
  required Map<String, Set<String>> neighbours,
  required Random? assignmentRandom,
  required int backtrackLimitPerFaction,
}) {
  if (factionIds.isEmpty || universe.isEmpty) return {};
  final targets = computeFairTargets(factionIds, universe.length);
  final comps = _ppComponentsInSubset(universe, neighbours);
  if (comps.length != 1) {
    throw SetupTopologyDataException(
      code: 'assignment_remainder_not_connected',
      details:
          'Locked-style assignment requires one P–P component on remainder '
          '(found ${comps.length} for factions ${factionIds.join(",")})',
    );
  }
  final land = comps.single;
  final order = _lockedGrowthOrder(factionIds, targets);
  return assignTerritoriesLockedOnLandmass(
    landmassProvinceIds: land,
    neighbours: neighbours,
    growthOrder: order,
    targetPerFaction: targets,
    mandatorySeedProvinceByFaction: const {},
    seedPickerRandom: assignmentRandom,
    backtrackLimitPerFaction: backtrackLimitPerFaction,
    observation: null,
  );
}

Map<String, String> _assignFactionsMultiComponentLocked({
  required List<String> factionIds,
  required Set<String> universe,
  required Map<String, Set<String>> neighbours,
  required Random? assignmentRandom,
  required int backtrackLimitPerFaction,
}) {
  if (factionIds.isEmpty || universe.isEmpty) return {};
  final targets = computeFairTargets(factionIds, universe.length);
  var components = _ppComponentsInSubset(universe, neighbours);
  components.sort((a, b) {
    final c = b.length.compareTo(a.length);
    if (c != 0) return c;
    final amin = a.reduce((x, y) => x.compareTo(y) < 0 ? x : y);
    final bmin = b.reduce((x, y) => x.compareTo(y) < 0 ? x : y);
    return amin.compareTo(bmin);
  });
  final allocated = List<int>.filled(components.length, 0);
  final compForFaction = <String, int>{};
  final facsOrdered = factionIds.toList()
    ..sort((a, b) {
      final c = targets[b]!.compareTo(targets[a]!);
      if (c != 0) return c;
      return a.compareTo(b);
    });
  for (final f in facsOrdered) {
    final t = targets[f]!;
    var bestCi = -1;
    var bestSlack = -1;
    for (var ci = 0; ci < components.length; ci++) {
      final slack = components[ci].length - allocated[ci];
      if (slack >= t && slack > bestSlack) {
        bestSlack = slack;
        bestCi = ci;
      }
    }
    if (bestCi < 0) {
      throw SetupTopologyDataException(
        code: 'faction_component_bin_pack_failed',
        details: 'Cannot place faction $f with target $t on remainder graph',
      );
    }
    compForFaction[f] = bestCi;
    allocated[bestCi] += t;
  }
  final byComp = <int, List<String>>{};
  for (final f in factionIds) {
    byComp.putIfAbsent(compForFaction[f]!, () => []).add(f);
  }
  final out = <String, String>{};
  for (final e in byComp.entries) {
    final land = components[e.key];
    final fs = e.value
      ..sort((a, b) {
        final c = targets[b]!.compareTo(targets[a]!);
        if (c != 0) return c;
        return a.compareTo(b);
      });
    final localTargets = {for (final f in fs) f: targets[f]!};
    final order = _lockedGrowthOrder(fs, localTargets);
    out.addAll(
      assignTerritoriesLockedOnLandmass(
        landmassProvinceIds: land,
        neighbours: neighbours,
        growthOrder: order,
        targetPerFaction: localTargets,
        mandatorySeedProvinceByFaction: const {},
        seedPickerRandom: assignmentRandom,
        backtrackLimitPerFaction: backtrackLimitPerFaction,
        observation: null,
      ),
    );
  }
  return out;
}

Map<String, String> _assignFactionsOnRemainderAuto({
  required List<String> factionIds,
  required Set<String> universe,
  required Map<String, Set<String>> neighbours,
  required Random? assignmentRandom,
  required int backtrackLimitPerFaction,
}) {
  final comps = _ppComponentsInSubset(universe, neighbours);
  if (comps.length == 1) {
    return _assignFactionsSingleComponentLocked(
      factionIds: factionIds,
      universe: universe,
      neighbours: neighbours,
      assignmentRandom: assignmentRandom,
      backtrackLimitPerFaction: backtrackLimitPerFaction,
    );
  }
  return _assignFactionsMultiComponentLocked(
    factionIds: factionIds,
    universe: universe,
    neighbours: neighbours,
    assignmentRandom: assignmentRandom,
    backtrackLimitPerFaction: backtrackLimitPerFaction,
  );
}

void _assertGpProvincesOnAssignedLandmass({
  required String gpId,
  required int expectedLm,
  required Map<String, String> owners,
  required Map<String, int> landmassIds,
}) {
  for (final e in owners.entries) {
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

Map<String, String> _assignOldWorldSingleLandmass({
  required int lmId,
  required Set<String> provs,
  required List<String> gpHere,
  required List<String> minorHere,
  required Map<String, int> targetPerGp,
  required int minProvincesPerMinor,
  required Map<String, String> gpSeeds,
  required Map<String, Set<String>> neighbours,
  required Map<String, int> landmassIds,
  required Random? assignmentRandom,
  required bool lockedSixMinorsOnFourContinents,
}) {
  final targets = <String, int>{
    for (final g in gpHere) g: targetPerGp[g]!,
    for (final m in minorHere) m: minProvincesPerMinor,
  };

  final mandatoryGpSeedProvinceByFaction = <String, String>{};
  for (final g in gpHere) {
    final seedEntry = gpSeeds.entries.firstWhere((e) => e.value == g);
    final sp = seedEntry.key;
    if (!provs.contains(sp)) {
      throw StateError(
        'GP $g sea-bound seed $sp not on expected landmass provinces',
      );
    }
    mandatoryGpSeedProvinceByFaction[g] = sp;
  }

  final growthOrder = _lockedGrowthOrder([...gpHere, ...minorHere], targets);

  if (growthOrder.isEmpty) {
    return {};
  }
  if (lockedSixMinorsOnFourContinents) {
    return assignTerritoriesLockedOnLandmass(
      landmassProvinceIds: provs,
      neighbours: neighbours,
      growthOrder: growthOrder,
      targetPerFaction: targets,
      mandatorySeedProvinceByFaction: mandatoryGpSeedProvinceByFaction,
      seedPickerRandom: assignmentRandom,
      backtrackLimitPerFaction: kDefaultBacktrackLimitPerFaction,
      observation: null,
    );
  }

  final seeds = <String, String>{
    for (final e in mandatoryGpSeedProvinceByFaction.entries) e.value: e.key,
  };
  for (final m in minorHere) {
    final candidates = provs.difference(seeds.keys.toSet()).toList()..sort();
    if (candidates.isEmpty) {
      throw StateError('No province left for minor $m seed on landmass $lmId');
    }
    if (assignmentRandom != null) candidates.shuffle(assignmentRandom);
    seeds[candidates.first] = m;
  }
  final avail = Set<String>.from(provs);
  final factionLandmassIds = {
    for (final g in gpHere) g: lmId,
    for (final m in minorHere) m: lmId,
  };
  // Cap total assignments so greedy leftovers cannot consume provinces reserved
  // for minors assigned later on the OW remainder (non-locked painting path).
  final maxTotalAssignment = targets.values.fold<int>(0, (a, b) => a + b);
  return assignTerritoriesByBfsGrowth(
    neighbours: neighbours,
    landmassIds: landmassIds,
    factionLandmassIds: factionLandmassIds,
    factionIds: growthOrder,
    seeds: seeds,
    targetPerFaction: targets,
    available: avail,
    maxTotal: maxTotalAssignment,
    neighborShuffleRandom: assignmentRandom,
  );
}

Map<String, String> _assignOldWorldOwnershipContiguous({
  required Map<String, Set<String>> neighbours,
  required List<String> provinceIds,
  required List<String> seaBoundProvinceIds,
  required List<String> gpIds,
  required List<String> minorIds,
  required int minProvincesPerMinor,
  Random? assignmentRandom,
  required bool useLockedSixMinorContinentPainting,
}) {
  final landmassIds = _landmassIdsFromNeighbours(neighbours);

  final gpCount = gpIds.length;
  final minorCount = minorIds.length;

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
  final owners = <String, String>{};

  final lmSorted = _landmassEntriesSortedBySize(landmassToProvinces);
  final lockedSixMinorsOnFourContinents = useLockedSixMinorContinentPainting;

  for (var li = 0; li < lmSorted.length; li++) {
    final lmId = lmSorted[li].key;
    final provs = lmSorted[li].value.toSet();
    final gpHere = gpIds.where((g) => gpLandmassAssignments[g] == lmId).toList()
      ..sort();
    final minorHere = lockedSixMinorsOnFourContinents
        ? _lockedMinorIdsOnSortedLandmassIndex(
            landmassIndexSorted: li,
            minorIdsSorted: minorIds.toList()..sort(),
          )
        : <String>[];

    final part = _assignOldWorldSingleLandmass(
      lmId: lmId,
      provs: provs,
      gpHere: gpHere,
      minorHere: minorHere,
      targetPerGp: targetPerGp,
      minProvincesPerMinor: minProvincesPerMinor,
      gpSeeds: gpSeeds,
      neighbours: neighbours,
      landmassIds: landmassIds,
      assignmentRandom: assignmentRandom,
      lockedSixMinorsOnFourContinents: lockedSixMinorsOnFourContinents,
    );
    owners.addAll(part);
    for (final p in part.keys) {
      gpAvailable.remove(p);
    }
  }

  for (final gpId in gpIds) {
    final expectedLm = gpLandmassAssignments[gpId];
    if (expectedLm == null) continue;
    _assertGpProvincesOnAssignedLandmass(
      gpId: gpId,
      expectedLm: expectedLm,
      owners: owners,
      landmassIds: landmassIds,
    );
  }

  if (minorCount > 0 &&
      gpAvailable.isNotEmpty &&
      !lockedSixMinorsOnFourContinents) {
    final minorUniverse = Set<String>.from(gpAvailable);
    final minorTargets = computeFairTargets(minorIds, minorUniverse.length);
    final minorOrder = _lockedGrowthOrder(minorIds, minorTargets);
    final minorCand = minorUniverse.toList()..sort();
    final minorSeeds = pickSimpleSeeds(
      factionIds: minorOrder,
      candidateIds: minorCand,
      available: Set<String>.from(minorUniverse),
    );
    owners.addAll(
      assignTerritoriesByBfsGrowth(
        neighbours: neighbours,
        factionIds: minorOrder,
        seeds: minorSeeds,
        targetPerFaction: minorTargets,
        available: minorUniverse,
        neighborShuffleRandom: assignmentRandom,
      ),
    );
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
  final universe = provinceIds.toSet();
  return _assignFactionsOnRemainderAuto(
    factionIds: tribeIds,
    universe: Set<String>.from(universe),
    neighbours: neighbours,
    assignmentRandom: null,
    backtrackLimitPerFaction: kDefaultBacktrackLimitPerFaction,
  );
}
