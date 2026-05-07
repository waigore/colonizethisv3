import 'dart:math';

import 'package:colonizethis_models/colonizethis_models.dart';

import 'grid_voronoi.dart';
import 'tile_map_distance_sentinels.dart';
import 'tile_map_land_sentinel.dart';
import 'tile_map_land_seed_contract.dart';

const String _landSentinel = kTileMapLandSentinel;

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
  for (var y = 0; y < params.height; y++) {
    for (var x = 0; x < params.width; x++) {
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
    }
  }
  return entries;
}

int _minManhattanDistToPoints(int x, int y, List<(int x, int y)> points) {
  var minD = 1 << 30;
  for (final (ox, oy) in points) {
    final d = (x - ox).abs() + (y - oy).abs();
    if (d < minD) minD = d;
  }
  return minD;
}

List<(int x, int y)> _organicSeedCloseSeaCandidates(
  TileMapLandSeedParams params,
  List<List<String>> grid,
  String seaZoneId,
  List<(int x, int y)> ownLandOrSeed,
  int closeRadius,
) {
  final candidates = <(int x, int y)>[];
  for (var y = 0; y < params.height; y++) {
    for (var x = 0; x < params.width; x++) {
      if (grid[y][x] != seaZoneId) continue;
      final minDistToOwn = _minManhattanDistToPoints(x, y, ownLandOrSeed);
      if (minDistToOwn > closeRadius) continue;
      candidates.add((x, y));
    }
  }
  return candidates;
}

int _minManhattanDistToOtherContinentCells(
  List<List<int>> continentGrid,
  TileMapLandSeedParams params,
  int x,
  int y,
  int ownContinent,
) {
  var minDistToOther = params.width + params.height;
  for (var ny = 0; ny < params.height; ny++) {
    for (var nx = 0; nx < params.width; nx++) {
      final cell = continentGrid[ny][nx];
      if (cell < 0 || cell == ownContinent) continue;
      final d = (x - nx).abs() + (y - ny).abs();
      if (d < minDistToOther) minDistToOther = d;
    }
  }
  return minDistToOther;
}

(int, int) _pickBestOrganicSeaCandidate(
  List<(int x, int y)> candidates,
  List<(int x, int y)> ownLandOrSeed,
  List<List<int>> continentGrid,
  TileMapLandSeedParams params,
  int continentIndex,
  double awayPenalty,
  Random rnd,
) {
  var bestScore = -1e100;
  final bestCandidates = <(int x, int y)>[];
  for (final (x, y) in candidates) {
    final minDistToOwn = _minManhattanDistToPoints(x, y, ownLandOrSeed);
    final minDistToOther = _minManhattanDistToOtherContinentCells(
      continentGrid,
      params,
      x,
      y,
      continentIndex,
    );
    final score = -minDistToOwn + awayPenalty * minDistToOther;
    if (score > bestScore) {
      bestScore = score;
      bestCandidates.clear();
      bestCandidates.add((x, y));
    } else if ((score - bestScore).abs() < 0.01) {
      bestCandidates.add((x, y));
    }
  }
  if (bestCandidates.isEmpty) return (-1, -1);
  return bestCandidates[rnd.nextInt(bestCandidates.length)];
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

void _appendOrthogonalSeaNeighborsToCoastalList(
  TileMapLandSeedParams params,
  List<List<String>> g,
  String seaZoneId,
  int sx,
  int sy,
  List<(int x, int y)> coastalList,
) {
  for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
    final nx = sx + dx;
    final ny = sy + dy;
    if (nx >= 0 &&
        nx < params.width &&
        ny >= 0 &&
        ny < params.height &&
        g[ny][nx] == seaZoneId &&
        !coastalList.contains((nx, ny))) {
      coastalList.add((nx, ny));
    }
  }
}

void _registerFirstOrthogonalSeaTouchingLand(
  TileMapLandSeedParams params,
  List<List<String>> g,
  String seaZoneId,
  int x,
  int y,
  void Function(int nx, int ny) onSea,
) {
  for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
    final nx = x + dx;
    final ny = y + dy;
    if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
      continue;
    }
    if (g[ny][nx] != seaZoneId) continue;
    onSea(nx, ny);
    return;
  }
}

void _registerCoastalSeaTilesAdjacentToLand(
  TileMapLandSeedParams params,
  List<List<String>> g,
  List<List<int>> cg,
  String seaZoneId,
  Map<int, List<(int x, int y)>> coastalByContinent,
) {
  for (var y = 0; y < params.height; y++) {
    for (var x = 0; x < params.width; x++) {
      if (g[y][x] != _landSentinel) continue;
      final c = cg[y][x];
      if (c < 0) continue;
      _registerFirstOrthogonalSeaTouchingLand(
        params,
        g,
        seaZoneId,
        x,
        y,
        (nx, ny) => coastalByContinent[c]!.add((nx, ny)),
      );
    }
  }
}

int _coastalNeighborScoreDelta(
  List<List<String>> g,
  List<List<int>> cg,
  int nx,
  int ny,
  int continentIndex,
) {
  if (g[ny][nx] != _landSentinel) return 0;
  final nc = cg[ny][nx];
  if (nc == continentIndex) return 1;
  if (nc >= 0 && nc != continentIndex) return -10;
  return 0;
}

int _scoreCoastalCellForContinent(
  List<List<String>> g,
  List<List<int>> cg,
  TileMapLandSeedParams params,
  int sx,
  int sy,
  int continentIndex,
  int scoreRadius,
) {
  var score = 0;
  for (var dy = -scoreRadius; dy <= scoreRadius; dy++) {
    for (var dx = -scoreRadius; dx <= scoreRadius; dx++) {
      final nx = sx + dx;
      final ny = sy + dy;
      if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
        continue;
      }
      if (dx == 0 && dy == 0) continue;
      score += _coastalNeighborScoreDelta(g, cg, nx, ny, continentIndex);
    }
  }
  return score;
}

/// Pass 2–3: land seed placement and assignment (organic and seed-before-assignment).
class TileMapGenLandSeeds {
  TileMapGenLandSeeds(this.params);

  final TileMapLandSeedParams params;

  /// One continent seed per continent; then a cluster of land-shape seeds per continent (K from province count). No province seeds yet.
  (List<(int x, int y)>, List<(int x, int y)>, List<int>) placeLandSeeds(
    Map<String, int> provinceToContinent,
    Random rnd,
  ) {
    if (provinceToContinent.isEmpty) {
      return (<(int x, int y)>[], <(int x, int y)>[], <int>[]);
    }
    final numContinents = provinceToContinent.values.toSet().length;
    if (numContinents < 1) {
      return (<(int x, int y)>[], <(int x, int y)>[], <int>[]);
    }
    final provincesByContinent = <int, List<String>>{};
    for (final e in provinceToContinent.entries) {
      provincesByContinent.putIfAbsent(e.value, () => []).add(e.key);
    }
    for (final list in provincesByContinent.values) {
      list.sort();
    }
    const minSeedsPerContinent = 5;
    final continentSeeds = <(int x, int y)>[];
    final landSeeds = <(int x, int y)>[];
    final continentBySeedIndex = <int>[];

    for (var c = 0; c < numContinents; c++) {
      final yLo = (params.height * c / numContinents).floor();
      final yHi = c + 1 == numContinents
          ? params.height
          : (params.height * (c + 1) / numContinents).floor();
      final bandHeight = (yHi - yLo).clamp(1, params.height);
      final bandWidth = params.width;

      // One continent seed per continent (random in band)
      final cx = rnd.nextInt(params.width);
      final cy = yLo + rnd.nextInt(bandHeight);
      continentSeeds.add((cx, cy));

      // K = max(minSeeds, provinces in this continent)
      final provincesInContinent = provincesByContinent[c]!.length;
      final K = (minSeedsPerContinent > provincesInContinent)
          ? minSeedsPerContinent
          : provincesInContinent;

      // Sigma for Gaussian: fraction of band size so cluster stays roughly in band
      final sigma = (bandWidth + bandHeight) / 8.0;
      final diskR = (min(bandWidth, bandHeight) / 2.0 * 0.8).ceil();
      final annulusInner = diskR ~/ 2;
      final annulusOuter = diskR;

      for (var k = 0; k < K; k++) {
        int dx;
        int dy;
        switch (params.clusterShape) {
          case LandSeedClusterShape.gaussian:
            final gx = _nextGaussian(rnd) * sigma;
            final gy = _nextGaussian(rnd) * sigma;
            dx = gx.round();
            dy = gy.round();
            break;
          case LandSeedClusterShape.uniformDisk:
            final angle = rnd.nextDouble() * 2 * pi;
            final r = sqrt(rnd.nextDouble()) * diskR;
            dx = (cos(angle) * r).round();
            dy = (sin(angle) * r).round();
            break;
          case LandSeedClusterShape.uniformAnnulus:
            final angle = rnd.nextDouble() * 2 * pi;
            final r =
                annulusInner + rnd.nextDouble() * (annulusOuter - annulusInner);
            dx = (cos(angle) * r).round();
            dy = (sin(angle) * r).round();
            break;
        }
        final x = (cx + dx).clamp(0, params.width - 1);
        final y = (cy + dy).clamp(yLo, yHi - 1);
        landSeeds.add((x, y));
        continentBySeedIndex.add(c);
      }
    }
    return (continentSeeds, landSeeds, continentBySeedIndex);
  }

  /// Organic land growing: interleaved seed placement + small Voronoi + coastline growth.
  /// Returns (continentSeeds, landSeeds, continentBySeedIndex, grid).
  (List<(int x, int y)>, List<(int x, int y)>, List<int>, List<List<String>>)
  placeLandSeedsOrganic(
    List<List<String>> grid,
    Map<String, int> provinceToContinent,
    String seaZoneId,
    Random rnd,
  ) {
    if (provinceToContinent.isEmpty) {
      return (<(int x, int y)>[], <(int x, int y)>[], <int>[], grid);
    }
    final numContinents = provinceToContinent.values.toSet().length;
    if (numContinents < 1) {
      return (<(int x, int y)>[], <(int x, int y)>[], <int>[], grid);
    }

    final provincesByContinent = <int, List<String>>{};
    for (final e in provinceToContinent.entries) {
      provincesByContinent.putIfAbsent(e.value, () => []).add(e.key);
    }
    for (final list in provincesByContinent.values) {
      list.sort();
    }

    const minSeedsPerContinent = 5;
    final seedsPerContinent = <int>[];
    for (var c = 0; c < numContinents; c++) {
      final pc = provincesByContinent[c]!.length;
      seedsPerContinent.add(
        minSeedsPerContinent > pc ? minSeedsPerContinent : pc,
      );
    }
    final totalSeeds = seedsPerContinent.reduce((a, b) => a + b);
    final totalRounds = (totalSeeds / numContinents).ceil().clamp(1, 999);

    final landBudgetTotal =
        ((1 - params.seaFraction) * params.width * params.height).round();
    if (landBudgetTotal <= 0) {
      return (<(int x, int y)>[], <(int x, int y)>[], <int>[], grid);
    }

    // Step 0: Place continent seeds
    final continentSeeds = <(int x, int y)>[];
    for (var c = 0; c < numContinents; c++) {
      final yLo = (params.height * c / numContinents).floor();
      final yHi = c + 1 == numContinents
          ? params.height
          : (params.height * (c + 1) / numContinents).floor();
      final bandHeight = (yHi - yLo).clamp(1, params.height);
      final cx = rnd.nextInt(params.width);
      final cy = yLo + rnd.nextInt(bandHeight);
      continentSeeds.add((cx, cy));
    }

    final landSeeds = <(int x, int y)>[];
    final continentBySeedIndex = <int>[];
    var g = grid.map((row) => row.toList()).toList();
    final continentGrid = List.generate(
      params.height,
      (_) => List.filled(params.width, -1),
    );

    const closeRadius = 5;
    const awayPenalty = 0.7;

    // Per-round land budget: reserve totalSeeds for seed positions, rest for Voronoi
    final voronoiBudgetTotal = (landBudgetTotal - totalSeeds).clamp(
      0,
      landBudgetTotal,
    );
    final totalProvinces = provinceToContinent.length;

    final seedCountsPerContinent = List<int>.filled(numContinents, 0);
    var voronoiRemaining = voronoiBudgetTotal;

    for (var round = 0; round < totalRounds; round++) {
      final roundBudget = (round + 1 == totalRounds)
          ? voronoiRemaining
          : (voronoiBudgetTotal / totalRounds).round();
      final budgetPerContinent = <int>[];
      for (var c = 0; c < numContinents; c++) {
        budgetPerContinent.add(
          (roundBudget * provincesByContinent[c]!.length / totalProvinces)
              .round(),
        );
      }
      var roundUsed = 0;
      for (var c = 0; c < numContinents; c++) {
        roundUsed += budgetPerContinent[c];
      }
      if (roundUsed != roundBudget && numContinents > 0) {
        budgetPerContinent[0] += roundBudget - roundUsed;
      }
      voronoiRemaining -= roundBudget;
      // Step 1: Place one land seed per continent (if needed)
      for (var c = 0; c < numContinents; c++) {
        if (seedCountsPerContinent[c] >= seedsPerContinent[c]) continue;
        final (sx, sy) = _placeOneOrganicSeed(
          g,
          continentGrid,
          continentSeeds[c],
          landSeeds,
          continentBySeedIndex,
          c,
          closeRadius,
          awayPenalty,
          numContinents,
          seaZoneId,
          rnd,
        );
        if (sx >= 0 && sy >= 0) {
          landSeeds.add((sx, sy));
          continentBySeedIndex.add(c);
          seedCountsPerContinent[c]++;
          g[sy][sx] = _landSentinel;
          continentGrid[sy][sx] = c;
        }
      }

      // Step 2: Small Voronoi with no-join (use round's budgetPerContinent)
      final voronoiResult = _assignLandByLandSeedsWithNoJoin(
        g,
        continentGrid,
        landSeeds,
        continentBySeedIndex,
        seaZoneId,
        budgetPerContinent,
      );
      g = voronoiResult.$1;
      for (var y = 0; y < params.height; y++) {
        for (var x = 0; x < params.width; x++) {
          continentGrid[y][x] = voronoiResult.$2[y][x];
        }
      }
    }

    // Step 3: Coastline growth if budget remains
    var usedTotal = 0;
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (g[y][x] == _landSentinel) usedTotal++;
      }
    }
    if (usedTotal < landBudgetTotal) {
      final remaining = landBudgetTotal - usedTotal;
      final (g2, _) = _growCoastlines(
        g,
        continentGrid,
        remaining,
        provinceToContinent,
        seaZoneId,
        rnd,
      );
      g = g2;
    }

    return (continentSeeds, landSeeds, continentBySeedIndex, g);
  }

  /// Place one land seed near existing land of continent c, preferably away from others.
  (int, int) _placeOneOrganicSeed(
    List<List<String>> grid,
    List<List<int>> continentGrid,
    (int x, int y) continentSeed,
    List<(int x, int y)> existingLandSeeds,
    List<int> continentBySeedIndex,
    int c,
    int closeRadius,
    double awayPenalty,
    int numContinents,
    String seaZoneId,
    Random rnd,
  ) {
    final ownLandOrSeed = <(int x, int y)>[continentSeed];
    for (var i = 0; i < existingLandSeeds.length; i++) {
      if (continentBySeedIndex[i] == c) {
        ownLandOrSeed.add(existingLandSeeds[i]);
      }
    }
    final candidates = _organicSeedCloseSeaCandidates(
      params,
      grid,
      seaZoneId,
      ownLandOrSeed,
      closeRadius,
    );
    if (candidates.isEmpty) {
      final (cx, cy) = continentSeed;
      const jitter = 2;
      final jx = (cx + rnd.nextInt(jitter * 2 + 1) - jitter).clamp(
        0,
        params.width - 1,
      );
      final jy = (cy + rnd.nextInt(jitter * 2 + 1) - jitter).clamp(
        0,
        params.height - 1,
      );
      return (jx, jy);
    }
    return _pickBestOrganicSeaCandidate(
      candidates,
      ownLandOrSeed,
      continentGrid,
      params,
      c,
      awayPenalty,
      rnd,
    );
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

  /// Voronoi with no-join: do not assign cell to c if any cell within buffer is land of another continent.
  (List<List<String>>, List<List<int>>) _assignLandByLandSeedsWithNoJoin(
    List<List<String>> grid,
    List<List<int>> continentGrid,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
    String seaZoneId,
    List<int> budgetPerContinent,
  ) {
    if (landSeeds.isEmpty) return (grid, continentGrid);
    final numContinents = budgetPerContinent.length;

    final seedStartByContinent = List<int>.filled(numContinents, 0);
    final seedEndByContinent = List<int>.filled(numContinents, 0);
    _fillLandSeedIndexRangesByContinent(
      continentBySeedIndex,
      numContinents,
      landSeeds.length,
      seedStartByContinent,
      seedEndByContinent,
    );

    final entries = _voronoiLandCellEntries(
      params,
      landSeeds,
      numContinents,
      seedStartByContinent,
      seedEndByContinent,
    );
    entries.sort((a, b) => a.$1.compareTo(b.$1));

    final next = grid.map((row) => row.toList()).toList();
    final nextContinent = continentGrid.map((row) => row.toList()).toList();
    final used = List<int>.filled(numContinents, 0);
    final buffer = params.continentBufferTiles == 0
        ? 1
        : params.continentBufferTiles;
    final offsets = _bufferOffsets(buffer);
    for (final (_, x, y, c) in entries) {
      if (next[y][x] == _landSentinel) continue;
      if (used[c] >= budgetPerContinent[c]) continue;
      if (_wouldJoinOtherContinentInBuffer(
        nextContinent,
        params,
        x,
        y,
        c,
        offsets,
      )) {
        continue;
      }
      next[y][x] = _landSentinel;
      nextContinent[y][x] = c;
      used[c]++;
    }
    return (next, nextContinent);
  }

  /// Attempts one coastal growth step for [continentIndex]. Returns whether a
  /// sea cell was converted to land.
  bool _tryGrowOneCoastalCellForContinent(
    int continentIndex,
    List<List<String>> g,
    List<List<int>> cg,
    String seaZoneId,
    Map<int, List<(int x, int y)>> coastalByContinent,
    List<int> budgetPerContinent,
    List<(int, int)> bufferOffsets,
    int scoreRadius,
    Random rnd,
  ) {
    if (budgetPerContinent[continentIndex] <= 0) return false;
    final coastal = coastalByContinent[continentIndex]!;
    if (coastal.isEmpty) return false;

    var bestScore = kMinLandSeedScoreSentinel;
    final bestCandidates = <(int x, int y)>[];

    for (final (sx, sy) in coastal) {
      if (g[sy][sx] != seaZoneId) continue;

      if (_wouldJoinOtherContinentInBuffer(
        cg,
        params,
        sx,
        sy,
        continentIndex,
        bufferOffsets,
      )) {
        continue;
      }

      final score = _scoreCoastalCellForContinent(
        g,
        cg,
        params,
        sx,
        sy,
        continentIndex,
        scoreRadius,
      );
      if (score < bestScore) continue;
      if (score > bestScore) {
        bestScore = score;
        bestCandidates.clear();
      }
      bestCandidates.add((sx, sy));
    }

    if (bestCandidates.isEmpty) return false;

    final (sx, sy) = bestCandidates[rnd.nextInt(bestCandidates.length)];
    if (g[sy][sx] != seaZoneId) return false;

    g[sy][sx] = _landSentinel;
    cg[sy][sx] = continentIndex;
    budgetPerContinent[continentIndex]--;

    coastalByContinent[continentIndex]!.removeWhere(
      (p) => p.$1 == sx && p.$2 == sy,
    );
    _appendOrthogonalSeaNeighborsToCoastalList(
      params,
      g,
      seaZoneId,
      sx,
      sy,
      coastalByContinent[continentIndex]!,
    );
    return true;
  }

  /// Grow coastlines with a thickness-first heuristic; do not bring land within
  /// buffer of another continent. Preference is given to coastal sea cells that
  /// already have a high density of same-continent land in a local neighborhood
  /// (bays and coves) so they are filled before long, thin tendrils into open
  /// ocean.
  (List<List<String>>, List<List<int>>) _growCoastlines(
    List<List<String>> grid,
    List<List<int>> continentGrid,
    int remaining,
    Map<String, int> provinceToContinent,
    String seaZoneId,
    Random rnd,
  ) {
    if (provinceToContinent.isEmpty) return (grid, continentGrid);
    final numContinents = provinceToContinent.values.toSet().length;
    final provincesByContinent = <int, List<String>>{};
    for (final e in provinceToContinent.entries) {
      provincesByContinent.putIfAbsent(e.value, () => []).add(e.key);
    }
    final totalProvinces = provinceToContinent.length;

    var g = grid.map((row) => row.toList()).toList();
    var cg = continentGrid.map((row) => row.toList()).toList();
    final coastalByContinent = <int, List<(int x, int y)>>{};
    for (var c = 0; c < numContinents; c++) {
      coastalByContinent[c] = [];
    }

    _registerCoastalSeaTilesAdjacentToLand(
      params,
      g,
      cg,
      seaZoneId,
      coastalByContinent,
    );

    final budgetPerContinent = List<int>.filled(numContinents, 0);
    var allocated = 0;
    for (var c = 0; c < numContinents; c++) {
      budgetPerContinent[c] =
          (remaining * provincesByContinent[c]!.length / totalProvinces)
              .round();
      allocated += budgetPerContinent[c];
    }
    if (allocated < remaining && numContinents > 0) {
      budgetPerContinent[0] += remaining - allocated;
    }

    // Radius for local land-neighbour scoring when picking coastal cells.
    const scoreRadius = 3;
    final buffer = params.continentBufferTiles == 0
        ? 1
        : params.continentBufferTiles;
    final bufferOffsets = _bufferOffsets(buffer);

    var added = 0;
    const maxAttempts = 10000;
    var attempts = 0;
    while (added < remaining && attempts < maxAttempts) {
      attempts++;
      var anyProgress = false;

      for (var c = 0; c < numContinents; c++) {
        if (!_tryGrowOneCoastalCellForContinent(
          c,
          g,
          cg,
          seaZoneId,
          coastalByContinent,
          budgetPerContinent,
          bufferOffsets,
          scoreRadius,
          rnd,
        )) {
          continue;
        }
        added++;
        anyProgress = true;
      }

      if (!anyProgress) {
        // No continent could grow further under current constraints; stop.
        break;
      }
    }
    return (g, cg);
  }

  /// Box-Muller transform: returns a standard normal sample.
  double _nextGaussian(Random rnd) {
    var u1 = rnd.nextDouble();
    var u2 = rnd.nextDouble();
    while (u1 <= 0) {
      u1 = rnd.nextDouble();
    }
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }

  /// Per-continent land budget; assign to _landSentinel by smallest effective distance (with optional Voronoi noise). Each cell at most one continent.
  List<List<String>> assignLandByLandSeeds(
    List<List<String>> grid,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
    Map<String, int> provinceToContinent,
    String seaZoneId,
  ) {
    if (landSeeds.isEmpty) return grid;
    final landBudgetTotal =
        ((1 - params.seaFraction) * params.width * params.height).round();
    if (landBudgetTotal <= 0) return grid;

    if (provinceToContinent.isEmpty) return grid;
    final numContinents = provinceToContinent.values.toSet().length;
    final provincesByContinent = <int, List<String>>{};
    for (final e in provinceToContinent.entries) {
      provincesByContinent.putIfAbsent(e.value, () => []).add(e.key);
    }
    final totalProvinces = provinceToContinent.length;
    if (totalProvinces == 0) return grid;

    // Per-continent budget (proportional to province count)
    final budget = List<int>.filled(numContinents, 0);
    var allocated = 0;
    for (var c = 0; c < numContinents; c++) {
      final pc = provincesByContinent[c]!.length;
      budget[c] = (landBudgetTotal * pc / totalProvinces).round();
      allocated += budget[c];
    }
    if (allocated > landBudgetTotal) {
      budget[0] -= (allocated - landBudgetTotal);
    } else if (allocated < landBudgetTotal && numContinents > 0) {
      budget[0] += (landBudgetTotal - allocated);
    }

    // Seeds per continent (index ranges: [start, end) for each c)
    final seedStartByContinent = List<int>.filled(numContinents, 0);
    final seedEndByContinent = List<int>.filled(numContinents, 0);
    _fillLandSeedIndexRangesByContinent(
      continentBySeedIndex,
      numContinents,
      landSeeds.length,
      seedStartByContinent,
      seedEndByContinent,
    );

    final entries = _voronoiLandCellEntries(
      params,
      landSeeds,
      numContinents,
      seedStartByContinent,
      seedEndByContinent,
    );
    entries.sort((a, b) => a.$1.compareTo(b.$1));

    final next = grid.map((row) => row.toList()).toList();
    final used = List<int>.filled(numContinents, 0);
    for (final (_, x, y, c) in entries) {
      if (used[c] < budget[c]) {
        next[y][x] = _landSentinel;
        used[c]++;
      }
    }
    return next;
  }
}
