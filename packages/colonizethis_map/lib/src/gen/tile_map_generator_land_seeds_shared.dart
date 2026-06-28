/// Shared Voronoi/buffer helpers for the land-seed passes.
///
/// SPEC/program/tile-map-gen-algorithm.md.
///
/// Extracted from the former `tile_map_generator_land_seeds_shared_part`
/// `part` fragment so the helpers are an independently importable, testable
/// unit (see #3588). Used by the placement (seed-before-assignment), organic,
/// and coastline-growth passes.
library;

import 'grid_voronoi.dart';
import 'tile_map_distance_sentinels.dart';
import 'tile_map_land_seed_contract.dart';
import '../tile_map_grid.dart';

/// Voronoi index-range bookkeeping, per-cell best-continent / cell-entry
/// assembly, continent-buffer join checks, and buffer-offset enumeration.
class LandSeedShared {
  const LandSeedShared._();

  static (int start, int end) landSeedIndexRangeForContinent(
    List<int> continentBySeedIndex,
    int landSeedCount,
    int continent,
  ) {
    var start = landSeedCount;
    var end = 0;
    for (var i = 0; i < landSeedCount; i++) {
      if (continentBySeedIndex[i] != continent) continue;
      if (i < start) start = i;
      end = i + 1;
    }
    return (start, end);
  }

  static void fillLandSeedIndexRangesByContinent(
    List<int> continentBySeedIndex,
    int numContinents,
    int landSeedCount,
    List<int> seedStartByContinent,
    List<int> seedEndByContinent,
  ) {
    for (var c = 0; c < numContinents; c++) {
      final range = landSeedIndexRangeForContinent(
        continentBySeedIndex,
        landSeedCount,
        c,
      );
      seedStartByContinent[c] = range.$1;
      seedEndByContinent[c] = range.$2;
    }
  }

  static (int continent, double bestD2) bestContinentForCellVoronoi(
    TileMapLandSeedParams params,
    List<(int x, int y)> landSeeds,
    int numContinents,
    List<int> seedStartByContinent,
    List<int> seedEndByContinent,
    int x,
    int y,
  ) {
    var bestD2 = 1e100;
    var bestC = 0;
    for (var c = 0; c < numContinents; c++) {
      final start = seedStartByContinent[c];
      final end = seedEndByContinent[c];
      var d2 = kUnsetSquaredDistanceInt31;
      for (var i = start; i < end; i++) {
        final (sx, sy) = landSeeds[i];
        final dd = (x - sx) * (x - sx) + (y - sy) * (y - sy);
        if (dd < d2) d2 = dd;
      }
      final noise = params.voronoiNoiseScale > 0
          ? deterministicNoise(params.seed, x, y) * params.voronoiNoiseScale
          : 0.0;
      final effective = d2.toDouble() + noise;
      if (effective >= bestD2) continue;
      bestD2 = effective;
      bestC = c;
    }
    return (bestC, bestD2);
  }

  static List<(double effectiveD2, int x, int y, int continent)>
  voronoiLandCellEntries(
    TileMapLandSeedParams params,
    List<(int x, int y)> landSeeds,
    int numContinents,
    List<int> seedStartByContinent,
    List<int> seedEndByContinent,
  ) {
    final entries = <(double effectiveD2, int x, int y, int continent)>[];
    TileMapGrid.forEachIndex(params.height, params.width, (y, x) {
      final (bestC, bestD2) = bestContinentForCellVoronoi(
        params,
        landSeeds,
        numContinents,
        seedStartByContinent,
        seedEndByContinent,
        x,
        y,
      );
      entries.add((bestD2, x, y, bestC));
    });
    return entries;
  }

  static bool wouldJoinOtherContinentInBuffer(
    List<List<int>> nextContinent,
    TileMapLandSeedParams params,
    int x,
    int y,
    int continent,
    List<(int, int)> offsets,
  ) {
    for (final (dx, dy) in offsets) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx >= 0 && nx < params.width && ny >= 0 && ny < params.height) {
        final nc = nextContinent[ny][nx];
        if (nc >= 0 && nc != continent) {
          return true;
        }
      }
    }
    return false;
  }

  /// Offsets (dx, dy) where |dx|+|dy| in [1, maxDist], for no-join buffer.
  static List<(int, int)> bufferOffsets(int maxDist) {
    if (maxDist <= 0) return [];
    final out = <(int, int)>[];
    for (var dy = -maxDist; dy <= maxDist; dy++) {
      for (var dx = -maxDist; dx <= maxDist; dx++) {
        if (dx == 0 && dy == 0) continue;
        if (dx.abs() + dy.abs() <= maxDist) out.add((dx, dy));
      }
    }
    return out;
  }
}
