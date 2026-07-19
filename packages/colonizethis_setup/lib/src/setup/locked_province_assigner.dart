// SPEC/program/locked-province-assigner.md — phased seeds + per-faction backtrack + cross-unwind.

import 'dart:math';

import 'locked_province_assigner_engine.dart';
import 'locked_province_assigner_graph.dart';
import 'locked_province_assigner_types.dart';

export 'locked_province_assigner_types.dart';

/// Greedy necessary check: each residual can be placed on some island at least as large.
bool islandResidualsFeasibleGreedy({
  required Set<String> unassignedOnLand,
  required Map<String, Set<String>> neighbours,
  required Set<String> land,
  required List<int> residualsSortedDesc,
}) {
  if (residualsSortedDesc.isEmpty) return true;
  final islands = islandSizesOnLand(unassignedOnLand, neighbours, land);
  if (islands.isEmpty) return residualsSortedDesc.every((r) => r == 0);
  var j = 0;
  for (final r in residualsSortedDesc) {
    if (r <= 0) continue;
    while (j < islands.length && islands[j] < r) {
      j++;
    }
    if (j >= islands.length) return false;
    j++;
  }
  return true;
}

/// Phased locked growth on one P–P landmass: factions in [growthOrder] are grown
/// **one at a time**. A faction receives a **seed** only when it becomes active
/// (all earlier factions already at target). Mandatory seeds ([mandatorySeedProvinceByFaction])
/// are applied when that faction is seeded; other factions pick a seed from
/// remaining provinces via [pickSimpleSeeds] / shuffle ([seedPickerRandom]).
///
/// Per-faction backtracks are capped by [backtrackLimitPerFaction]. When the cap
/// is hit, or the search dead-ends, the assigner unwinds the last removable
/// province of the **previous** faction in [growthOrder] (never mandatory seeds).
/// If that is impossible (e.g. first faction), a **capital-generation restart**
/// clears the landmass and retries (bounded).
Map<String, String> assignTerritoriesLockedOnLandmass({
  required Set<String> landmassProvinceIds,
  required Map<String, Set<String>> neighbours,
  required List<String> growthOrder,
  required Map<String, int> targetPerFaction,
  Map<String, String> mandatorySeedProvinceByFaction = const {},
  Random? seedPickerRandom,
  int backtrackLimitPerFaction = kDefaultBacktrackLimitPerFaction,
  LockedAssignerObservation? observation,
}) {
  final engine = LockedAssignerEngine(
    landmassProvinceIds: landmassProvinceIds,
    neighbours: neighbours,
    growthOrder: growthOrder,
    targetPerFaction: targetPerFaction,
    mandatorySeedProvinceByFaction: mandatorySeedProvinceByFaction,
    seedPickerRandom: seedPickerRandom,
    backtrackLimitPerFaction: backtrackLimitPerFaction,
    observation: observation,
  );
  return engine.run();
}
