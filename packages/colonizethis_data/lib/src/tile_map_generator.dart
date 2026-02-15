// SPEC/program/tile-map-generation.md. Reference: SPEC/ideas/tile-based-map-generation.md.

import 'dart:math';

import 'map_topology.dart';
import 'resource.dart';
import 'resource_rules.dart';
import 'terrain_type.dart';
import 'tile_map_result.dart';
import 'topology_node.dart';

/// Parameters for tile-based map generation.
class TileMapParams {
  const TileMapParams({
    this.width = 100,
    this.height = 100,
    this.seed = 42,
    this.borderNoise = 0.0,
    this.maxEnforceIterations = 10,
  });

  final int width;
  final int height;
  final int seed;
  /// 0–1; 0 = no border noise.
  final double borderNoise;
  final int maxEnforceIterations;
}

/// Generates a per-region tile map from topology. SPEC/program/tile-map-generation.md.
class TileMapGenerator {
  TileMapGenerator({this.params = const TileMapParams()});

  final TileMapParams params;

  /// Generate a tile map for the given topology.
  /// If [resourceRules] is provided, assigns terrain and optional resource per land cell (step 4).
  TileMapResult generate(MapTopology topology, {ResourceRules? resourceRules}) {
    if (topology.nodes.isEmpty) {
      throw ArgumentError('Topology must have at least one node');
    }
    final rnd = Random(params.seed);

    // 1. Graph embedding + 2. Seed placement: place each node at a grid position; resolve overlaps
    final seeds = _placeSeeds(topology, rnd);

    // 3. Region assignment (Voronoi-style): each cell to closest seed
    var grid = _assignRegions(topology, seeds);

    // 4. Topology enforcement: ensure grid adjacencies match graph
    for (var i = 0; i < params.maxEnforceIterations; i++) {
      final result = TileMapResult(width: params.width, height: params.height, grid: grid);
      final missing = _missingAdjacencies(topology, result);
      if (missing.isEmpty) break;
      grid = _fixMissingAdjacencies(topology, grid, missing, seeds);
    }

    // 5. Border randomization (optional)
    if (params.borderNoise > 0) {
      grid = _borderNoise(grid, rnd);
    }

    // 6. Terrain and resource assignment (per SPEC: inverse proportion to default market price)
    List<List<TerrainType?>>? terrainGrid;
    List<List<Resource?>>? resourceGrid;
    if (resourceRules != null) {
      final t = _assignTerrainAndResources(topology, grid, resourceRules, rnd);
      terrainGrid = t.$1;
      resourceGrid = t.$2;
    }

    return TileMapResult(
      width: params.width,
      height: params.height,
      grid: grid,
      terrainGrid: terrainGrid,
      resourceGrid: resourceGrid,
    );
  }

  (List<List<TerrainType?>>, List<List<Resource?>>) _assignTerrainAndResources(
    MapTopology topology,
    List<List<String>> grid,
    ResourceRules rules,
    Random rnd,
  ) {
    final nodeById = {for (final n in topology.nodes) n.id: n};
    final landTerrains = TerrainType.values;
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
        final regionId = grid[y][x];
        final node = nodeById[regionId];
        if (node == null || node.type == TopologyNodeType.seaZone) {
          terrainGrid[y][x] = null;
          resourceGrid[y][x] = null;
          continue;
        }
        // Land: assign terrain
        terrainGrid[y][x] = landTerrains[rnd.nextInt(landTerrains.length)];
        final terrain = terrainGrid[y][x]!;
        // With probability place a resource from allowed set; weight = inverse to price
        final allowed = Resource.values
            .where((r) =>
                rules.isAllowedInRegion(r, node.regionId) &&
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

  Map<String, (int x, int y)> _placeSeeds(MapTopology topology, Random rnd) {
    final n = topology.nodes.length;
    final seeds = <String, (int x, int y)>{};
    final used = <(int, int)>{};
    const minDist = 3;
    for (final node in topology.nodes) {
      for (var attempt = 0; attempt < 200; attempt++) {
        final x = rnd.nextInt(params.width);
        final y = rnd.nextInt(params.height);
        var ok = true;
        for (final (ox, oy) in used) {
          if ((x - ox).abs() < minDist && (y - oy).abs() < minDist) {
            ok = false;
            break;
          }
        }
        if (ok) {
          seeds[node.id] = (x, y);
          used.add((x, y));
          break;
        }
      }
      if (!seeds.containsKey(node.id)) {
        var x = rnd.nextInt(params.width);
        var y = rnd.nextInt(params.height);
        while (used.contains((x, y))) {
          x = (x + 1) % params.width;
          if (x == 0) y = (y + 1) % params.height;
        }
        seeds[node.id] = (x, y);
        used.add((x, y));
      }
    }
    return seeds;
  }

  List<List<String>> _assignRegions(MapTopology topology, Map<String, (int x, int y)> seeds) {
    final grid = List.generate(
      params.height,
      (_) => List.filled(params.width, topology.nodes.first.id),
    );
    final ids = topology.nodes.map((n) => n.id).toList();
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        var bestId = ids.first;
        var bestDist = 1e9;
        for (final id in ids) {
          final (sx, sy) = seeds[id]!;
          final d = (x - sx) * (x - sx) + (y - sy) * (y - sy);
          if (d < bestDist) {
            bestDist = d.toDouble();
            bestId = id;
          }
        }
        grid[y][x] = bestId;
      }
    }
    return grid;
  }

  Set<String> _requiredPairs(MapTopology topology) {
    final pairs = <String>{};
    for (final e in topology.edges) {
      pairs.add(e.id1.compareTo(e.id2) < 0 ? '${e.id1}|${e.id2}' : '${e.id2}|${e.id1}');
    }
    return pairs;
  }

  Set<String> _missingAdjacencies(MapTopology topology, TileMapResult result) {
    final required = _requiredPairs(topology);
    final actual = result.adjacentRegionPairs();
    return required.difference(actual);
  }

  List<List<String>> _fixMissingAdjacencies(
    MapTopology topology,
    List<List<String>> grid,
    Set<String> missing,
    Map<String, (int x, int y)> seeds,
  ) {
    final next = grid.map((row) => row.toList()).toList();
    for (final pair in missing) {
      final parts = pair.split('|');
      if (parts.length != 2) continue;
      final id1 = parts[0];
      final id2 = parts[1];
      final (x1, y1) = seeds[id1]!;
      final (x2, y2) = seeds[id2]!;
      _carvePath(next, x1, y1, id1, x2, y2, id2);
    }
    return next;
  }

  void _carvePath(List<List<String>> grid, int x1, int y1, String id1, int x2, int y2, String id2) {
    // Simple line carve: reassign cells along a path from (x1,y1) to (x2,y2) to alternate id1/id2
    final steps = (x2 - x1).abs() + (y2 - y1).abs();
    if (steps == 0) return;
    for (var t = 0; t <= steps; t++) {
      final frac = steps > 0 ? t / steps : 1.0;
      final x = (x1 + (x2 - x1) * frac).round().clamp(0, params.width - 1);
      final y = (y1 + (y2 - y1) * frac).round().clamp(0, params.height - 1);
      grid[y][x] = t.isEven ? id1 : id2;
    }
  }

  List<List<String>> _borderNoise(List<List<String>> grid, Random rnd) {
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
          if (grid[ny][nx] != id) {
            next[ny][nx] = id;
            next[y][x] = grid[ny][nx];
            break;
          }
        }
      }
    }
    return next;
  }
}
