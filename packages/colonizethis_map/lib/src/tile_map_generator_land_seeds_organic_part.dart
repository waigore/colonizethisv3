// Organic land-growing helpers for [TileMapGenLandSeeds]:
// - Candidate selection over close sea cells (`_organicSeedCloseSeaCandidates`,
//   `_pickBestOrganicSeaCandidate`, distance helpers).
// - Per-round placement of one organic land seed (`_placeOneOrganicSeed`).
// - Voronoi-with-no-join assignment (`_assignLandByLandSeedsWithNoJoin`).
// - Top-level interleaved placement / Voronoi / coastline-growth driver
//   (`_placeLandSeedsOrganicImpl`).
part of 'tile_map_generator_land_seeds.dart';

List<(int x, int y)> _organicSeedCloseSeaCandidates(
  TileMapLandSeedParams params,
  List<List<String>> grid,
  String seaZoneId,
  int closeRadius,
  List<List<int>> minDistToOwnLand,
) {
  final candidates = <(int x, int y)>[];
  for (var y = 0; y < params.height; y++) {
    for (var x = 0; x < params.width; x++) {
      if (grid[y][x] != seaZoneId) continue;
      final minDistToOwn = minDistToOwnLand[y][x];
      if (minDistToOwn > closeRadius) continue;
      candidates.add((x, y));
    }
  }
  return candidates;
}

(int, int) _pickBestOrganicSeaCandidate(
  List<(int x, int y)> candidates,
  List<List<int>> minDistToOwnLand,
  List<List<int>> distToOtherContinent,
  double awayPenalty,
  Random rnd,
) {
  var bestScore = -1e100;
  final bestCandidates = <(int x, int y)>[];
  for (final (x, y) in candidates) {
    final minDistToOwn = minDistToOwnLand[y][x];
    final minDistToOther = distToOtherContinent[y][x];
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

/// Place one land seed near existing land of continent c, preferably away from others.
(int, int) _placeOneOrganicSeed(
  TileMapLandSeedParams params,
  List<List<String>> grid,
  List<List<int>> distToOtherContinent,
  (int x, int y) continentSeed,
  List<(int x, int y)> existingLandSeeds,
  List<int> continentBySeedIndex,
  int c,
  int closeRadius,
  double awayPenalty,
  String seaZoneId,
  Random rnd,
) {
  final ownLandOrSeed = <(int x, int y)>[continentSeed];
  for (var i = 0; i < existingLandSeeds.length; i++) {
    if (continentBySeedIndex[i] == c) {
      ownLandOrSeed.add(existingLandSeeds[i]);
    }
  }
  final minDistToOwnLand = manhattanDistToNearestPoints(
    params.width,
    params.height,
    ownLandOrSeed,
    distanceWhenNoSources: 1 << 30,
  );
  final candidates = _organicSeedCloseSeaCandidates(
    params,
    grid,
    seaZoneId,
    closeRadius,
    minDistToOwnLand,
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
    minDistToOwnLand,
    distToOtherContinent,
    awayPenalty,
    rnd,
  );
}

/// Voronoi with no-join: do not assign cell to c if any cell within buffer is land of another continent.
(List<List<String>>, List<List<int>>) _assignLandByLandSeedsWithNoJoin(
  TileMapLandSeedParams params,
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

  final next = TileMapGrid.copy(grid);
  final nextContinent = TileMapGrid.copy(continentGrid);
  final used = List<int>.filled(numContinents, 0);
  final buffer = params.continentBufferTiles == 0
      ? 1
      : params.continentBufferTiles;
  final offsets = _bufferOffsets(buffer);
  for (final (_, x, y, c) in entries) {
    if (next[y][x] == kTileMapLandSentinel) continue;
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
    next[y][x] = kTileMapLandSentinel;
    nextContinent[y][x] = c;
    used[c]++;
  }
  return (next, nextContinent);
}

/// Organic land growing: interleaved seed placement + small Voronoi + coastline growth.
/// Returns (continentSeeds, landSeeds, continentBySeedIndex, grid).
(List<(int x, int y)>, List<(int x, int y)>, List<int>, List<List<String>>)
_placeLandSeedsOrganicImpl(
  TileMapLandSeedParams params,
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
  var g = TileMapGrid.copy(grid);
  var continentGrid = TileMapGrid.filled(params.height, params.width, -1);

  const closeRadius = 5;
  const awayPenalty = 0.7;

  // Per-round land budget: reserve totalSeeds for seed positions, rest for Voronoi
  final voronoiBudgetTotal = (landBudgetTotal - totalSeeds).clamp(
    0,
    landBudgetTotal,
  );
  final seedCountsPerContinent = List<int>.filled(numContinents, 0);
  var voronoiRemaining = voronoiBudgetTotal;

  for (var round = 0; round < totalRounds; round++) {
    final roundBudget = (round + 1 == totalRounds)
        ? voronoiRemaining
        : (voronoiBudgetTotal / totalRounds).round();
    final budgetPerContinent = allocateBudgetByProvinceCount(
      totalBudget: roundBudget,
      provincesByContinent: provincesByContinent,
      numContinents: numContinents,
    );
    voronoiRemaining -= roundBudget;
    final distToOtherByContinent = manhattanDistToOtherContinentsMaps(
      continentGrid: continentGrid,
      width: params.width,
      height: params.height,
      numContinents: numContinents,
    );
    // Step 1: Place one land seed per continent (if needed)
    for (var c = 0; c < numContinents; c++) {
      if (seedCountsPerContinent[c] >= seedsPerContinent[c]) continue;
      final (sx, sy) = _placeOneOrganicSeed(
        params,
        g,
        distToOtherByContinent[c],
        continentSeeds[c],
        landSeeds,
        continentBySeedIndex,
        c,
        closeRadius,
        awayPenalty,
        seaZoneId,
        rnd,
      );
      if (sx >= 0 && sy >= 0) {
        landSeeds.add((sx, sy));
        continentBySeedIndex.add(c);
        seedCountsPerContinent[c]++;
        g[sy][sx] = kTileMapLandSentinel;
        continentGrid[sy][sx] = c;
      }
    }

    // Step 2: Small Voronoi with no-join (use round's budgetPerContinent)
    final voronoiResult = _assignLandByLandSeedsWithNoJoin(
      params,
      g,
      continentGrid,
      landSeeds,
      continentBySeedIndex,
      seaZoneId,
      budgetPerContinent,
    );
    g = voronoiResult.$1;
    // [_assignLandByLandSeedsWithNoJoin] already returns a fresh continent grid;
    // adopt it instead of copying cell-by-cell into the prior buffer (Refs #2489).
    continentGrid = voronoiResult.$2;
  }

  // Step 3: Coastline growth if budget remains
  var usedTotal = 0;
  for (var y = 0; y < params.height; y++) {
    for (var x = 0; x < params.width; x++) {
      if (g[y][x] == kTileMapLandSentinel) usedTotal++;
    }
  }
  if (usedTotal < landBudgetTotal) {
    final remaining = landBudgetTotal - usedTotal;
    final (g2, _) = _growCoastlines(
      params,
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
