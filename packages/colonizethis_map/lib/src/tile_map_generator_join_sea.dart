part of 'tile_map_generator.dart';

/// Pass 10–11: join continents, terrain jitter, sea subdivision.
class _TileMapGenJoinSea {
  _TileMapGenJoinSea(this.params, this._log, this._graph);

  final TileMapParams params;
  final CtLogger _log;
  final TileMapGridGraph _graph;

  void jitterTerrainByProvince(
    List<List<String>> grid,
    List<List<TerrainType?>> terrainGrid,
    List<List<Resource?>> resourceGrid,
    String regionId,
    Random rnd,
  ) {
    final allowedNonMountain = allowedTerrainsForRegion(
      regionId,
    ).where((t) => t != TerrainType.mountain).toList();
    if (allowedNonMountain.isEmpty) return;

    final height = grid.length;
    if (height == 0) return;
    final width = grid[0].length;

    // Build province -> tiles mapping.
    final tilesByProvince = <String, List<(int x, int y)>>{};
    final provinceIdPattern = RegExp(r'^p\d+$');
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final id = grid[y][x];
        if (!provinceIdPattern.hasMatch(id)) continue;
        tilesByProvince.putIfAbsent(id, () => []).add((x, y));
      }
    }
    if (tilesByProvince.isEmpty) return;

    const directions4 = <(int dx, int dy)>[(0, -1), (1, 0), (0, 1), (-1, 0)];
    const directions8 = <(int dx, int dy)>[
      (0, -1),
      (1, 0),
      (0, 1),
      (-1, 0),
      (-1, -1),
      (1, -1),
      (1, 1),
      (-1, 1),
    ];

    for (final entry in tilesByProvince.entries) {
      final tiles = entry.value;
      if (tiles.length < params.jitterMinProvinceSize) continue;

      // Terrain histogram.
      final counts = <TerrainType, int>{};
      var terrainTiles = 0;
      for (final (x, y) in tiles) {
        final t = terrainGrid[y][x];
        if (t == null) continue;
        counts[t] = (counts[t] ?? 0) + 1;
        terrainTiles++;
      }
      if (terrainTiles == 0 || counts.isEmpty) continue;

      // Find dominant terrain.
      TerrainType dominant = counts.keys.first;
      var maxCount = counts[dominant]!;
      for (final e in counts.entries) {
        if (e.value > maxCount) {
          dominant = e.key;
          maxCount = e.value;
        }
      }
      final fDom = maxCount / terrainTiles;
      if (fDom < params.jitterHomogeneityThreshold) continue;

      // Candidate tiles: dominant terrain, no resource, and lying on a
      // terrain or province edge.
      final candidates = <(int x, int y)>[];
      for (final (x, y) in tiles) {
        if (terrainGrid[y][x] != dominant) continue;
        if (resourceGrid[y][x] != null) continue;

        var isEdge = false;
        // Terrain-edge or province-edge in 4-neighborhood.
        for (final (dx, dy) in directions4) {
          final nx = x + dx;
          final ny = y + dy;
          if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
          final neighborProvince = grid[ny][nx];
          final neighborTerrain = terrainGrid[ny][nx];
          if (neighborProvince != entry.key) {
            isEdge = true; // province-edge
            break;
          }
          if (neighborTerrain != null && neighborTerrain != dominant) {
            isEdge = true; // terrain-edge within same province
            break;
          }
        }
        if (!isEdge) continue;

        candidates.add((x, y));
      }
      if (candidates.isEmpty) continue;

      candidates.shuffle(rnd);
      final maxChanges = (params.jitterMaxFraction * tiles.length).floor();
      if (maxChanges <= 0) continue;
      var changes = 0;

      for (final (x, y) in candidates) {
        if (changes >= maxChanges) break;
        if (rnd.nextDouble() > params.jitterProbability) continue;

        // Prefer neighboring terrains within same province that are not
        // dominant, and require a minimum neighbor support threshold.
        final neighborCounts = <TerrainType, int>{};
        for (final (dx, dy) in directions8) {
          final nx = x + dx;
          final ny = y + dy;
          if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
          if (grid[ny][nx] != entry.key) continue; // same province only
          final nt = terrainGrid[ny][nx];
          if (nt == null || nt == dominant || nt == TerrainType.mountain) {
            continue;
          }
          neighborCounts[nt] = (neighborCounts[nt] ?? 0) + 1;
        }

        final supported = neighborCounts.entries
            .where((e) => e.value >= params.jitterNeighborSupportThreshold)
            .map((e) => e.key)
            .toList();
        if (supported.isEmpty) {
          // No terrain with enough local support; skip to avoid isolated speckles.
          continue;
        }

        final newTerrain = supported[rnd.nextInt(supported.length)];
        terrainGrid[y][x] = newTerrain;
        changes++;
      }
    }
  }

  /// Join step: for each continent with >1 land component, connect two by a shortest path of sea cells. Returns (grid, terrainGrid, resourceGrid, didJoin).
  (List<List<String>>, List<List<TerrainType?>>?, List<List<Resource?>>?, bool)
  joinContinents(
    List<List<String>> grid,
    List<List<TerrainType?>>? terrainGrid,
    List<List<Resource?>>? resourceGrid,
    Map<String, int> provinceToContinent,
    String seaZoneId,
    String? mapRegionId,
    ResourceRules? resourceRules,
    Random rnd,
  ) {
    if (provinceToContinent.isEmpty) {
      return (grid, terrainGrid, resourceGrid, false);
    }
    final numContinents = provinceToContinent.values.toSet().length;
    var didJoin = false;
    var g = grid.map((row) => row.toList()).toList();
    var tg = terrainGrid?.map((row) => row.toList()).toList();
    var rg = resourceGrid?.map((row) => row.toList()).toList();
    final ocean = _graph.oceanCells(g, seaZoneId);
    // Upper bound so we cannot spin forever if sea-fraction preservation undoes a bridge.
    final maxJoinIterationsPerContinent = params.width * params.height;

    final capState =
        (tg != null &&
            rg != null &&
            mapRegionId != null &&
            resourceRules != null &&
            (mapRegionId == 'oldWorld' || mapRegionId == 'newWorld'))
        ? _MultiRegionCapState.fromExisting(
            params.multiRegionResourceCapFraction,
            resourceRules,
            mapRegionId,
            rg,
          )
        : null;

    for (var c = 0; c < numContinents; c++) {
      var joinIterations = 0;
      while (joinIterations < maxJoinIterationsPerContinent) {
        joinIterations++;
        final landCells = _landCellsForContinent(
          g,
          provinceToContinent,
          c,
          seaZoneId,
        );
        final components = _graph.connectedComponentsOfLand(landCells);
        if (components.length <= 1) break;
        didJoin = true;
        final compA = components[0];
        final compB = components[1];
        final path = _shortestSeaPath(g, seaZoneId, compA, compB);
        if (path.isEmpty) break;
        final provinceId = _provinceIdAdjacentToSeaPath(g, compA, path);
        final bridgeCells = path.toSet();
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
        // Do not convert bridge tiles back to sea: _preserveSeaFraction picks the
        // most "coastal" land first, which matches the new corridor and would undo
        // the join, leaving >1 component and an infinite loop.
        preserveSeaFraction(
          g,
          tg,
          rg,
          seaZoneId,
          ocean,
          path.length,
          landCellsExcludedFromSeaRestore: bridgeCells,
        );
      }
      if (joinIterations >= maxJoinIterationsPerContinent) {
        final stillSplit = _graph.connectedComponentsOfLand(
          _landCellsForContinent(g, provinceToContinent, c, seaZoneId),
        );
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

  /// Pass 11: Subdivide sea so each zone has at most maxSeaZoneFraction * totalSea tiles.
  /// Returns (newGrid, total sea zone count).
  (List<List<String>>, int) subdivideSeaZonesWithCap(
    List<List<String>> grid,
    String seaZoneId,
    int totalSea,
  ) {
    final components = _graph.connectedComponentsOfSea(grid, seaZoneId);
    if (components.isEmpty) return (grid, 0);
    final sorted = List<Set<(int x, int y)>>.from(components)
      ..sort((a, b) {
        final (minYa, minXa) = _graph.minYx(a);
        final (minYb, minXb) = _graph.minYx(b);
        if (minYa != minYb) return minYa.compareTo(minYb);
        return minXa.compareTo(minXb);
      });
    final g = grid.map((row) => row.toList()).toList();
    final maxPerZone = (params.maxSeaZoneFraction * totalSea).floor();
    var nextSeaZoneIndex = 1;
    for (final component in sorted) {
      final size = component.length;
      if (maxPerZone <= 0 || size <= maxPerZone) {
        final id = 's$nextSeaZoneIndex';
        nextSeaZoneIndex++;
        for (final (x, y) in component) {
          g[y][x] = id;
        }
        continue;
      }
      final K = (size / maxPerZone).ceil().clamp(1, size);
      final seeds = _placeSeaSeedsFarthestPoint(component, K);
      final seedMap = <String, (int x, int y)>{
        for (var i = 0; i < seeds.length; i++)
          's${nextSeaZoneIndex + i}': seeds[i],
      };
      final assignment = assignCellsToNearestSeed(
        component,
        seedMap,
        noiseScale: params.voronoiNoiseScale,
        noiseSeed: params.seed,
      );
      for (final entry in assignment.entries) {
        final (x, y) = entry.key;
        g[y][x] = entry.value;
      }
      nextSeaZoneIndex += K;
    }
    return (g, nextSeaZoneIndex - 1);
  }

  /// Place K well-spread seeds in [cells] using farthest-point sampling.
  List<(int x, int y)> _placeSeaSeedsFarthestPoint(
    Set<(int x, int y)> cells,
    int K,
  ) {
    if (cells.isEmpty || K <= 0) return [];
    final list = cells.toList();
    if (K >= list.length) return list;
    list.sort((a, b) {
      if (a.$2 != b.$2) return a.$2.compareTo(b.$2);
      return a.$1.compareTo(b.$1);
    });
    final chosen = <(int x, int y)>[list.first];
    for (var i = 1; i < K; i++) {
      var bestCell = list.first;
      var bestMinD2 = 0;
      for (final (x, y) in list) {
        if (chosen.contains((x, y))) continue;
        var minD2 = kUnsetSquaredDistanceInt31;
        for (final (sx, sy) in chosen) {
          final d2 = (x - sx) * (x - sx) + (y - sy) * (y - sy);
          if (d2 < minD2) minD2 = d2;
        }
        if (minD2 > bestMinD2) {
          bestMinD2 = minD2;
          bestCell = (x, y);
        }
      }
      chosen.add(bestCell);
    }
    return chosen;
  }

  /// Shortest path of sea cells from (sea cells adjacent to compA) to (sea cells adjacent to compB). BFS; returns path including endpoints.
  List<(int x, int y)> _shortestSeaPath(
    List<List<String>> grid,
    String seaZoneId,
    Set<(int x, int y)> compA,
    Set<(int x, int y)> compB,
  ) {
    final compASet = compA;
    final compBSet = compB;
    final seaAdjacentToA = <(int x, int y)>{};
    for (final (x, y) in compASet) {
      for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
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
    for (final (x, y) in compBSet) {
      for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
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
      for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
          continue;
        }
        if (grid[ny][nx] != seaZoneId) continue;
        final n = (nx, ny);
        if (prev.containsKey(n)) continue;
        prev[n] = (x, y);
        queue.add(n);
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
      for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
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
    _MultiRegionCapState? capState,
  }) {
    final landTerrains = allowedTerrainsForRegion(mapRegionId);
    if (landTerrains.isEmpty) return;
    terrainGrid[y][x] = landTerrains[rnd.nextInt(landTerrains.length)];
    final terrain = terrainGrid[y][x]!;
    var allowed = Resource.values
        .where(
          (r) =>
              rules.isAllowedInRegion(r, mapRegionId) &&
              rules.isAllowedOnTerrain(r, terrain),
        )
        .toList();
    if (allowed.isEmpty) return;
    if (capState != null &&
        (mapRegionId == 'oldWorld' || mapRegionId == 'newWorld') &&
        capState.shouldRestrictToRegionOnly(allowed)) {
      allowed = capState.filterToRegionOnly(allowed);
      if (allowed.isEmpty) return;
    }
    if (rnd.nextDouble() > 0.4) return;
    final weights = allowed.map((r) => rules.spawnWeight(r)).toList();
    final sum = weights.reduce((a, b) => a + b);
    var roll = rnd.nextDouble() * sum;
    for (var i = 0; i < allowed.length; i++) {
      roll -= weights[i];
      if (roll <= 0) {
        final placed = allowed[i];
        resourceGrid[y][x] = placed;
        capState?.record(placed);
        break;
      }
    }
  }

  int countSeaCells(List<List<String>> grid, String seaZoneId) =>
      _graph.countSeaCells(grid, seaZoneId);

  void preserveSeaFraction(
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
        final oceanNeighbours = [(x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)]
            .where(
              (p) =>
                  p.$1 >= 0 &&
                  p.$1 < params.width &&
                  p.$2 >= 0 &&
                  p.$2 < params.height &&
                  grid[p.$2][p.$1] == seaZoneId &&
                  ocean.contains(p),
            )
            .length;
        if (oceanNeighbours >= 1) coastal.add((x, y));
      }
    }
    coastal.sort((a, b) {
      final na =
          [
                (a.$1 - 1, a.$2),
                (a.$1 + 1, a.$2),
                (a.$1, a.$2 - 1),
                (a.$1, a.$2 + 1),
              ]
              .where(
                (p) =>
                    p.$1 >= 0 &&
                    p.$1 < params.width &&
                    p.$2 >= 0 &&
                    p.$2 < params.height &&
                    grid[p.$2][p.$1] == seaZoneId &&
                    ocean.contains(p),
              )
              .length;
      final nb =
          [
                (b.$1 - 1, b.$2),
                (b.$1 + 1, b.$2),
                (b.$1, b.$2 - 1),
                (b.$1, b.$2 + 1),
              ]
              .where(
                (p) =>
                    p.$1 >= 0 &&
                    p.$1 < params.width &&
                    p.$2 >= 0 &&
                    p.$2 < params.height &&
                    grid[p.$2][p.$1] == seaZoneId &&
                    ocean.contains(p),
              )
              .length;
      return nb.compareTo(na);
    });
    for (var i = 0; i < count && i < coastal.length; i++) {
      final (x, y) = coastal[i];
      grid[y][x] = seaZoneId;
      if (terrainGrid != null) terrainGrid[y][x] = null;
      if (resourceGrid != null) resourceGrid[y][x] = null;
    }
  }
}
