import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/src/utils/graph_traversal.dart';
import 'capital_choice.dart';
import 'faction_setup_helpers.dart';
import 'game_setup_topology.dart';
import 'locked_province_assigner.dart';
import 'province_assignment.dart';
import 'setup_exceptions.dart';

part 'game_setup_ownership_comparators.dart';
part 'game_setup_ownership_gp_packing.dart';
part 'game_setup_ownership_remainder_factions.dart';

Game assignCapitalsForFactions({
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
    final owned = ownedProvinceIdsForFaction(
      provinces,
      factionId,
      sorted: false,
    );
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

Map<String, String> assignOldWorldOwnershipContiguous({
  required Map<String, Set<String>> neighbours,
  required List<String> provinceIds,
  required List<String> seaBoundProvinceIds,
  required List<String> gpIds,
  required List<String> minorIds,
  required int minProvincesPerMinor,
  Random? assignmentRandom,
  required bool useLockedSixMinorContinentPainting,
}) {
  final landmassIds = landmassIdsFromProvinceAdjacency(neighbours);

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

Map<String, String> assignNewWorldOwnershipContiguous({
  required MapTopology topologyNewWorld,
  required List<String> provinceIds,
  required List<String> tribeIds,
}) {
  if (tribeIds.isEmpty) {
    return {for (final p in provinceIds) p: ''};
  }

  final neighbours = provinceNeighboursFromTopology(topologyNewWorld);
  final universe = provinceIds.toSet();
  return _assignFactionsOnRemainderAuto(
    factionIds: tribeIds,
    universe: Set<String>.from(universe),
    neighbours: neighbours,
    assignmentRandom: null,
    backtrackLimitPerFaction: kDefaultBacktrackLimitPerFaction,
  );
}
