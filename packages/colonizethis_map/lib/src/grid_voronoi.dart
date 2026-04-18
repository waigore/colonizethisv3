// Reusable Voronoi assignment for grid cells. SPEC/program/tile-map-gen-algorithm.md § Voronoi assignment.

import 'package:colonizethis_models/colonizethis_models.dart';

/// Deterministic noise in [-1, 1] for Voronoi boundary irregularity.
/// Same formula as tile_map_generator so land/province/sea boundaries behave consistently.
double deterministicNoise(int seed, int x, int y) {
  var h = (seed * 31 + x) * 31 + y;
  h = (h ^ (h >> 16)) * 0x85ebca6b;
  h = (h ^ (h >> 13)) * 0xc2b2ae35;
  h = h ^ (h >> 16);
  return (h & kDeterministicLcg31Mask) / kDeterministicLcg31Mask * 2 - 1;
}

/// Assigns each cell to the id of the nearest seed by Euclidean distance (squared).
/// Optional [noiseScale] and [noiseSeed]: effective distance = d2 + noiseScale * deterministicNoise(noiseSeed, x, y).
/// Ties broken by seed id (smaller id wins).
Map<(int x, int y), String> assignCellsToNearestSeed(
  Iterable<(int x, int y)> cells,
  Map<String, (int x, int y)> seeds, {
  double noiseScale = 0,
  int noiseSeed = 0,
}) {
  if (seeds.isEmpty) return {};
  final result = <(int x, int y), String>{};
  final seedIds = seeds.keys.toList()..sort();
  for (final (x, y) in cells) {
    var bestId = seedIds.first;
    var bestEff = 1e100;
    for (final id in seedIds) {
      final (sx, sy) = seeds[id]!;
      final d2 = (x - sx) * (x - sx) + (y - sy) * (y - sy);
      final noise = noiseScale != 0
          ? deterministicNoise(noiseSeed, x, y) * noiseScale
          : 0.0;
      final eff = d2.toDouble() + noise;
      if (eff < bestEff) {
        bestEff = eff;
        bestId = id;
      }
    }
    result[(x, y)] = bestId;
  }
  return result;
}
