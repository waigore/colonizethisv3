// Land-seed placement helpers for [TileMapGenLandSeeds]:
// - `_placeLandSeedsImpl` lays down per-continent seed clusters
//   (Pass 2: continent seed + K shaped land-shape seeds per continent).
// - `_assignLandByLandSeedsImpl` performs the final non-organic Voronoi
//   land-budget assignment used by the seed-before-assignment path.
// - `_nextGaussian` is a Box–Muller helper for the Gaussian cluster shape.
part of 'tile_map_generator_land_seeds.dart';

/// One continent seed per continent; then a cluster of land-shape seeds per
/// continent (K from province count). No province seeds yet.
(List<(int x, int y)>, List<(int x, int y)>, List<int>) _placeLandSeedsImpl(
  TileMapLandSeedParams params,
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

/// Box-Muller transform: returns a standard normal sample.
double _nextGaussian(Random rnd) {
  var u1 = rnd.nextDouble();
  var u2 = rnd.nextDouble();
  while (u1 <= 0) {
    u1 = rnd.nextDouble();
  }
  return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
}

/// Per-continent land budget; assign to `_landSentinel` by smallest effective
/// distance (with optional Voronoi noise). Each cell at most one continent.
List<List<String>> _assignLandByLandSeedsImpl(
  TileMapLandSeedParams params,
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

  final budget = allocateBudgetByProvinceCount(
    totalBudget: landBudgetTotal,
    provincesByContinent: provincesByContinent,
    numContinents: numContinents,
  );

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

  final next = copyTileMapGrid(grid);
  final used = List<int>.filled(numContinents, 0);
  for (final (_, x, y, c) in entries) {
    if (used[c] < budget[c]) {
      next[y][x] = _landSentinel;
      used[c]++;
    }
  }
  return next;
}
