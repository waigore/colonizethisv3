// Coastline-growth helpers for [TileMapGenLandSeeds]:
// - Coastal tile registration / sea-neighbor expansion.
// - Local-density scoring used when picking which coastal sea cell to convert.
// - Per-continent single-step growth (`_tryGrowOneCoastalCellForContinent`).
// - Top-level thickness-first coastline growth (`_growCoastlines`) called
//   from the organic placement pass when land budget remains.
part of 'tile_map_generator_land_seeds.dart';

void _appendOrthogonalSeaNeighborsToCoastalList(
  TileMapLandSeedParams params,
  List<List<String>> g,
  String seaZoneId,
  int sx,
  int sy,
  List<(int x, int y)> coastalList,
) {
  for (final (dx, dy) in kTileMapDirections4NorthSouthWestEast) {
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
  for (final (dx, dy) in kTileMapDirections4NorthSouthWestEast) {
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
      if (g[y][x] != kTileMapLandSentinel) continue;
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
  if (g[ny][nx] != kTileMapLandSentinel) return 0;
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

/// Attempts one coastal growth step for [continentIndex]. Returns whether a
/// sea cell was converted to land.
bool _tryGrowOneCoastalCellForContinent(
  TileMapLandSeedParams params,
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

  g[sy][sx] = kTileMapLandSentinel;
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
  TileMapLandSeedParams params,
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

  var g = TileMapGrid.copy(grid);
  var cg = TileMapGrid.copy(continentGrid);
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

  final budgetPerContinent = allocateBudgetByProvinceCount(
    totalBudget: remaining,
    provincesByContinent: provincesByContinent,
    numContinents: numContinents,
  );

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
        params,
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
