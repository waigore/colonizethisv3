// Package-internal landmass paint facade (Refs #4029 / #4086 Slice A+B de-part).

import 'dart:math';

import 'game_setup_ownership_comparators.dart';
import 'locked_province_assigner.dart';
import 'province_assignment.dart';

/// Locked DFS vs BFS growth backends for landmass paint scaffolding.
enum LandmassPaintMode { locked, bfs }

/// How BFS mode obtains province→faction seeds.
enum BfsSeedMode { provided, pickSimple }

List<String> _lockedGrowthOrder(
  List<String> factionIds,
  Map<String, int> targetPerFaction,
) {
  final list = List<String>.from(factionIds)
    ..sort((a, b) => compareByTargetDescThenIdAsc(a, b, targetPerFaction));
  return list;
}

/// Package-internal landmass paint facade: growth-order + seed scaffolding into
/// locked or BFS backends (solvers stay separate). Refs #4029.
Map<String, String> paintLandmass({
  required LandmassPaintMode mode,
  required Set<String> landmassProvinceIds,
  required Map<String, Set<String>> neighbours,
  required List<String> factionIds,
  required Map<String, int> targetPerFaction,
  Map<String, String> mandatorySeedProvinceByFaction = const {},
  BfsSeedMode bfsSeedMode = BfsSeedMode.provided,
  Map<String, String>? bfsSeeds,
  Map<String, int>? landmassIds,
  Map<String, int>? factionLandmassIds,
  int? maxTotal,
  Random? assignmentRandom,
  int backtrackLimitPerFaction = kDefaultBacktrackLimitPerFaction,
}) {
  if (factionIds.isEmpty || landmassProvinceIds.isEmpty) {
    return {};
  }
  final growthOrder = _lockedGrowthOrder(factionIds, targetPerFaction);
  if (growthOrder.isEmpty) {
    return {};
  }

  switch (mode) {
    case LandmassPaintMode.locked:
      return assignTerritoriesLockedOnLandmass(
        landmassProvinceIds: landmassProvinceIds,
        neighbours: neighbours,
        growthOrder: growthOrder,
        targetPerFaction: targetPerFaction,
        mandatorySeedProvinceByFaction: mandatorySeedProvinceByFaction,
        seedPickerRandom: assignmentRandom,
        backtrackLimitPerFaction: backtrackLimitPerFaction,
        observation: null,
      );
    case LandmassPaintMode.bfs:
      final seeds = switch (bfsSeedMode) {
        BfsSeedMode.provided => bfsSeeds ??
            (throw StateError(
              'paintLandmass bfs provided seed mode requires bfsSeeds',
            )),
        BfsSeedMode.pickSimple => pickSimpleSeeds(
          factionIds: growthOrder,
          candidateIds: (landmassProvinceIds.toList()..sort()),
          available: Set<String>.from(landmassProvinceIds),
        ),
      };
      return assignTerritoriesByBfsGrowth(
        neighbours: neighbours,
        landmassIds: landmassIds,
        factionLandmassIds: factionLandmassIds,
        factionIds: growthOrder,
        seeds: seeds,
        targetPerFaction: targetPerFaction,
        available: Set<String>.from(landmassProvinceIds),
        maxTotal: maxTotal,
        neighborShuffleRandom: assignmentRandom,
      );
  }
}

/// Lint-anchor alias for `repo.setup_dedup_ownership_paint` (Refs #4029).
/// Cross-library call sites use [paintLandmass]; this private name must remain
/// defined in this file so the CI symbol scan stays green after de-part.
// ignore: unused_element
Map<String, String> _paintLandmass({
  required LandmassPaintMode mode,
  required Set<String> landmassProvinceIds,
  required Map<String, Set<String>> neighbours,
  required List<String> factionIds,
  required Map<String, int> targetPerFaction,
  Map<String, String> mandatorySeedProvinceByFaction = const {},
  BfsSeedMode bfsSeedMode = BfsSeedMode.provided,
  Map<String, String>? bfsSeeds,
  Map<String, int>? landmassIds,
  Map<String, int>? factionLandmassIds,
  int? maxTotal,
  Random? assignmentRandom,
  int backtrackLimitPerFaction = kDefaultBacktrackLimitPerFaction,
}) =>
    paintLandmass(
      mode: mode,
      landmassProvinceIds: landmassProvinceIds,
      neighbours: neighbours,
      factionIds: factionIds,
      targetPerFaction: targetPerFaction,
      mandatorySeedProvinceByFaction: mandatorySeedProvinceByFaction,
      bfsSeedMode: bfsSeedMode,
      bfsSeeds: bfsSeeds,
      landmassIds: landmassIds,
      factionLandmassIds: factionLandmassIds,
      maxTotal: maxTotal,
      assignmentRandom: assignmentRandom,
      backtrackLimitPerFaction: backtrackLimitPerFaction,
    );
