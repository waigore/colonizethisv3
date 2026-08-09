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

import 'map_gen_pass_payloads.dart';
import 'map_gen_stage.dart';
import 'tile_map_gen_continent_join_bridge.dart';
import 'tile_map_gen_continent_join_path.dart';
import 'tile_map_grid_graph.dart';
import 'tile_map_params.dart';
import 'tile_map_resource_cap_state.dart';

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
    var landCellsByContinent = buildLandCellsByContinentIndex(
      grid: g,
      membership: provinceToContinent,
      seaZoneId: seaZoneId,
      numContinents: numContinents,
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
        final path = shortestSeaPathBetweenLandComponents(
          grid: g,
          seaZoneId: seaZoneId,
          compA: compA,
          compB: compB,
          width: params.width,
          height: params.height,
        );
        if (path.isEmpty) break;
        final provinceId = provinceIdAdjacentToSeaPath(
          grid: g,
          compA: compA,
          path: path,
          width: params.width,
          height: params.height,
        );
        final bridgeCells = path.toSet();
        applyContinentJoinBridgePathCells(
          grid: g,
          path: path,
          provinceId: provinceId,
          terrainGrid: tg,
          resourceGrid: rg,
          mapRegionId: mapRegionId,
          resourceRules: resourceRules,
          rnd: rnd,
          capState: capState,
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
        removeCellsFromAllContinents(
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
    return preserveSeaFractionAfterJoin(
      grid: grid,
      terrainGrid: terrainGrid,
      resourceGrid: resourceGrid,
      seaZoneId: seaZoneId,
      ocean: ocean,
      count: count,
      graph: _graph,
      landCellsExcludedFromSeaRestore: landCellsExcludedFromSeaRestore,
    );
  }
}
