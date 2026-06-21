/// Pass 10: join continents by carving shortest sea-cell land bridges.
///
/// Extracted from the former `_TileMapGenJoinSea` bridge fragment into a
/// standalone [MapGenPass] family (Refs #3588). Constructor-injected
/// dependencies replace the previous `part of` library-scope coupling so the
/// pass is testable in isolation. SPEC/program/tile-map-gen-algorithm.md.
library;

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/package_logger.dart';

import '../tile_map_directions.dart';
import '../tile_map_grid.dart';
import 'map_gen_pass_payloads.dart';
import 'map_gen_stage.dart';
import 'tile_map_grid_graph.dart';
import 'tile_map_params.dart';
import 'tile_map_resource_cap_state.dart';
import 'tile_map_resource_placement.dart';

/// Pass 10 continent-joining service.
///
/// For each continent with more than one land component, connects two
/// components with a shortest path of sea cells and preserves the overall sea
/// fraction by restoring an equal number of coastal land tiles to sea.
class ContinentJoinPass
    implements MapGenPass<ContinentJoinPassPayload, ContinentJoinPassResult> {
  ContinentJoinPass(this.params, this._log, this._graph);

  @override
  final TileMapParams params;
  final CtLogger _log;
  final TileMapGridGraph _graph;

  /// Uniform pass entry: runs continent joining when [TileMapParams.joinContinents]
  /// is set, otherwise returns the inputs unchanged (Refs #3588).
  @override
  ContinentJoinPassResult run(MapGenPassContext<ContinentJoinPassPayload> ctx) {
    final payload = ctx.payload;
    if (!params.joinContinents) {
      return ContinentJoinPassResult(
        grid: payload.grid,
        terrainGrid: payload.terrainGrid,
        resourceGrid: payload.resourceGrid,
        didJoin: false,
      );
    }
    final (g, tg, rg, didJoin) = joinContinents(
      payload.grid,
      payload.terrainGrid,
      payload.resourceGrid,
      payload.provinceToContinent,
      payload.seaZoneId,
      payload.mapRegionId,
      payload.landSeeds,
      payload.continentBySeedIndex,
      payload.resourceRules,
      payload.rnd,
    );
    if (didJoin) {
      ctx.log('Pass 10: Join continents (land bridges added)');
    }
    return ContinentJoinPassResult(
      grid: g,
      terrainGrid: tg,
      resourceGrid: rg,
      didJoin: didJoin,
    );
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
        _removeCellsFromAllContinents(
          landCellsByContinent,
          restoredToSea,
          numContinents,
        );
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

  /// Drops every cell in [cells] from each continent's land-cell set (used after
  /// [preserveSeaFraction] restores coastal land back to sea). Extracted to keep
  /// [joinContinents] control-flow nesting within policy.
  void _removeCellsFromAllContinents(
    List<Set<(int x, int y)>> landCellsByContinent,
    List<(int x, int y)> cells,
    int numContinents,
  ) {
    for (final (x, y) in cells) {
      for (var ci = 0; ci < numContinents; ci++) {
        landCellsByContinent[ci].remove((x, y));
      }
    }
  }

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

  /// Restore [count] coastal land tiles back to sea (highest ocean adjacency
  /// first) to preserve the overall sea fraction after a join. Shared with the
  /// lakes/moats pass. Returns the restored cell coordinates.
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
