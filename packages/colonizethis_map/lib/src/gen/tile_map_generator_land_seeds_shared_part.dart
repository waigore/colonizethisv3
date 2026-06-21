// Shared helpers for [TileMapGenLandSeeds]:
// Voronoi index range bookkeeping, per-cell best-continent / cell-entry
// assembly, continent-buffer join checks, and buffer-offset enumeration.
// Used by both placement (`_assignLandByLandSeedsImpl`) and organic
// (`_assignLandByLandSeedsWithNoJoin`, `_growCoastlines`) passes.
part of 'tile_map_generator_land_seeds.dart';

(int start, int end) _landSeedIndexRangeForContinent(
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

void _fillLandSeedIndexRangesByContinent(
  List<int> continentBySeedIndex,
  int numContinents,
  int landSeedCount,
  List<int> seedStartByContinent,
  List<int> seedEndByContinent,
) {
  for (var c = 0; c < numContinents; c++) {
    final range = _landSeedIndexRangeForContinent(
      continentBySeedIndex,
      landSeedCount,
      c,
    );
    seedStartByContinent[c] = range.$1;
    seedEndByContinent[c] = range.$2;
  }
}

(int continent, double bestD2) _bestContinentForCellVoronoi(
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

List<(double effectiveD2, int x, int y, int continent)> _voronoiLandCellEntries(
  TileMapLandSeedParams params,
  List<(int x, int y)> landSeeds,
  int numContinents,
  List<int> seedStartByContinent,
  List<int> seedEndByContinent,
) {
  final entries = <(double effectiveD2, int x, int y, int continent)>[];
  TileMapGrid.forEachIndex(params.height, params.width, (y, x) {
    final (bestC, bestD2) = _bestContinentForCellVoronoi(
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

bool _wouldJoinOtherContinentInBuffer(
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
List<(int, int)> _bufferOffsets(int maxDist) {
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
