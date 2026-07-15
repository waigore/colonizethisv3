part of 'game_setup_ownership.dart';

/// Locked DFS vs BFS growth backends for landmass paint scaffolding.
enum _LandmassPaintMode { locked, bfs }

/// How BFS mode obtains province→faction seeds.
enum _BfsSeedMode { provided, pickSimple }

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
Map<String, String> _paintLandmass({
  required _LandmassPaintMode mode,
  required Set<String> landmassProvinceIds,
  required Map<String, Set<String>> neighbours,
  required List<String> factionIds,
  required Map<String, int> targetPerFaction,
  Map<String, String> mandatorySeedProvinceByFaction = const {},
  _BfsSeedMode bfsSeedMode = _BfsSeedMode.provided,
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
    case _LandmassPaintMode.locked:
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
    case _LandmassPaintMode.bfs:
      final seeds = switch (bfsSeedMode) {
        _BfsSeedMode.provided => bfsSeeds ??
            (throw StateError(
              '_paintLandmass bfs provided seed mode requires bfsSeeds',
            )),
        _BfsSeedMode.pickSimple => pickSimpleSeeds(
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
