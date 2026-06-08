part of 'game_setup_ownership.dart';

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
