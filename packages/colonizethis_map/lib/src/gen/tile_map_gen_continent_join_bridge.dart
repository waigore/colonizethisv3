/// Bridge-cell apply and sea-fraction preservation for continent joining.
/// SPEC/program/tile-map-gen-algorithm.md.
library;

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';

import '../tile_map_grid.dart';
import 'tile_map_grid_graph.dart';
import 'tile_map_resource_cap_state.dart';
import 'tile_map_resource_placement.dart';

/// Applies a carved sea bridge as land cells of [provinceId].
void applyContinentJoinBridgePathCells({
  required List<List<String>> grid,
  required List<(int x, int y)> path,
  required String provinceId,
  required List<List<TerrainType?>>? terrainGrid,
  required List<List<Resource?>>? resourceGrid,
  required String? mapRegionId,
  required ResourceRules? resourceRules,
  required Random rnd,
  MultiRegionCapState? capState,
}) {
  for (final (x, y) in path) {
    grid[y][x] = provinceId;
    if (terrainGrid != null &&
        resourceGrid != null &&
        mapRegionId != null &&
        resourceRules != null) {
      assignTerrainAndResourceForJoinedCell(
        terrainGrid: terrainGrid,
        resourceGrid: resourceGrid,
        x: x,
        y: y,
        mapRegionId: mapRegionId,
        rules: resourceRules,
        rnd: rnd,
        capState: capState,
      );
    }
  }
}

void assignTerrainAndResourceForJoinedCell({
  required List<List<TerrainType?>> terrainGrid,
  required List<List<Resource?>> resourceGrid,
  required int x,
  required int y,
  required String mapRegionId,
  required ResourceRules rules,
  required Random rnd,
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
/// first) to preserve the overall sea fraction after a join.
List<(int x, int y)> preserveSeaFractionAfterJoin({
  required List<List<String>> grid,
  required List<List<TerrainType?>>? terrainGrid,
  required List<List<Resource?>>? resourceGrid,
  required String seaZoneId,
  required Set<(int x, int y)> ocean,
  required int count,
  required TileMapGridGraph graph,
  Set<(int x, int y)>? landCellsExcludedFromSeaRestore,
}) {
  // One ocean-neighbour count per candidate; reuse for sort keys (Refs #2489).
  final coastal = <(int x, int y, int oceanNeighbours)>[];
  TileMapGrid.forEachCell(grid, (y, x, value) {
    if (value == seaZoneId) return;
    if (landCellsExcludedFromSeaRestore?.contains((x, y)) ?? false) {
      return;
    }
    final n = graph.oceanNeighbourCount(grid, x, y, seaZoneId, ocean);
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
