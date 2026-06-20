/// Pass 4–5, Pass 8–9: lakes, moats, border noise, province seeds and assignment.

part of 'tile_map_generator.dart';

class _TileMapGenLakesProvinces implements MapGenStage {
  _TileMapGenLakesProvinces(this.params, this._graph, this._join);

  @override
  final TileMapParams params;
  final TileMapGridGraph _graph;
  final _TileMapGenJoinSea _join;

  void _addCoastalLandCandidatesAroundLakeCell(
    int x,
    int y,
    List<List<String>> next,
    String seaZoneId,
    Set<(int x, int y)> ocean,
    Set<(int x, int y)> coastalLandCandidates,
  ) {
    for (final (dx, dy) in kTileMapDirections4NorthSouthWestEast) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx >= 0 &&
          nx < params.width &&
          ny >= 0 &&
          ny < params.height &&
          next[ny][nx] == seaZoneId &&
          _graph.oceanNeighbourCount(next, nx, ny, seaZoneId, ocean) >= 1) {
        coastalLandCandidates.add((nx, ny));
      }
    }
  }

  void _tryBorderNoiseSwapAtCell(
    List<List<String>> grid,
    List<List<String>> next,
    int x,
    int y,
    String seaZoneId,
    Random rnd,
  ) {
    if (rnd.nextDouble() >= params.borderNoise) return;
    final id = grid[y][x];
    for (final (dx, dy) in kTileMapDirections4WestEastNorthSouth) {
      final nx = x + dx;
      final ny = y + dy;
      final nid = grid[ny][nx];
      final atBoundary =
          (id == _landSentinel && nid == seaZoneId) ||
          (id == seaZoneId && nid == _landSentinel);
      if (atBoundary) {
        next[ny][nx] = id;
        next[y][x] = nid;
        break;
      }
    }
  }

  /// Fill lakes: convert lake (sea not in ocean) to land; skip lakes that border 2+ continents (straits).
  List<List<String>> fillLakes(
    List<List<String>> grid,
    String seaZoneId,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
  ) {
    final ocean = _graph.oceanCells(
      grid,
      seaZoneId,
      landSeeds,
      continentBySeedIndex,
    );
    final next = snapshotGrid(grid);
    final lakeCells = <(int x, int y)>[];
    TileMapGrid.forEachIndex(params.height, params.width, (y, x) {
      if (grid[y][x] != seaZoneId) return;
      if (ocean.contains((x, y))) return;
      lakeCells.add((x, y));
    });
    final lakeComponents = _graph.connectedComponentsOfLand(lakeCells.toSet());
    var lakesFilled = 0;
    final coastalLandCandidates = <(int x, int y)>{};
    for (final component in lakeComponents) {
      for (final (x, y) in component) {
        next[y][x] = _landSentinel;
        lakesFilled++;
        _addCoastalLandCandidatesAroundLakeCell(
          x,
          y,
          next,
          seaZoneId,
          ocean,
          coastalLandCandidates,
        );
      }
    }
    final sorted = coastalLandCandidates.toList()
      ..sort((a, b) {
        final na = _graph.oceanNeighbourCount(
          next,
          a.$1,
          a.$2,
          seaZoneId,
          ocean,
        );
        final nb = _graph.oceanNeighbourCount(
          next,
          b.$1,
          b.$2,
          seaZoneId,
          ocean,
        );
        return nb.compareTo(na);
      });
    for (final (fx, fy) in sorted.take(lakesFilled)) {
      next[fy][fx] = seaZoneId;
    }
    return next;
  }

  /// Collapse narrow ocean moats: convert ocean cells that are effectively
  /// thin moats around a single continent into land, then preserve overall sea
  /// fraction by converting an equal number of coastal land tiles back to sea.
  ///
  /// A moat candidate is an ocean cell whose 4-neighbourhood contains land
  /// belonging to the **same** continent in at least two directions and no
  /// land from any other continent.
  List<List<String>> fillMoats(
    List<List<String>> grid,
    String seaZoneId,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
    Random rnd,
  ) {
    final ocean = _graph.oceanCells(
      grid,
      seaZoneId,
      landSeeds,
      continentBySeedIndex,
    );
    if (ocean.isEmpty) return grid;

    final next = snapshotGrid(grid);
    final moatCells = <(int x, int y)>[];

    TileMapGrid.forEachIndex(params.height, params.width, (y, x) {
      if (next[y][x] != seaZoneId) return;
      if (!ocean.contains((x, y))) return;

      // Examine 4-neighbourhood for bordering land.
      final neighbouringContinents = <int>{};
      final sameContinentDirectionCounts = <int, int>{};

      for (final (dx, dy) in kTileMapDirections4) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
          continue;
        }
        if (next[ny][nx] == seaZoneId) continue;
        final continent = _graph.continentForLandCell(
          nx,
          ny,
          landSeeds,
          continentBySeedIndex,
        );
        neighbouringContinents.add(continent);
        sameContinentDirectionCounts[continent] =
            (sameContinentDirectionCounts[continent] ?? 0) + 1;
      }

      if (neighbouringContinents.isEmpty) return;
      if (neighbouringContinents.length > 1) {
        return; // multi-continent strait, keep as sea
      }

      final c = neighbouringContinents.single;
      final dirCount = sameContinentDirectionCounts[c] ?? 0;
      if (dirCount < 2) return; // not strongly enclosed by that continent

      moatCells.add((x, y));
    });

    if (moatCells.isEmpty) return grid;

    for (final (x, y) in moatCells) {
      next[y][x] = _landSentinel;
    }

    // Preserve overall sea fraction by converting an equal number of coastal
    // land tiles back to sea, using the existing helper.
    _join.preserveSeaFraction(
      next,
      null,
      null,
      seaZoneId,
      ocean,
      moatCells.length,
    );

    return next;
  }

  /// Land cells grouped by continent (nearest land seed → continent via continentBySeedIndex).
  Map<int, List<(int x, int y)>> _landCellsByContinent(
    List<List<String>> grid,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
  ) {
    final numContinents = continentBySeedIndex.isEmpty
        ? 0
        : continentBySeedIndex.reduce((a, b) => a > b ? a : b) + 1;
    final byContinent = <int, List<(int x, int y)>>{
      for (var c = 0; c < numContinents; c++) c: [],
    };
    TileMapGrid.forEachIndex(params.height, params.width, (y, x) {
      if (grid[y][x] != _landSentinel) return;
      final bestSeedIndex = _graph.nearestLandSeedIndexForCell(x, y, landSeeds);
      final c = continentBySeedIndex[bestSeedIndex];
      byContinent[c]!.add((x, y));
    });
    return byContinent;
  }

  /// Place one province seed per province on that continent's land cells; min spacing.
  Map<String, (int x, int y)> placeProvinceSeedsOnLand(
    List<List<String>> grid,
    Map<String, int> provinceToContinent,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
    String seaZoneId,
    Random rnd,
  ) {
    if (provinceToContinent.isEmpty) return {};
    final numContinents = provinceToContinent.values.toSet().length;
    final byContinent = _landCellsByContinent(
      grid,
      landSeeds,
      continentBySeedIndex,
    );
    final seeds = <String, (int x, int y)>{};
    const minDist = 3;
    for (var c = 0; c < numContinents; c++) {
      final cells = byContinent[c] ?? [];
      if (cells.isEmpty) continue;
      final provinceIds =
          provinceToContinent.entries
              .where((e) => e.value == c)
              .map((e) => e.key)
              .toList()
            ..sort();
      final used = <(int x, int y)>{};
      for (final provinceId in provinceIds) {
        final shuffled = List<(int x, int y)>.from(cells)..shuffle(rnd);
        for (final (x, y) in shuffled) {
          if (used.any(
            (p) => (p.$1 - x).abs() < minDist && (p.$2 - y).abs() < minDist,
          )) {
            continue;
          }
          seeds[provinceId] = (x, y);
          used.add((x, y));
          break;
        }
        if (!seeds.containsKey(provinceId) && cells.isNotEmpty) {
          final (x, y) = cells[rnd.nextInt(cells.length)];
          seeds[provinceId] = (x, y);
          used.add((x, y));
        }
      }
    }
    return seeds;
  }

  /// Replace each _landSentinel cell with nearest province seed id. Uses generic Voronoi.
  List<List<String>> assignProvincesFromSeeds(
    List<List<String>> grid,
    Map<String, (int x, int y)> provinceSeeds,
    String seaZoneId,
  ) {
    if (provinceSeeds.isEmpty) return grid;
    final landCells = <(int x, int y)>[];
    TileMapGrid.forEachCell(grid, (y, x, value) {
      if (value == _landSentinel) landCells.add((x, y));
    });
    final assignment = assignCellsToNearestSeed(
      landCells,
      provinceSeeds,
      noiseScale: 0,
      noiseSeed: params.seed,
    );
    final next = snapshotGrid(grid);
    for (final entry in assignment.entries) {
      final (x, y) = entry.key;
      next[y][x] = entry.value;
    }
    return next;
  }

  /// Border noise: swap only at land/sea boundary (sentinel vs seaZoneId).
  List<List<String>> borderNoise(
    List<List<String>> grid,
    String seaZoneId,
    Random rnd,
  ) {
    final next = snapshotGrid(grid);
    // ct-lint-allow: nested-grid-walk — bordered interior walk (skips the grid
    // edge, y/x in 1..n-2), so the full-grid TileMapGrid.forEachIndex contract
    // does not apply.
    for (var y = 1; y < params.height - 1; y++) {
      for (var x = 1; x < params.width - 1; x++) {
        _tryBorderNoiseSwapAtCell(grid, next, x, y, seaZoneId, rnd);
      }
    }
    return next;
  }
}
