// SPEC/program/tile-map-generation.md. Reference: SPEC/ideas/tile-based-map-generation.md.

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';

import 'grid_voronoi.dart';
import 'topology_inference.dart';

/// Sentinel value for "land not yet assigned to a province". Replaced in Pass 9.
const String _landSentinel = '_land';

/// How land-shape seeds are placed around each continent seed. SPEC/program/tile-map-generation.md § Pass 2.
enum LandSeedClusterShape {
  gaussian,
  uniformDisk,
  uniformAnnulus,
}

/// Centralized map generation parameters. SPEC/program/tile-map-generation.md § Grid size derivation.
class MapGenerationParams {
  const MapGenerationParams({
    this.targetTilesPerProvince = 35,
    this.seaFraction = 0.6,
    this.numContinents = 3,
    this.seed = 42,
    this.borderNoise = 0.0,
    this.maxEnforceIterations = 10,
    this.clusterShape = LandSeedClusterShape.gaussian,
    this.voronoiNoiseScale = 1.0,
    this.continentBufferTiles = 2,
    this.skipFillLakes = false,
    this.joinContinents = true,
    this.seedBeforeAssignment = false,
  })  : assert(targetTilesPerProvince >= 1),
        assert(seaFraction >= 0 && seaFraction < 1),
        assert(numContinents >= 1),
        assert(voronoiNoiseScale >= 0),
        assert(continentBufferTiles >= 0);

  /// Average land tiles per province; used to derive total land and grid size.
  final int targetTilesPerProvince;
  /// Fraction of grid that is sea (0–1); e.g. 0.6 for 60:40 sea:land.
  final double seaFraction;
  /// Number of continents; used when deriving grid size (e.g. when loading topology from file).
  final int numContinents;
  final int seed;
  /// 0–1; 0 = no border noise.
  final double borderNoise;
  final int maxEnforceIterations;
  /// How land-shape seeds are clustered around each continent seed.
  final LandSeedClusterShape clusterShape;
  /// Voronoi noise scale (0 = off). When > 0, perturb distance in Pass 3 for irregular boundaries.
  final double voronoiNoiseScale;
  /// Minimum Manhattan distance from another continent when assigning land (organic). 0 = legacy 1-tile.
  final int continentBufferTiles;
  /// When true, skip Pass 4 (no lake-to-land conversion).
  final bool skipFillLakes;
  /// When true, run join step after Pass 9 if a topology continent has multiple land components.
  final bool joinContinents;
  /// When true, use legacy land assignment (place all seeds first, then one Voronoi).
  /// When false (default), use organic land growing.
  final bool seedBeforeAssignment;
}

/// Computes grid width and height from province count and map params.
/// Uses land count, target tiles per province, and sea fraction. SPEC/program/tile-map-generation.md § Grid size derivation.
({int width, int height}) computeGridSizeFromParams(
  int numProvinces,
  MapGenerationParams params,
) {
  if (numProvinces == 0) return (width: 32, height: 24);
  final totalLandTiles = numProvinces * params.targetTilesPerProvince;
  final safeSea = params.seaFraction.clamp(0.0, 0.99);
  final totalTiles = (totalLandTiles / (1 - safeSea)).round();
  const aspect = 4 / 3;
  var height = sqrt(totalTiles / aspect).round();
  if (height < 8) height = 8;
  var width = (totalTiles / height).round();
  if (width < 8) width = 8;
  return (width: width, height: height);
}

/// Builds province-to-continent map by partitioning p1..pN across C continents.
/// Each continent gets a similar number of provinces (≈ N/C, remainder distributed).
Map<String, int> buildProvinceToContinentMap(int numProvinces, int numContinents) {
  if (numProvinces <= 0 || numContinents <= 0) return {};
  final result = <String, int>{};
  final continentSize = numProvinces ~/ numContinents;
  final remainder = numProvinces % numContinents;
  var idx = 0;
  for (var c = 0; c < numContinents; c++) {
    final size = continentSize + (c < remainder ? 1 : 0);
    for (var i = 0; i < size; i++) {
      result['p${idx + 1}'] = c;
      idx++;
    }
  }
  return result;
}

/// Returns continent index (0, 1, …) per province id from topology.
/// Continents = connected components of the land subgraph (P–P edges only). Sea zone is not in the result.
Map<String, int> computeContinentMembership(MapTopology topology) {
  final provinceIds = topology.nodes
      .where((n) => n.type == TopologyNodeType.province)
      .map((n) => n.id)
      .toSet();
  if (provinceIds.isEmpty) return {};
  final p2p = <String, Set<String>>{};
  for (final id in provinceIds) {
    p2p[id] = {};
  }
  for (final e in topology.edges) {
    if (provinceIds.contains(e.id1) && provinceIds.contains(e.id2)) {
      p2p[e.id1]!.add(e.id2);
      p2p[e.id2]!.add(e.id1);
    }
  }
  final continent = <String, int>{};
  var idx = 0;
  for (final start in provinceIds) {
    if (continent.containsKey(start)) continue;
    final queue = <String>[start];
    continent[start] = idx;
    while (queue.isNotEmpty) {
      final cur = queue.removeLast();
      for (final n in p2p[cur]!) {
        if (!continent.containsKey(n)) {
          continent[n] = idx;
          queue.add(n);
        }
      }
    }
    idx++;
  }
  return continent;
}

/// Runtime parameters for tile-based map generation (grid dimensions and generator options).
class TileMapParams {
  const TileMapParams({
    this.width = 100,
    this.height = 100,
    this.seed = 42,
    this.seaFraction = 0.6,
    this.borderNoise = 0.0,
    this.maxEnforceIterations = 10,
    this.clusterShape = LandSeedClusterShape.gaussian,
    this.voronoiNoiseScale = 1.0,
    this.continentBufferTiles = 2,
    this.skipFillLakes = false,
    this.joinContinents = true,
    this.seedBeforeAssignment = false,
    this.maxSeaZoneFraction = 0.05,
  })  : assert(seaFraction >= 0 && seaFraction < 1),
        assert(voronoiNoiseScale >= 0),
        assert(continentBufferTiles >= 0),
        assert(maxSeaZoneFraction > 0 && maxSeaZoneFraction <= 1);

  final int width;
  final int height;
  final int seed;
  /// Fraction of grid that is sea (0–1); used for land budget in Pass 3.
  final double seaFraction;
  /// 0–1; 0 = no border noise.
  final double borderNoise;
  final int maxEnforceIterations;
  /// How land-shape seeds are clustered around each continent seed.
  final LandSeedClusterShape clusterShape;
  /// Voronoi noise scale (0 = off). When > 0, perturb distance in Pass 3.
  final double voronoiNoiseScale;
  /// Minimum Manhattan distance from another continent when assigning land (organic). 0 = legacy 1-tile.
  final int continentBufferTiles;
  /// When true, skip Pass 4 (no lake-to-land conversion).
  final bool skipFillLakes;
  /// When true, run join step after Pass 9 when needed.
  final bool joinContinents;
  /// When true, use legacy land assignment (place all seeds first, then one Voronoi).
  final bool seedBeforeAssignment;
  /// Max fraction of total sea tiles per sea zone (Pass 11); e.g. 0.05 = 5%.
  final double maxSeaZoneFraction;
}

/// Generates a per-region tile map from province/continent params. SPEC/program/tile-map-generation.md.
/// Map-first: topology is inferred from the grid after generation.
class TileMapGenerator {
  TileMapGenerator({this.params = const TileMapParams()});

  final TileMapParams params;

  /// Generate a tile map from province/continent count. Returns (TileMapResult, inferred MapTopology).
  /// Optional [onLog] receives one line per pass.
  /// If [resourceRules] is provided, assigns terrain and optional resource per land cell (Pass 6–7).
  /// Optional [onLandSeedsPlaced] receives the land seed positions (Pass 2) and a parallel list of
  /// continent indices (0, 1, …) for each seed, for visualization.
  /// Optional [onContinentSeedsPlaced] receives the continent seed positions (one per continent).
  (TileMapResult, MapTopology) generate({
    required int numProvinces,
    required int numContinents,
    required String regionId,
    String seaZoneId = 's1',
    ResourceRules? resourceRules,
    void Function(String)? onLog,
    void Function(List<(int x, int y)> landSeeds, List<int> continentIndices)? onLandSeedsPlaced,
    void Function(List<(int x, int y)> continentSeeds)? onContinentSeedsPlaced,
  }) {
    if (numProvinces < 1) {
      throw ArgumentError('numProvinces must be at least 1');
    }
    if (numContinents < 1) {
      throw ArgumentError('numContinents must be at least 1');
    }
    final provinceToContinent = buildProvinceToContinentMap(numProvinces, numContinents);
    final rnd = Random(params.seed);

    // Pass 1: Initialize grid (all sea)
    var grid = List.generate(
      params.height,
      (_) => List.filled(params.width, seaZoneId),
    );
    onLog?.call('Pass 1: Grid initialized (${params.width}x${params.height}), all sea');

    List<(int x, int y)> continentSeeds;
    List<(int x, int y)> landSeeds;
    List<int> continentBySeedIndex;

    if (params.seedBeforeAssignment) {
      // Pass 2–3 (fallback): Place all seeds, then one global Voronoi
      final placed = _placeLandSeeds(provinceToContinent, rnd);
      continentSeeds = placed.$1;
      landSeeds = placed.$2;
      continentBySeedIndex = placed.$3;
      onLog?.call('Pass 2: Continent seeds ${continentSeeds.length}, land seeds ${landSeeds.length}');
      grid = _assignLandByLandSeeds(grid, landSeeds, continentBySeedIndex, provinceToContinent, seaZoneId);
    } else {
      // Organic: interleaved seed placement + small Voronoi + coastline growth
      final organic = _placeLandSeedsOrganic(grid, provinceToContinent, seaZoneId, rnd);
      continentSeeds = organic.$1;
      landSeeds = organic.$2;
      continentBySeedIndex = organic.$3;
      grid = organic.$4;
      onLog?.call('Pass 2–3 (organic): Continent seeds ${continentSeeds.length}, land seeds ${landSeeds.length}');
    }

    if (landSeeds.isNotEmpty) {
      onLandSeedsPlaced?.call(
        List<(int x, int y)>.from(landSeeds),
        List<int>.from(continentBySeedIndex),
      );
    }
    if (continentSeeds.isNotEmpty) {
      onContinentSeedsPlaced?.call(List<(int x, int y)>.from(continentSeeds));
    }

    var landCount = 0;
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] == _landSentinel) landCount++;
      }
    }
    onLog?.call('Pass 3: Land assignment complete ($landCount land, ${params.width * params.height - landCount} sea)');

    // Pass 4: Fill lakes (ocean = sea connected to edge; lake → land; optional coastal swap)
    if (params.skipFillLakes) {
      onLog?.call('Pass 4: Fill lakes skipped');
    } else {
      grid = _fillLakes(grid, seaZoneId, landSeeds, continentBySeedIndex);
      onLog?.call('Pass 4: Fill lakes done');
    }

    // Pass 5: Border randomization (optional; sentinel = land)
    if (params.borderNoise > 0) {
      grid = _borderNoise(grid, seaZoneId, rnd);
      onLog?.call('Pass 5: Border noise applied');
    } else {
      onLog?.call('Pass 5: Border noise skipped (0)');
    }

    // Pass 6–7: Terrain and resource assignment (by map regionId; no province id)
    List<List<TerrainType?>>? terrainGrid;
    List<List<Resource?>>? resourceGrid;
    if (resourceRules != null) {
      final t = _assignTerrainAndResources(grid, regionId, resourceRules, rnd);
      terrainGrid = t.$1;
      resourceGrid = t.$2;
      var terrainCount = 0;
      var resourceCount = 0;
      for (var y = 0; y < params.height; y++) {
        for (var x = 0; x < params.width; x++) {
          if (terrainGrid[y][x] != null) terrainCount++;
          if (resourceGrid[y][x] != null) resourceCount++;
        }
      }
      onLog?.call('Pass 6: Terrain assigned ($terrainCount land cells)');
      onLog?.call('Pass 7: Resources placed ($resourceCount cells)');
    } else {
      onLog?.call('Pass 6–7: Terrain/resources skipped (no rules or no provinces)');
    }

    // Pass 8: Province seeds on land (one per province, per continent)
    final provinceSeeds = _placeProvinceSeedsOnLand(
        grid, provinceToContinent, landSeeds, continentBySeedIndex, seaZoneId, rnd);
    onLog?.call('Pass 8: Province seeds on land (${provinceSeeds.length} provinces)');

    // Pass 9: Province assignment (Voronoi on land; replace sentinel with province id)
    grid = _assignProvincesFromSeeds(grid, provinceSeeds, seaZoneId);
    onLog?.call('Pass 9: Province assignment complete');

    // Join step (optional): connect split land components per continent
    if (params.joinContinents) {
      final joinResult = _joinContinents(
        grid,
        terrainGrid,
        resourceGrid,
        provinceToContinent,
        seaZoneId,
        regionId,
        resourceRules,
        rnd,
      );
      grid = joinResult.$1;
      terrainGrid = joinResult.$2;
      resourceGrid = joinResult.$3;
      if (joinResult.$4) {
        onLog?.call('Pass 10: Join continents (land bridges added)');
      }
    }

    // Pass 11: Sea zone subdivision with size cap (max fraction of total sea per zone).
    final totalSea = _countSeaCells(grid, seaZoneId);
    if (totalSea > 0) {
      final (newGrid, numSeaZones) = _subdivideSeaZonesWithCap(grid, seaZoneId, totalSea);
      grid = newGrid;
      onLog?.call('Pass 11: Sea zone subdivision ($numSeaZones sea zones, cap ${(params.maxSeaZoneFraction * 100).toInt()}% of sea)');
    }

    final result = TileMapResult(
      width: params.width,
      height: params.height,
      grid: grid,
      terrainGrid: terrainGrid,
      resourceGrid: resourceGrid,
    );
    final topology = inferTopologyFromTileMap(result, regionId, seaZoneId);
    return (result, topology);
  }

  /// Join step: for each continent with >1 land component, connect two by a shortest path of sea cells. Returns (grid, terrainGrid, resourceGrid, didJoin).
  (List<List<String>>, List<List<TerrainType?>>?, List<List<Resource?>>?, bool) _joinContinents(
    List<List<String>> grid,
    List<List<TerrainType?>>? terrainGrid,
    List<List<Resource?>>? resourceGrid,
    Map<String, int> provinceToContinent,
    String seaZoneId,
    String? mapRegionId,
    ResourceRules? resourceRules,
    Random rnd,
  ) {
    if (provinceToContinent.isEmpty) return (grid, terrainGrid, resourceGrid, false);
    final numContinents = provinceToContinent.values.toSet().length;
    var didJoin = false;
    var g = grid.map((row) => row.toList()).toList();
    var tg = terrainGrid != null ? terrainGrid.map((row) => row.toList()).toList() : null;
    var rg = resourceGrid != null ? resourceGrid.map((row) => row.toList()).toList() : null;
    final ocean = _oceanCells(g, seaZoneId);

    for (var c = 0; c < numContinents; c++) {
      while (true) {
        final landCells = _landCellsForContinent(g, provinceToContinent, c, seaZoneId);
        final components = _connectedComponentsOfLand(landCells);
        if (components.length <= 1) break;
        didJoin = true;
        final compA = components[0];
        final compB = components[1];
        final path = _shortestSeaPath(g, seaZoneId, compA, compB);
        if (path.isEmpty) break;
        final provinceId = _provinceIdAdjacentToSeaPath(g, compA, path);
        for (final (x, y) in path) {
          g[y][x] = provinceId;
          if (tg != null && rg != null && mapRegionId != null && resourceRules != null) {
            _assignTerrainAndResourceForCell(tg, rg, x, y, mapRegionId, resourceRules, rnd);
          }
        }
        _preserveSeaFraction(g, tg, rg, seaZoneId, ocean, path.length);
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

  List<Set<(int x, int y)>> _connectedComponentsOfLand(Set<(int x, int y)> landCells) {
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
        for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
          final n = (x + dx, y + dy);
          if (remaining.remove(n)) {
            component.add(n);
            queue.add(n);
          }
        }
      }
      result.add(component);
    }
    return result;
  }

  /// Pass 11: 4-connected components of sea cells (grid cells with seaZoneId).
  List<Set<(int x, int y)>> _connectedComponentsOfSea(
    List<List<String>> grid,
    String seaZoneId,
  ) {
    final seaCells = <(int x, int y)>{};
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] == seaZoneId) seaCells.add((x, y));
      }
    }
    return _connectedComponentsOfLand(seaCells);
  }

  /// Assign s1, s2, … to sea components; sort by (minY, minX). Returns new grid.
  List<List<String>> _assignSeaZoneIds(
    List<List<String>> grid,
    List<Set<(int x, int y)>> components,
    String seaZoneId,
  ) {
    final sorted = List<Set<(int x, int y)>>.from(components)
      ..sort((a, b) {
        final (minYa, minXa) = _minYx(a);
        final (minYb, minXb) = _minYx(b);
        if (minYa != minYb) return minYa.compareTo(minYb);
        return minXa.compareTo(minXb);
      });
    final g = grid.map((row) => row.toList()).toList();
    for (var i = 0; i < sorted.length; i++) {
      final id = 's${i + 1}';
      for (final (x, y) in sorted[i]) {
        g[y][x] = id;
      }
    }
    return g;
  }

  (int, int) _minYx(Set<(int x, int y)> cells) {
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

  int _countSeaCells(List<List<String>> grid, String seaZoneId) {
    var n = 0;
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] == seaZoneId) n++;
      }
    }
    return n;
  }

  /// Pass 11: Subdivide sea so each zone has at most maxSeaZoneFraction * totalSea tiles.
  /// Returns (newGrid, total sea zone count).
  (List<List<String>>, int) _subdivideSeaZonesWithCap(
    List<List<String>> grid,
    String seaZoneId,
    int totalSea,
  ) {
    final components = _connectedComponentsOfSea(grid, seaZoneId);
    if (components.isEmpty) return (grid, 0);
    final sorted = List<Set<(int x, int y)>>.from(components)
      ..sort((a, b) {
        final (minYa, minXa) = _minYx(a);
        final (minYb, minXb) = _minYx(b);
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
        for (var i = 0; i < seeds.length; i++) 's${nextSeaZoneIndex + i}': seeds[i],
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
  List<(int x, int y)> _placeSeaSeedsFarthestPoint(Set<(int x, int y)> cells, int K) {
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
        var minD2 = 0x7FFFFFFFFFFFFFFF;
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
        if (nx >= 0 && nx < params.width && ny >= 0 && ny < params.height &&
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
        if (nx >= 0 && nx < params.width && ny >= 0 && ny < params.height &&
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
        if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) continue;
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
        if (nx >= 0 && nx < params.width && ny >= 0 && ny < params.height &&
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
    Random rnd,
  ) {
    final landTerrains = allowedTerrainsForRegion(mapRegionId);
    if (landTerrains.isEmpty) return;
    terrainGrid[y][x] = landTerrains[rnd.nextInt(landTerrains.length)];
    final terrain = terrainGrid[y][x]!;
    final allowed = Resource.values
        .where((r) =>
            rules.isAllowedInRegion(r, mapRegionId) &&
            rules.isAllowedOnTerrain(r, terrain))
        .toList();
    if (allowed.isEmpty) return;
    if (rnd.nextDouble() > 0.4) return;
    final weights = allowed.map((r) => rules.spawnWeight(r)).toList();
    final sum = weights.reduce((a, b) => a + b);
    var roll = rnd.nextDouble() * sum;
    for (var i = 0; i < allowed.length; i++) {
      roll -= weights[i];
      if (roll <= 0) {
        resourceGrid[y][x] = allowed[i];
        break;
      }
    }
  }

  void _preserveSeaFraction(
    List<List<String>> grid,
    List<List<TerrainType?>>? terrainGrid,
    List<List<Resource?>>? resourceGrid,
    String seaZoneId,
    Set<(int x, int y)> ocean,
    int count,
  ) {
    final coastal = <(int x, int y)>[];
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] == seaZoneId) continue;
        final oceanNeighbours = [
          (x - 1, y),
          (x + 1, y),
          (x, y - 1),
          (x, y + 1),
        ].where((p) => p.$1 >= 0 && p.$1 < params.width && p.$2 >= 0 && p.$2 < params.height &&
            grid[p.$2][p.$1] == seaZoneId && ocean.contains(p)).length;
        if (oceanNeighbours >= 1) coastal.add((x, y));
      }
    }
    coastal.sort((a, b) {
      final na = [
        (a.$1 - 1, a.$2),
        (a.$1 + 1, a.$2),
        (a.$1, a.$2 - 1),
        (a.$1, a.$2 + 1),
      ].where((p) => p.$1 >= 0 && p.$1 < params.width && p.$2 >= 0 && p.$2 < params.height &&
          grid[p.$2][p.$1] == seaZoneId && ocean.contains(p)).length;
      final nb = [
        (b.$1 - 1, b.$2),
        (b.$1 + 1, b.$2),
        (b.$1, b.$2 - 1),
        (b.$1, b.$2 + 1),
      ].where((p) => p.$1 >= 0 && p.$1 < params.width && p.$2 >= 0 && p.$2 < params.height &&
          grid[p.$2][p.$1] == seaZoneId && ocean.contains(p)).length;
      return nb.compareTo(na);
    });
    for (var i = 0; i < count && i < coastal.length; i++) {
      final (x, y) = coastal[i];
      grid[y][x] = seaZoneId;
      if (terrainGrid != null) terrainGrid[y][x] = null;
      if (resourceGrid != null) resourceGrid[y][x] = null;
    }
  }

  (List<List<TerrainType?>>, List<List<Resource?>>) _assignTerrainAndResources(
    List<List<String>> grid,
    String mapRegionId,
    ResourceRules rules,
    Random rnd,
  ) {
    final terrainGrid = List.generate(
      params.height,
      (_) => List.filled(params.width, null as TerrainType?),
    );
    final resourceGrid = List.generate(
      params.height,
      (_) => List.filled(params.width, null as Resource?),
    );

    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] != _landSentinel) {
          terrainGrid[y][x] = null;
          resourceGrid[y][x] = null;
          continue;
        }
        // Land (sentinel): assign terrain from map-region allowed set. SPEC: map-level region.
        final landTerrains = allowedTerrainsForRegion(mapRegionId);
        if (landTerrains.isEmpty) continue;
        terrainGrid[y][x] = landTerrains[rnd.nextInt(landTerrains.length)];
        final terrain = terrainGrid[y][x]!;
        // With probability place a resource from allowed set; weight = inverse to price
        final allowed = Resource.values
            .where((r) =>
                rules.isAllowedInRegion(r, mapRegionId) &&
                rules.isAllowedOnTerrain(r, terrain))
            .toList();
        if (allowed.isEmpty) continue;
        // 40% chance to place any resource on eligible land; then weighted pick
        if (rnd.nextDouble() > 0.4) continue;
        final weights = allowed.map((r) => rules.spawnWeight(r)).toList();
        final sum = weights.reduce((a, b) => a + b);
        var roll = rnd.nextDouble() * sum;
        for (var i = 0; i < allowed.length; i++) {
          roll -= weights[i];
          if (roll <= 0) {
            resourceGrid[y][x] = allowed[i];
            break;
          }
        }
      }
    }
    return (terrainGrid, resourceGrid);
  }

  /// One continent seed per continent; then a cluster of land-shape seeds per continent (K from province count). No province seeds yet.
  (List<(int x, int y)>, List<(int x, int y)>, List<int>) _placeLandSeeds(Map<String, int> provinceToContinent, Random rnd) {
    if (provinceToContinent.isEmpty) return (<(int x, int y)>[], <(int x, int y)>[], <int>[]);
    final numContinents = provinceToContinent.values.toSet().length;
    if (numContinents < 1) return (<(int x, int y)>[], <(int x, int y)>[], <int>[]);
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
            final r = annulusInner + rnd.nextDouble() * (annulusOuter - annulusInner);
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
  (List<(int x, int y)>, List<(int x, int y)>, List<int>, List<List<String>>) _placeLandSeedsOrganic(
    List<List<String>> grid,
    Map<String, int> provinceToContinent,
    String seaZoneId,
    Random rnd,
  ) {
    if (provinceToContinent.isEmpty) return (<(int x, int y)>[], <(int x, int y)>[], <int>[], grid);
    final numContinents = provinceToContinent.values.toSet().length;
    if (numContinents < 1) return (<(int x, int y)>[], <(int x, int y)>[], <int>[], grid);

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
      seedsPerContinent.add(minSeedsPerContinent > pc ? minSeedsPerContinent : pc);
    }
    final totalSeeds = seedsPerContinent.reduce((a, b) => a + b);
    final totalRounds = (totalSeeds / numContinents).ceil().clamp(1, 999);

    final landBudgetTotal = ((1 - params.seaFraction) * params.width * params.height).round();
    if (landBudgetTotal <= 0) return (<(int x, int y)>[], <(int x, int y)>[], <int>[], grid);

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
    final voronoiBudgetTotal = (landBudgetTotal - totalSeeds).clamp(0, landBudgetTotal);
    final totalProvinces = provinceToContinent.length;

    final seedCountsPerContinent = List<int>.filled(numContinents, 0);
    var voronoiRemaining = voronoiBudgetTotal;

    for (var round = 0; round < totalRounds; round++) {
      final roundBudget = (round + 1 == totalRounds)
          ? voronoiRemaining
          : (voronoiBudgetTotal / totalRounds).round();
      final budgetPerContinent = <int>[];
      for (var c = 0; c < numContinents; c++) {
        budgetPerContinent.add((roundBudget * provincesByContinent[c]!.length / totalProvinces).round());
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
      final (g2, _) = _growCoastlines(g, continentGrid, remaining, provinceToContinent, seaZoneId, rnd);
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
    final candidates = <(int x, int y)>[];
    final ownLandOrSeed = <(int x, int y)>[continentSeed];
    for (var i = 0; i < existingLandSeeds.length; i++) {
      if (continentBySeedIndex[i] == c) {
        ownLandOrSeed.add(existingLandSeeds[i]);
      }
    }
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] != seaZoneId) continue;
        var minDistToOwn = closeRadius + 1;
        for (final (ox, oy) in ownLandOrSeed) {
          final d = (x - ox).abs() + (y - oy).abs();
          if (d < minDistToOwn) minDistToOwn = d;
        }
        if (minDistToOwn > closeRadius) continue;
        candidates.add((x, y));
      }
    }
    if (candidates.isEmpty) {
      final (cx, cy) = continentSeed;
      const jitter = 2;
      final jx = (cx + rnd.nextInt(jitter * 2 + 1) - jitter).clamp(0, params.width - 1);
      final jy = (cy + rnd.nextInt(jitter * 2 + 1) - jitter).clamp(0, params.height - 1);
      return (jx, jy);
    }
    var bestScore = -1e100;
    final bestCandidates = <(int x, int y)>[];
    for (final (x, y) in candidates) {
      var minDistToOwn = params.width + params.height;
      for (final (ox, oy) in ownLandOrSeed) {
        final d = (x - ox).abs() + (y - oy).abs();
        if (d < minDistToOwn) minDistToOwn = d;
      }
      var minDistToOther = params.width + params.height;
      for (var ny = 0; ny < params.height; ny++) {
        for (var nx = 0; nx < params.width; nx++) {
          if (continentGrid[ny][nx] >= 0 && continentGrid[ny][nx] != c) {
            final d = (x - nx).abs() + (y - ny).abs();
            if (d < minDistToOther) minDistToOther = d;
          }
        }
      }
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
    for (var c = 0; c < numContinents; c++) {
      var start = landSeeds.length;
      var end = 0;
      for (var i = 0; i < landSeeds.length; i++) {
        if (continentBySeedIndex[i] == c) {
          if (i < start) start = i;
          end = i + 1;
        }
      }
      seedStartByContinent[c] = start;
      seedEndByContinent[c] = end;
    }

    final entries = <(double effectiveD2, int x, int y, int continent)>[];
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        var bestD2 = 1e100;
        var bestC = 0;
        for (var c = 0; c < numContinents; c++) {
          final start = seedStartByContinent[c];
          final end = seedEndByContinent[c];
          var d2 = 0x7FFFFFFFFFFFFFFF;
          for (var i = start; i < end; i++) {
            final (sx, sy) = landSeeds[i];
            final dd = (x - sx) * (x - sx) + (y - sy) * (y - sy);
            if (dd < d2) d2 = dd;
          }
          final noise = params.voronoiNoiseScale > 0
              ? _deterministicNoise(params.seed, x, y) * params.voronoiNoiseScale
              : 0.0;
          final effective = d2.toDouble() + noise;
          if (effective < bestD2) {
            bestD2 = effective;
            bestC = c;
          }
        }
        entries.add((bestD2, x, y, bestC));
      }
    }
    entries.sort((a, b) => a.$1.compareTo(b.$1));

    final next = grid.map((row) => row.toList()).toList();
    final nextContinent = continentGrid.map((row) => row.toList()).toList();
    final used = List<int>.filled(numContinents, 0);
    final buffer = params.continentBufferTiles == 0 ? 1 : params.continentBufferTiles;
    final offsets = _bufferOffsets(buffer);
    for (final (_, x, y, c) in entries) {
      if (next[y][x] == _landSentinel) continue;
      if (used[c] >= budgetPerContinent[c]) continue;
      var wouldJoin = false;
      for (final (dx, dy) in offsets) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx >= 0 && nx < params.width && ny >= 0 && ny < params.height) {
          final nc = nextContinent[ny][nx];
          if (nc >= 0 && nc != c) {
            wouldJoin = true;
            break;
          }
        }
      }
      if (wouldJoin) continue;
      next[y][x] = _landSentinel;
      nextContinent[y][x] = c;
      used[c]++;
    }
    return (next, nextContinent);
  }

  /// Grow coastlines at random; do not bring land within buffer of another continent.
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
    for (var c = 0; c < numContinents; c++) coastalByContinent[c] = [];

    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (g[y][x] != _landSentinel) continue;
        final c = cg[y][x];
        if (c < 0) continue;
        for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
          final nx = x + dx;
          final ny = y + dy;
          if (nx >= 0 && nx < params.width && ny >= 0 && ny < params.height &&
              g[ny][nx] == seaZoneId) {
            coastalByContinent[c]!.add((nx, ny));
            break;
          }
        }
      }
    }

    final budgetPerContinent = List<int>.filled(numContinents, 0);
    var allocated = 0;
    for (var c = 0; c < numContinents; c++) {
      budgetPerContinent[c] = (remaining * provincesByContinent[c]!.length / totalProvinces).round();
      allocated += budgetPerContinent[c];
    }
    if (allocated < remaining && numContinents > 0) budgetPerContinent[0] += remaining - allocated;

    var added = 0;
    const maxAttempts = 10000;
    var attempts = 0;
    while (added < remaining && attempts < maxAttempts) {
      attempts++;
      for (var c = 0; c < numContinents; c++) {
        if (budgetPerContinent[c] <= 0) continue;
        final coastal = coastalByContinent[c]!;
        if (coastal.isEmpty) continue;
        final (sx, sy) = coastal[rnd.nextInt(coastal.length)];
        if (g[sy][sx] != seaZoneId) continue;
        final buffer = params.continentBufferTiles == 0 ? 1 : params.continentBufferTiles;
        final offsets = _bufferOffsets(buffer);
        var wouldJoin = false;
        for (final (dx, dy) in offsets) {
          final nx = sx + dx;
          final ny = sy + dy;
          if (nx >= 0 && nx < params.width && ny >= 0 && ny < params.height) {
            final nc = cg[ny][nx];
            if (nc >= 0 && nc != c) {
              wouldJoin = true;
              break;
            }
          }
        }
        if (wouldJoin) continue;
        g[sy][sx] = _landSentinel;
        cg[sy][sx] = c;
        budgetPerContinent[c]--;
        added++;
        coastalByContinent[c]!.removeWhere((p) => p.$1 == sx && p.$2 == sy);
        for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
          final nx = sx + dx;
          final ny = sy + dy;
          if (nx >= 0 && nx < params.width && ny >= 0 && ny < params.height &&
              g[ny][nx] == seaZoneId && !coastalByContinent[c]!.contains((nx, ny))) {
            coastalByContinent[c]!.add((nx, ny));
          }
        }
        break;
      }
    }
    return (g, cg);
  }

  /// Box-Muller transform: returns a standard normal sample.
  double _nextGaussian(Random rnd) {
    var u1 = rnd.nextDouble();
    var u2 = rnd.nextDouble();
    while (u1 <= 0) u1 = rnd.nextDouble();
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }

  /// Per-continent land budget; assign to _landSentinel by smallest effective distance (with optional Voronoi noise). Each cell at most one continent.
  List<List<String>> _assignLandByLandSeeds(
    List<List<String>> grid,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
    Map<String, int> provinceToContinent,
    String seaZoneId,
  ) {
    if (landSeeds.isEmpty) return grid;
    final landBudgetTotal = ((1 - params.seaFraction) * params.width * params.height).round();
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
    for (var c = 0; c < numContinents; c++) {
      var start = landSeeds.length;
      var end = 0;
      for (var i = 0; i < landSeeds.length; i++) {
        if (continentBySeedIndex[i] == c) {
          if (i < start) start = i;
          end = i + 1;
        }
      }
      seedStartByContinent[c] = start;
      seedEndByContinent[c] = end;
    }

    final entries = <(double effectiveD2, int x, int y, int continent)>[];
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        var bestD2 = 1e100;
        var bestC = 0;
        for (var c = 0; c < numContinents; c++) {
          final start = seedStartByContinent[c];
          final end = seedEndByContinent[c];
          var d2 = 0x7FFFFFFFFFFFFFFF;
          for (var i = start; i < end; i++) {
            final (sx, sy) = landSeeds[i];
            final dd = (x - sx) * (x - sy) * (x - sx) + (y - sy) * (y - sy);
            if (dd < d2) d2 = dd;
          }
          final noise = params.voronoiNoiseScale > 0
              ? _deterministicNoise(params.seed, x, y) * params.voronoiNoiseScale
              : 0.0;
          final effective = d2.toDouble() + noise;
          if (effective < bestD2) {
            bestD2 = effective;
            bestC = c;
          }
        }
        entries.add((bestD2, x, y, bestC));
      }
    }
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

  /// Deterministic noise in [-1, 1] for Voronoi boundary irregularity.
  double _deterministicNoise(int seed, int x, int y) {
    var h = (seed * 31 + x) * 31 + y;
    h = (h ^ (h >> 16)) * 0x85ebca6b;
    h = (h ^ (h >> 13)) * 0xc2b2ae35;
    h = h ^ (h >> 16);
    return (h & 0x7FFFFFFF) / 0x7FFFFFFF * 2 - 1;
  }

  /// Ocean = sea cells reachable from grid boundary. Lake = sea not in ocean.
  Set<(int x, int y)> _oceanCells(List<List<String>> grid, String seaZoneId) {
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
      if (params.width > 1 && grid[y][params.width - 1] == seaZoneId &&
          !ocean.contains((params.width - 1, y))) {
        ocean.add((params.width - 1, y));
        queue.add((params.width - 1, y));
      }
    }
    while (queue.isNotEmpty) {
      final (x, y) = queue.removeLast();
      for (final (nx, ny) in [
        (x - 1, y),
        (x + 1, y),
        (x, y - 1),
        (x, y + 1),
      ]) {
        if (nx >= 0 && nx < params.width && ny >= 0 && ny < params.height &&
            grid[ny][nx] == seaZoneId && !ocean.contains((nx, ny))) {
          ocean.add((nx, ny));
          queue.add((nx, ny));
        }
      }
    }
    return ocean;
  }

  /// Continent index for a land cell from nearest land seed. Returns 0 when seeds empty.
  int _continentForLandCell(
    int x,
    int y,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
  ) {
    if (landSeeds.isEmpty) return 0;
    var bestSeedIndex = 0;
    var bestD2 = 0x7FFFFFFFFFFFFFFF;
    for (var i = 0; i < landSeeds.length; i++) {
      final (sx, sy) = landSeeds[i];
      final d2 = (x - sx) * (x - sx) + (y - sy) * (y - sy);
      if (d2 < bestD2) {
        bestD2 = d2;
        bestSeedIndex = i;
      }
    }
    return continentBySeedIndex[bestSeedIndex];
  }

  /// Fill lakes: convert lake (sea not in ocean) to land; skip lakes that border 2+ continents (straits).
  List<List<String>> _fillLakes(
    List<List<String>> grid,
    String seaZoneId,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
  ) {
    final ocean = _oceanCells(grid, seaZoneId);
    final next = grid.map((row) => row.toList()).toList();
    final lakeCells = <(int x, int y)>[];
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] != seaZoneId) continue;
        if (ocean.contains((x, y))) continue;
        lakeCells.add((x, y));
      }
    }
    final lakeComponents = _connectedComponentsOfLand(lakeCells.toSet());
    var lakesFilled = 0;
    final coastalLandCandidates = <(int x, int y)>{};
    for (final component in lakeComponents) {
      final borderingLand = <(int x, int y)>{};
      for (final (x, y) in component) {
        for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
          final nx = x + dx;
          final ny = y + dy;
          if (nx >= 0 && nx < params.width && ny >= 0 && ny < params.height &&
              grid[ny][nx] != seaZoneId) {
            borderingLand.add((nx, ny));
          }
        }
      }
      final continentsBordering = <int>{};
      for (final (lx, ly) in borderingLand) {
        continentsBordering.add(_continentForLandCell(lx, ly, landSeeds, continentBySeedIndex));
      }
      if (continentsBordering.length >= 2) continue;
      for (final (x, y) in component) {
        next[y][x] = _landSentinel;
        lakesFilled++;
        for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
          final nx = x + dx;
          final ny = y + dy;
          if (nx >= 0 && nx < params.width && ny >= 0 && ny < params.height &&
              next[ny][nx] == seaZoneId &&
              _oceanNeighbourCount(next, nx, ny, seaZoneId, ocean) >= 1) {
            coastalLandCandidates.add((nx, ny));
          }
        }
      }
    }
    final sorted = coastalLandCandidates.toList()
      ..sort((a, b) {
        final na = _oceanNeighbourCount(next, a.$1, a.$2, seaZoneId, ocean);
        final nb = _oceanNeighbourCount(next, b.$1, b.$2, seaZoneId, ocean);
        return nb.compareTo(na);
      });
    for (final (fx, fy) in sorted.take(lakesFilled)) {
      next[fy][fx] = seaZoneId;
    }
    return next;
  }

  int _oceanNeighbourCount(List<List<String>> grid, int x, int y, String seaZoneId,
      Set<(int x, int y)> ocean) {
    var n = 0;
    for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx >= 0 && nx < params.width && ny >= 0 && ny < params.height &&
          grid[ny][nx] == seaZoneId && ocean.contains((nx, ny))) n++;
    }
    return n;
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
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] != _landSentinel) continue;
        var bestSeedIndex = 0;
        var bestD2 = 0x7FFFFFFFFFFFFFFF;
        for (var i = 0; i < landSeeds.length; i++) {
          final (sx, sy) = landSeeds[i];
          final d2 = (x - sx) * (x - sx) + (y - sy) * (y - sy);
          if (d2 < bestD2) {
            bestD2 = d2;
            bestSeedIndex = i;
          }
        }
        final c = continentBySeedIndex[bestSeedIndex];
        byContinent[c]!.add((x, y));
      }
    }
    return byContinent;
  }

  /// Place one province seed per province on that continent's land cells; min spacing.
  Map<String, (int x, int y)> _placeProvinceSeedsOnLand(
    List<List<String>> grid,
    Map<String, int> provinceToContinent,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
    String seaZoneId,
    Random rnd,
  ) {
    if (provinceToContinent.isEmpty) return {};
    final numContinents = provinceToContinent.values.toSet().length;
    final byContinent = _landCellsByContinent(grid, landSeeds, continentBySeedIndex);
    final seeds = <String, (int x, int y)>{};
    const minDist = 3;
    for (var c = 0; c < numContinents; c++) {
      final cells = byContinent[c] ?? [];
      if (cells.isEmpty) continue;
      final provinceIds = provinceToContinent.entries
          .where((e) => e.value == c)
          .map((e) => e.key)
          .toList()
        ..sort();
      final used = <(int x, int y)>{};
      for (final provinceId in provinceIds) {
        final shuffled = List<(int x, int y)>.from(cells)..shuffle(rnd);
        for (final (x, y) in shuffled) {
          if (used.any((p) => (p.$1 - x).abs() < minDist && (p.$2 - y).abs() < minDist)) continue;
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
  List<List<String>> _assignProvincesFromSeeds(
    List<List<String>> grid,
    Map<String, (int x, int y)> provinceSeeds,
    String seaZoneId,
  ) {
    if (provinceSeeds.isEmpty) return grid;
    final landCells = <(int x, int y)>[];
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] == _landSentinel) landCells.add((x, y));
      }
    }
    final assignment = assignCellsToNearestSeed(
      landCells,
      provinceSeeds,
      noiseScale: 0,
      noiseSeed: params.seed,
    );
    final next = grid.map((row) => row.toList()).toList();
    for (final entry in assignment.entries) {
      final (x, y) = entry.key;
      next[y][x] = entry.value;
    }
    return next;
  }

  /// Border noise: swap only at land/sea boundary (sentinel vs seaZoneId).
  List<List<String>> _borderNoise(List<List<String>> grid, String seaZoneId, Random rnd) {
    final next = grid.map((row) => row.toList()).toList();
    for (var y = 1; y < params.height - 1; y++) {
      for (var x = 1; x < params.width - 1; x++) {
        if (rnd.nextDouble() >= params.borderNoise) continue;
        final id = grid[y][x];
        final neighbors = [
          (x - 1, y),
          (x + 1, y),
          (x, y - 1),
          (x, y + 1),
        ];
        for (final (nx, ny) in neighbors) {
          final nid = grid[ny][nx];
          final atBoundary = (id == _landSentinel && nid == seaZoneId) ||
              (id == seaZoneId && nid == _landSentinel);
          if (atBoundary) {
            next[ny][nx] = id;
            next[y][x] = nid;
            break;
          }
        }
      }
    }
    return next;
  }
}

