/// Shared terrain dominance-counting helper for the generation layer.
///
/// Deduplicates the per-province / per-neighbourhood "most frequent terrain"
/// argmax that previously appeared independently in the terrain-assignment pass
/// (`_mostFrequentTerrain`) and the terrain-jitter pass
/// (`jitterTerrainByProvince`). Refs #3588.
/// SPEC/program/tile-map-gen-algorithm.md § Implementation Structure.
library;

import 'package:colonizethis_data/colonizethis_data.dart';

/// Returns the [TerrainType] with the highest count in [counts].
///
/// On ties, the first-inserted key among the maxima is returned, so the result
/// is deterministic for a fixed insertion order (generation determinism is
/// preserved). [counts] must be non-empty; callers guard the empty case before
/// invoking this helper.
TerrainType mostFrequentTerrain(Map<TerrainType, int> counts) {
  TerrainType best = counts.keys.first;
  var bestCount = counts[best]!;
  for (final entry in counts.entries) {
    if (entry.value <= bestCount) continue;
    best = entry.key;
    bestCount = entry.value;
  }
  return best;
}
