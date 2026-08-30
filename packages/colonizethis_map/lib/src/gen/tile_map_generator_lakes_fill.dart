/// Pass 4 lake fill (Refs #4654).
///
/// SPEC/program/tile-map-gen-algorithm.md.
library;

import '../tile_map_directions.dart';
import '../tile_map_grid.dart';
import 'tile_map_grid_graph.dart';
import 'tile_map_land_sentinel.dart';
import 'tile_map_params.dart';

/// Lake conversion: enclosed sea (not ocean) to land, then restore sea fraction.
class TileMapGenLakesFill {
  TileMapGenLakesFill(this.params, this.graph);

  final TileMapParams params;
  final TileMapGridGraph graph;

  void addCoastalLandCandidatesAroundLakeCell(
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
          graph.oceanNeighbourCount(next, nx, ny, seaZoneId, ocean) >= 1) {
        coastalLandCandidates.add((nx, ny));
      }
    }
  }

  Set<(int x, int y)> resolveOceanCells(
    List<List<String>> grid,
    String seaZoneId,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex, {
    Set<(int x, int y)>? ocean,
  }) {
    return ocean ??
        graph.oceanCells(grid, seaZoneId, landSeeds, continentBySeedIndex);
  }

  /// Fill lakes: convert lake (sea not in ocean) to land; skip lakes that
  /// border 2+ continents (straits).
  List<List<String>> fillLakes(
    List<List<String>> grid,
    String seaZoneId,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex, {
    Set<(int x, int y)>? ocean,
  }) {
    final resolvedOcean = resolveOceanCells(
      grid,
      seaZoneId,
      landSeeds,
      continentBySeedIndex,
      ocean: ocean,
    );
    final next = TileMapGrid.copy(grid);
    final lakeCells = <(int x, int y)>[];
    TileMapGrid.forEachIndex(params.height, params.width, (y, x) {
      if (grid[y][x] != seaZoneId) return;
      if (resolvedOcean.contains((x, y))) return;
      lakeCells.add((x, y));
    });
    final lakeComponents = graph.connectedComponentsOfLand(lakeCells.toSet());
    var lakesFilled = 0;
    final coastalLandCandidates = <(int x, int y)>{};
    for (final component in lakeComponents) {
      for (final (x, y) in component) {
        next[y][x] = kTileMapLandSentinel;
        lakesFilled++;
        addCoastalLandCandidatesAroundLakeCell(
          x,
          y,
          next,
          seaZoneId,
          resolvedOcean,
          coastalLandCandidates,
        );
      }
    }
    final sorted = coastalLandCandidates.toList()
      ..sort((a, b) {
        final na = graph.oceanNeighbourCount(
          next,
          a.$1,
          a.$2,
          seaZoneId,
          resolvedOcean,
        );
        final nb = graph.oceanNeighbourCount(
          next,
          b.$1,
          b.$2,
          seaZoneId,
          resolvedOcean,
        );
        return nb.compareTo(na);
      });
    for (final (fx, fy) in sorted.take(lakesFilled)) {
      next[fy][fx] = seaZoneId;
    }
    return next;
  }
}
