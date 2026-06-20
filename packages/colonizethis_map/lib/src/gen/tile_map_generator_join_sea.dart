/// Pass 10–11: join continents, terrain jitter, sea subdivision.
///
/// The continent-joining, terrain-jitter, and sea-subdivision passes were
/// previously split across three sibling part fragments; they are consolidated
/// here as cohesive extensions on [_TileMapGenJoinSea] (Refs #3574, slice 7).

part of 'tile_map_generator.dart';

/// Exempt from the uniform [MapGenPass] entry point (Refs #3574, slice 4):
/// this family owns three heterogeneous passes — continent joining
/// (grid+terrain+resource in/out), terrain jitter (in-place mutation), and
/// sea-zone subdivision (grid in/out) — that share no single representative
/// payload/result shape. It therefore implements [MapGenStage] only; the
/// orchestrator drives its three passes via their dedicated methods.
class _TileMapGenJoinSea implements MapGenStage {
  _TileMapGenJoinSea(this.params, this._log, this._graph);

  @override
  final TileMapParams params;
  final CtLogger _log;
  final TileMapGridGraph _graph;
}

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
    var g = snapshotGrid(grid);
    var tg = terrainGrid != null ? snapshotGrid(terrainGrid) : null;
    var rg = resourceGrid != null ? snapshotGrid(resourceGrid) : null;
    final ocean = _graph.oceanCells(
      g,
      seaZoneId,
      landSeeds,
      continentBySeedIndex,
    );
    final maxJoinIterationsPerContinent = params.width * params.height;
    var landCellsByContinent = _buildLandCellsByContinentIndex(
      g,
      provinceToContinent,
      seaZoneId,
      numContinents,
    );

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
            terrainGrid: tg,
          )
        : null;

    for (var c = 0; c < numContinents; c++) {
      var joinIterations = 0;
      while (joinIterations < maxJoinIterationsPerContinent) {
        joinIterations++;
        final landCells = landCellsByContinent[c];
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
        landCellsByContinent[c].addAll(path);
        final restoredToSea = preserveSeaFraction(
          g,
          tg,
          rg,
          seaZoneId,
          ocean,
          path.length,
          landCellsExcludedFromSeaRestore: bridgeCells,
        );
        for (final (x, y) in restoredToSea) {
          for (var ci = 0; ci < numContinents; ci++) {
            landCellsByContinent[ci].remove((x, y));
          }
        }
      }
      if (joinIterations >= maxJoinIterationsPerContinent) {
        final stillSplit = _graph.connectedComponentsOfLand(
          landCellsByContinent[c],
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

  /// One O(W×H) scan; [joinContinents] reuses and incrementally updates these sets
  /// (Refs #2489 P4).
  List<Set<(int x, int y)>> _buildLandCellsByContinentIndex(
    List<List<String>> grid,
    Map<String, int> membership,
    String seaZoneId,
    int numContinents,
  ) {
    final out = List<Set<(int x, int y)>>.generate(
      numContinents,
      (_) => <(int x, int y)>{},
    );
    TileMapGrid.forEachCell(grid, (y, x, id) {
      if (id == seaZoneId) return;
      final continentIndex = membership[id];
      if (continentIndex == null ||
          continentIndex < 0 ||
          continentIndex >= numContinents) {
        return;
      }
      out[continentIndex].add((x, y));
    });
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
    // One ocean-neighbour count per candidate; reuse for sort keys (Refs #2489).
    final coastal = <(int x, int y, int oceanNeighbours)>[];
    TileMapGrid.forEachCell(grid, (y, x, value) {
      if (value == seaZoneId) return;
      if (landCellsExcludedFromSeaRestore?.contains((x, y)) ?? false) {
        return;
      }
      final n = _graph.oceanNeighbourCount(grid, x, y, seaZoneId, ocean);
      if (n >= 1) {
        coastal.add((x, y, n));
      }
    });
    coastal.sort((a, b) => b.$3.compareTo(a.$3));
    final restoredToSea = <(int x, int y)>[];
    for (var i = 0; i < count && i < coastal.length; i++) {
      final (x, y, _) = coastal[i];
      grid[y][x] = seaZoneId;
      if (terrainGrid != null) terrainGrid[y][x] = null;
      if (resourceGrid != null) resourceGrid[y][x] = null;
      restoredToSea.add((x, y));
    }
    return restoredToSea;
  }
}

extension _TileMapGenJoinSeaJitterPart on _TileMapGenJoinSea {
  bool _jitterTileIsTerrainOrProvinceEdge(
    int x,
    int y,
    String provinceId,
    TerrainType dominant,
    List<List<String>> grid,
    List<List<TerrainType?>> terrainGrid,
    int width,
    int height,
    List<(int dx, int dy)> directions4,
  ) {
    for (final (dx, dy) in directions4) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
      final neighborProvince = grid[ny][nx];
      final neighborTerrain = terrainGrid[ny][nx];
      if (neighborProvince != provinceId) return true;
      if (neighborTerrain != null && neighborTerrain != dominant) {
        return true;
      }
    }
    return false;
  }

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
    final tilesByProvince = <String, List<(int x, int y)>>{};
    final provinceIdPattern = RegExp(r'^p\d+$');
    TileMapGrid.forEachCell(grid, (y, x, id) {
      if (!provinceIdPattern.hasMatch(id)) return;
      tilesByProvince.putIfAbsent(id, () => []).add((x, y));
    });
    if (tilesByProvince.isEmpty) return;

    const directions4 = kTileMapDirections4;
    const directions8 = kTileMapDirections8;

    for (final entry in tilesByProvince.entries) {
      final tiles = entry.value;
      if (tiles.length < params.jitterMinProvinceSize) continue;

      final counts = <TerrainType, int>{};
      var terrainTiles = 0;
      for (final (x, y) in tiles) {
        final t = terrainGrid[y][x];
        if (t == null) continue;
        counts[t] = (counts[t] ?? 0) + 1;
        terrainTiles++;
      }
      if (terrainTiles == 0 || counts.isEmpty) continue;

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

      final candidates = <(int x, int y)>[];
      for (final (x, y) in tiles) {
        if (terrainGrid[y][x] != dominant) continue;
        if (resourceGrid[y][x] != null) continue;
        if (!_jitterTileIsTerrainOrProvinceEdge(
          x,
          y,
          entry.key,
          dominant,
          grid,
          terrainGrid,
          width,
          height,
          directions4,
        )) {
          continue;
        }
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

        final neighborCounts = <TerrainType, int>{};
        for (final (dx, dy) in directions8) {
          final nx = x + dx;
          final ny = y + dy;
          if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
          if (grid[ny][nx] != entry.key) continue;
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
        if (supported.isEmpty) continue;
        terrainGrid[y][x] = supported[rnd.nextInt(supported.length)];
        changes++;
      }
    }
  }
}

extension _TileMapGenJoinSeaSubdividePart on _TileMapGenJoinSea {
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
    final g = snapshotGrid(grid);
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
      chosen.add(_bestFarthestPointCellFromList(list, chosen));
    }
    return chosen;
  }

  (int x, int y) _bestFarthestPointCellFromList(
    List<(int x, int y)> list,
    List<(int x, int y)> chosen,
  ) {
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
    return bestCell;
  }
}
