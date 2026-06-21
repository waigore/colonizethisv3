/// Grid and connectivity helpers shared by tile map generation passes.
/// SPEC/program/tile-map-gen-algorithm.md

import '../tile_map_directions.dart';
import 'tile_map_distance_sentinels.dart';
import 'tile_map_land_seed_contract.dart';

class TileMapGridGraph {
  TileMapGridGraph(this.params);

  final TileMapLandSeedParams params;

  List<Set<(int x, int y)>> connectedComponentsOfLand(
    Set<(int x, int y)> landCells,
  ) {
    if (landCells.isEmpty) return [];
    final result = <Set<(int x, int y)>>[];
    final remaining = Set<(int x, int y)>.from(landCells);
    while (remaining.isNotEmpty) {
      final start = remaining.first;
      remaining.remove(start);
      final component = <(int x, int y)>{start};
      final queue = <(int x, int y)>[start];
      while (queue.isNotEmpty) {
        final (x, y) = queue.removeLast();
        _expandLandComponentNeighbors(x, y, remaining, component, queue);
      }
      result.add(component);
    }
    return result;
  }

  /// Pass 11: 4-connected components of sea cells (grid cells with seaZoneId).
  List<Set<(int x, int y)>> connectedComponentsOfSea(
    List<List<String>> grid,
    String seaZoneId,
  ) {
    final seaCells = <(int x, int y)>{};
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] == seaZoneId) seaCells.add((x, y));
      }
    }
    return connectedComponentsOfLand(seaCells);
  }

  (int, int) minYx(Set<(int x, int y)> cells) {
    var minY = params.height;
    var minX = params.width;
    for (final (x, y) in cells) {
      if (y < minY || (y == minY && x < minX)) {
        minY = y;
        minX = x;
      }
    }
    return (minY, minX);
  }

  int countSeaCells(List<List<String>> grid, String seaZoneId) {
    var n = 0;
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] == seaZoneId) n++;
      }
    }
    return n;
  }

  /// Sea cells 4-reachable from **any** grid-edge sea cell (legacy Pass-4 ocean mask).
  /// Used only to avoid treating the **main exterior ocean** as a fillable lake when
  /// **|S| = 1** for a single-continent map (see SPEC/program/tile-map-gen-algorithm.md § Pass 4).
  Set<(int x, int y)> _legacyBoundaryReachableSea(
    List<List<String>> grid,
    String seaZoneId,
  ) {
    final ocean = <(int x, int y)>{};
    final queue = <(int x, int y)>[];
    for (var x = 0; x < params.width; x++) {
      if (grid[0][x] == seaZoneId) {
        ocean.add((x, 0));
        queue.add((x, 0));
      }
      if (params.height > 1 && grid[params.height - 1][x] == seaZoneId) {
        ocean.add((x, params.height - 1));
        queue.add((x, params.height - 1));
      }
    }
    for (var y = 0; y < params.height; y++) {
      if (grid[y][0] == seaZoneId && !ocean.contains((0, y))) {
        ocean.add((0, y));
        queue.add((0, y));
      }
      if (params.width > 1 &&
          grid[y][params.width - 1] == seaZoneId &&
          !ocean.contains((params.width - 1, y))) {
        ocean.add((params.width - 1, y));
        queue.add((params.width - 1, y));
      }
    }
    while (queue.isNotEmpty) {
      final (x, y) = queue.removeLast();
      for (final (dx, dy) in kTileMapDirections4WestEastNorthSouth) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx >= 0 &&
            nx < params.width &&
            ny >= 0 &&
            ny < params.height &&
            grid[ny][nx] == seaZoneId &&
            !ocean.contains((nx, ny))) {
          ocean.add((nx, ny));
          queue.add((nx, ny));
        }
      }
    }
    return ocean;
  }

  /// Pass 4 / moats / join sea-fraction: **ocean** among sea cells is the complement
  /// of **fillable lake** sea components (see SPEC/program/tile-map-gen-algorithm.md § Pass 4).
  ///
  /// Partition sea into 4-connected components. For each component **C**, let **S** be
  /// the set of continent ids from [continentForLandCell] for every **in-grid** cardinal
  /// neighbor of cells in **C** that is **land** (not `seaZoneId`). Out-of-bounds
  /// neighbors contribute nothing. If **|S| = 1**, **C** is a **candidate** fillable lake.
  /// Let **G** = sea components with **|S| = 1** that intersect **legacy** boundary-reachable
  /// sea (4-flood from map edge through sea). **Exclusion** (treat as non-fillable ocean):
  /// if **|G| ≥ 2**, exclude the **largest** component in **G** (tie: lexicographic min of
  /// `(y,x)` from [minYx]). If **|G| = 1** with component **C**, exclude **C** only when
  /// **total sea** cell count is at least [kPass4DominantOceanMinTotalSea] **and**
  /// **|C| × 100 ≥ totalSea × kPass4DominantOceanPercentNumerator** (dominant exterior ocean
  /// on normal-sized maps). Otherwise **C** remains fillable (small grids / rim bays that
  /// are all the sea). All **|S| = 1** sea components disjoint from legacy boundary sea
  /// remain fillable. **Ocean** = all sea cells not in any fillable-lake component. If
  /// **|S| ≥ 2** or **|S| = 0**, **C** is ocean (not filled as a single-continent lake).
  Set<(int x, int y)> oceanCells(
    List<List<String>> grid,
    String seaZoneId,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
  ) {
    // Below this total sea count, a lone |S|=1 edge-touching component is still
    // fillable (small grids / tests); at or above it, treat a dominant lone
    // component as exterior ocean when it occupies most sea cells.
    const dominantOceanMinTotalSea = 48;
    const dominantOceanPercentNumerator = 80;
    final legacyOcean = _legacyBoundaryReachableSea(grid, seaZoneId);
    final components = connectedComponentsOfSea(grid, seaZoneId);
    // One full-grid sea pass via [connectedComponentsOfSea]; avoid a second
    // [countSeaCells] scan (Refs #2489).
    final totalSea = components.fold<int>(0, (sum, c) => sum + c.length);
    // One continent-set computation per sea component (Refs #2489 P1); both passes
    // below reuse this cache instead of calling [_continentSetForSeaComponent]
    // twice per component.
    final continentSets = List<Set<int>>.generate(components.length, (i) {
      return _continentSetForSeaComponent(
        grid,
        seaZoneId,
        components[i],
        landSeeds,
        continentBySeedIndex,
      );
    });
    final touchLegacyFillable = <Set<(int x, int y)>>[];
    for (var i = 0; i < components.length; i++) {
      final component = components[i];
      final continentSet = continentSets[i];
      if (continentSet.length != 1) continue;
      if (!component.any((p) => legacyOcean.contains(p))) continue;
      touchLegacyFillable.add(component);
    }

    Set<(int x, int y)>? excludedMainOcean;
    if (touchLegacyFillable.length >= 2) {
      excludedMainOcean = touchLegacyFillable.reduce((a, b) {
        if (a.length > b.length) return a;
        if (b.length > a.length) return b;
        final (ay, ax) = minYx(a);
        final (by, bx) = minYx(b);
        if (ay != by) return ay < by ? a : b;
        return ax <= bx ? a : b;
      });
    } else if (touchLegacyFillable.length == 1) {
      final c = touchLegacyFillable.single;
      if (totalSea >= dominantOceanMinTotalSea &&
          c.length * 100 >= totalSea * dominantOceanPercentNumerator) {
        excludedMainOcean = c;
      }
    }

    final fillableLake = <(int x, int y)>{};
    for (var i = 0; i < components.length; i++) {
      final component = components[i];
      final continentSet = continentSets[i];
      if (continentSet.length != 1) continue;
      if (excludedMainOcean != null &&
          component.length == excludedMainOcean.length &&
          component.containsAll(excludedMainOcean)) {
        continue;
      }
      fillableLake.addAll(component);
    }
    final ocean = <(int x, int y)>{};
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] == seaZoneId && !fillableLake.contains((x, y))) {
          ocean.add((x, y));
        }
      }
    }
    return ocean;
  }

  Set<int> _continentSetForSeaComponent(
    List<List<String>> grid,
    String seaZoneId,
    Set<(int x, int y)> component,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
  ) {
    final continentSet = <int>{};
    for (final (x, y) in component) {
      for (final (dx, dy) in kTileMapDirections4NorthSouthWestEast) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
          continue;
        }
        if (grid[ny][nx] == seaZoneId) continue;
        continentSet.add(
          continentForLandCell(nx, ny, landSeeds, continentBySeedIndex),
        );
      }
    }
    return continentSet;
  }

  /// Index of the land seed with smallest squared distance to (x, y).
  ///
  /// Returns 0 when [landSeeds] is empty. Refs #2489.
  int nearestLandSeedIndexForCell(
    int x,
    int y,
    List<(int x, int y)> landSeeds,
  ) {
    if (landSeeds.isEmpty) return 0;
    var bestSeedIndex = 0;
    var bestD2 = kUnsetSquaredDistanceInt31;
    for (var i = 0; i < landSeeds.length; i++) {
      final (sx, sy) = landSeeds[i];
      final d2 = (x - sx) * (x - sx) + (y - sy) * (y - sy);
      if (d2 < bestD2) {
        bestD2 = d2;
        bestSeedIndex = i;
      }
    }
    return bestSeedIndex;
  }

  /// Continent index for a land cell from nearest land seed. Returns 0 when seeds empty.
  int continentForLandCell(
    int x,
    int y,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
  ) {
    if (landSeeds.isEmpty) return 0;
    return continentBySeedIndex[
      nearestLandSeedIndexForCell(x, y, landSeeds)
    ];
  }

  int oceanNeighbourCount(
    List<List<String>> grid,
    int x,
    int y,
    String seaZoneId,
    Set<(int x, int y)> ocean,
  ) {
    var n = 0;
    for (final (dx, dy) in kTileMapDirections4NorthSouthWestEast) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx >= 0 &&
          nx < params.width &&
          ny >= 0 &&
          ny < params.height &&
          grid[ny][nx] == seaZoneId &&
          ocean.contains((nx, ny))) {
        n++;
      }
    }
    return n;
  }

  void _expandLandComponentNeighbors(
    int x,
    int y,
    Set<(int x, int y)> remaining,
    Set<(int x, int y)> component,
    List<(int x, int y)> queue,
  ) {
    for (final (dx, dy) in kTileMapDirections4NorthSouthWestEast) {
      final n = (x + dx, y + dy);
      if (!remaining.remove(n)) continue;
      component.add(n);
      queue.add(n);
    }
  }
}
