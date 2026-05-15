part of 'tile_map_generator.dart';

extension _TileMapGenJoinSeaBridgePart on _TileMapGenJoinSea {
  /// Join step: for each continent with >1 land component, connect two by a shortest path of sea cells. Returns (grid, terrainGrid, resourceGrid, didJoin).
  (List<List<String>>, List<List<TerrainType?>>?, List<List<Resource?>>?, bool)
  joinContinents(
    List<List<String>> grid,
    List<List<TerrainType?>>? terrainGrid,
    List<List<Resource?>>? resourceGrid,
    Map<String, int> provinceToContinent,
    String seaZoneId,
    String? mapRegionId,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
    ResourceRules? resourceRules,
    Random rnd,
  ) {
    if (provinceToContinent.isEmpty) {
      return (grid, terrainGrid, resourceGrid, false);
    }
    final numContinents = provinceToContinent.values.toSet().length;
    var didJoin = false;
    var g = copyTileMapGrid(grid);
    var tg = terrainGrid != null ? copyTileMapGrid(terrainGrid) : null;
    var rg = resourceGrid != null ? copyTileMapGrid(resourceGrid) : null;
    final ocean = _graph.oceanCells(
      g,
      seaZoneId,
      landSeeds,
      continentBySeedIndex,
    );
    final maxJoinIterationsPerContinent = params.width * params.height;

    final capState =
        (tg != null &&
            rg != null &&
            mapRegionId != null &&
            resourceRules != null &&
            (mapRegionId == 'oldWorld' || mapRegionId == 'newWorld'))
        ? MultiRegionCapState.fromExisting(
            params.multiRegionResourceCapFraction,
            resourceRules,
            mapRegionId,
            rg,
          )
        : null;

    for (var c = 0; c < numContinents; c++) {
      var landCells = _landCellsForContinent(
        g,
        provinceToContinent,
        c,
        seaZoneId,
      );
      var joinIterations = 0;
      while (joinIterations < maxJoinIterationsPerContinent) {
        joinIterations++;
        final components = _graph.connectedComponentsOfLand(landCells);
        if (components.length <= 1) break;
        didJoin = true;
        final compA = components[0];
        final compB = components[1];
        final path = _shortestSeaPath(g, seaZoneId, compA, compB);
        if (path.isEmpty) break;
        final provinceId = _provinceIdAdjacentToSeaPath(g, compA, path);
        final bridgeCells = path.toSet();
        _applyBridgePathCells(
          g,
          path,
          provinceId,
          tg,
          rg,
          mapRegionId,
          resourceRules,
          rnd,
          capState,
        );
        for (final p in path) {
          landCells.add(p);
        }
        final restoredToSea = preserveSeaFraction(
          g,
          tg,
          rg,
          seaZoneId,
          ocean,
          path.length,
          landCellsExcludedFromSeaRestore: bridgeCells,
        );
        for (final p in restoredToSea) {
          landCells.remove(p);
        }
      }
      if (joinIterations >= maxJoinIterationsPerContinent) {
        // [landCells] is kept in sync with the grid across bridge / sea-restore;
        // avoid a redundant O(W×H) rescan for the diagnostic path (Refs #2489 P4).
        final stillSplit = _graph.connectedComponentsOfLand(landCells);
        if (stillSplit.length > 1) {
          _log.w(
            'join continents hit iteration cap with >1 land component for '
            'continent index $c (width=${params.width} height=${params.height})',
          );
        }
      }
    }
    return (g, tg, rg, didJoin);
  }

  int countSeaCells(List<List<String>> grid, String seaZoneId) =>
      _graph.countSeaCells(grid, seaZoneId);

  void _applyBridgePathCells(
    List<List<String>> g,
    List<(int x, int y)> path,
    String provinceId,
    List<List<TerrainType?>>? tg,
    List<List<Resource?>>? rg,
    String? mapRegionId,
    ResourceRules? resourceRules,
    Random rnd,
    MultiRegionCapState? capState,
  ) {
    for (final (x, y) in path) {
      g[y][x] = provinceId;
      if (tg != null &&
          rg != null &&
          mapRegionId != null &&
          resourceRules != null) {
        _assignTerrainAndResourceForCell(
          tg,
          rg,
          x,
          y,
          mapRegionId,
          resourceRules,
          rnd,
          capState: capState,
        );
      }
    }
  }

  Set<(int x, int y)> _landCellsForContinent(
    List<List<String>> grid,
    Map<String, int> membership,
    int continentIndex,
    String seaZoneId,
  ) {
    final out = <(int x, int y)>{};
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        final id = grid[y][x];
        if (id == seaZoneId) continue;
        if (membership[id] == continentIndex) out.add((x, y));
      }
    }
    return out;
  }

  List<(int x, int y)> _shortestSeaPath(
    List<List<String>> grid,
    String seaZoneId,
    Set<(int x, int y)> compA,
    Set<(int x, int y)> compB,
  ) {
    final seaAdjacentToA = <(int x, int y)>{};
    for (final (x, y) in compA) {
      for (final (dx, dy) in kTileMapDirections4NorthSouthWestEast) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx >= 0 &&
            nx < params.width &&
            ny >= 0 &&
            ny < params.height &&
            grid[ny][nx] == seaZoneId) {
          seaAdjacentToA.add((nx, ny));
        }
      }
    }
    final seaAdjacentToB = <(int x, int y)>{};
    for (final (x, y) in compB) {
      for (final (dx, dy) in kTileMapDirections4NorthSouthWestEast) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx >= 0 &&
            nx < params.width &&
            ny >= 0 &&
            ny < params.height &&
            grid[ny][nx] == seaZoneId) {
          seaAdjacentToB.add((nx, ny));
        }
      }
    }
    if (seaAdjacentToA.isEmpty || seaAdjacentToB.isEmpty) return [];
    final prev = <(int x, int y), (int x, int y)?>{};
    final queue = <(int x, int y)>[];
    for (final p in seaAdjacentToA) {
      prev[p] = null;
      queue.add(p);
    }
    (int x, int y)? goal;
    while (queue.isNotEmpty && goal == null) {
      final (x, y) = queue.removeAt(0);
      if (seaAdjacentToB.contains((x, y))) {
        goal = (x, y);
        break;
      }
      for (final (dx, dy) in kTileMapDirections4NorthSouthWestEast) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
          continue;
        }
        if (grid[ny][nx] != seaZoneId) continue;
        final next = (nx, ny);
        if (prev.containsKey(next)) continue;
        prev[next] = (x, y);
        queue.add(next);
      }
    }
    if (goal == null) return [];
    final path = <(int x, int y)>[];
    (int x, int y)? cur = goal;
    while (cur != null) {
      path.add(cur);
      cur = prev[cur];
    }
    return path.reversed.toList();
  }

  String _provinceIdAdjacentToSeaPath(
    List<List<String>> grid,
    Set<(int x, int y)> compA,
    List<(int x, int y)> path,
  ) {
    for (final (px, py) in path) {
      for (final (dx, dy) in kTileMapDirections4NorthSouthWestEast) {
        final nx = px + dx;
        final ny = py + dy;
        if (nx >= 0 &&
            nx < params.width &&
            ny >= 0 &&
            ny < params.height &&
            compA.contains((nx, ny))) {
          return grid[ny][nx];
        }
      }
    }
    final anyInA = compA.first;
    return grid[anyInA.$2][anyInA.$1];
  }

  void _assignTerrainAndResourceForCell(
    List<List<TerrainType?>> terrainGrid,
    List<List<Resource?>> resourceGrid,
    int x,
    int y,
    String mapRegionId,
    ResourceRules rules,
    Random rnd, {
    MultiRegionCapState? capState,
  }) {
    final landTerrains = allowedTerrainsForRegion(mapRegionId);
    if (landTerrains.isEmpty) return;
    terrainGrid[y][x] = landTerrains[rnd.nextInt(landTerrains.length)];
    tryPlaceWeightedResourceAtCell(
      resourceGrid: resourceGrid,
      x: x,
      y: y,
      terrain: terrainGrid[y][x]!,
      mapRegionId: mapRegionId,
      rules: rules,
      rnd: rnd,
      capState: capState,
    );
  }

  List<(int x, int y)> preserveSeaFraction(
    List<List<String>> grid,
    List<List<TerrainType?>>? terrainGrid,
    List<List<Resource?>>? resourceGrid,
    String seaZoneId,
    Set<(int x, int y)> ocean,
    int count, {
    Set<(int x, int y)>? landCellsExcludedFromSeaRestore,
  }) {
    final coastal = <(int x, int y)>[];
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] == seaZoneId) continue;
        if (landCellsExcludedFromSeaRestore?.contains((x, y)) ?? false) {
          continue;
        }
        if (_graph.oceanNeighbourCount(grid, x, y, seaZoneId, ocean) >= 1) {
          coastal.add((x, y));
        }
      }
    }
    coastal.sort((a, b) {
      final na = _graph.oceanNeighbourCount(grid, a.$1, a.$2, seaZoneId, ocean);
      final nb = _graph.oceanNeighbourCount(grid, b.$1, b.$2, seaZoneId, ocean);
      return nb.compareTo(na);
    });
    final restoredToSea = <(int x, int y)>[];
    for (var i = 0; i < count && i < coastal.length; i++) {
      final (x, y) = coastal[i];
      grid[y][x] = seaZoneId;
      if (terrainGrid != null) terrainGrid[y][x] = null;
      if (resourceGrid != null) resourceGrid[y][x] = null;
      restoredToSea.add((x, y));
    }
    return restoredToSea;
  }
}
