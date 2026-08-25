/// Pass 6a mountain top-up after ridge walks (Refs #4654).
///
/// SPEC/program/tile-map-gen-algorithm.md.
library;

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';

import '../tile_map_grid.dart';
import 'tile_map_land_sentinel.dart';
import 'tile_map_params.dart';

/// Post-walk mountain count, ridge-adjacent frontier, and undershoot top-up.
class MountainRidgeTopUp {
  const MountainRidgeTopUp(this.params);

  final TileMapParams params;

  void addMountainAdjacentFrontierFromCell(
    int x,
    int y,
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    List<(int dx, int dy)> directions,
    Set<(int x, int y)> frontier,
  ) {
    for (final (dx, dy) in directions) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
        continue;
      }
      if (grid[ny][nx] != kTileMapLandSentinel) continue;
      if (terrainGrid[ny][nx] == TerrainType.mountain) continue;
      frontier.add((nx, ny));
    }
  }

  ({
    int mountainCount,
    Set<(int x, int y)> mountainAdjacentFrontier,
    List<(int x, int y)> remainingNonMountainLand,
  })
  scanPostMountainLand(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    List<(int dx, int dy)> directions,
  ) {
    var mountainCount = 0;
    final frontier = <(int x, int y)>{};
    final remaining = <(int x, int y)>[];
    TileMapGrid.forEachIndex(params.height, params.width, (y, x) {
      if (grid[y][x] != kTileMapLandSentinel) return;
      final terrain = terrainGrid[y][x];
      if (terrain == TerrainType.mountain) {
        mountainCount++;
        addMountainAdjacentFrontierFromCell(
          x,
          y,
          terrainGrid,
          grid,
          directions,
          frontier,
        );
      } else {
        remaining.add((x, y));
      }
    });
    return (
      mountainCount: mountainCount,
      mountainAdjacentFrontier: frontier,
      remainingNonMountainLand: remaining,
    );
  }

  List<(int x, int y)> applyTopUp(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    List<(int dx, int dy)> directions,
    int targetMountain,
    Random rnd,
  ) {
    var scan = scanPostMountainLand(terrainGrid, grid, directions);
    var currentMountain = scan.mountainCount;
    if (currentMountain >= targetMountain) {
      return scan.remainingNonMountainLand;
    }

    final frontierList = scan.mountainAdjacentFrontier.toList()..shuffle(rnd);
    var idx = 0;
    while (currentMountain < targetMountain && idx < frontierList.length) {
      final (fx, fy) = frontierList[idx++];
      if (terrainGrid[fy][fx] == TerrainType.mountain) continue;
      terrainGrid[fy][fx] = TerrainType.mountain;
      currentMountain++;
    }

    if (currentMountain < targetMountain) {
      final remainingLand = scan.remainingNonMountainLand
        ..removeWhere((c) => terrainGrid[c.$2][c.$1] == TerrainType.mountain);
      remainingLand.shuffle(rnd);
      var i = 0;
      while (currentMountain < targetMountain && i < remainingLand.length) {
        final (lx, ly) = remainingLand[i++];
        if (terrainGrid[ly][lx] == TerrainType.mountain) continue;
        terrainGrid[ly][lx] = TerrainType.mountain;
        currentMountain++;
      }
    }

    if (currentMountain > scan.mountainCount) {
      scan.remainingNonMountainLand.removeWhere(
        (c) => terrainGrid[c.$2][c.$1] == TerrainType.mountain,
      );
    }
    return scan.remainingNonMountainLand;
  }

  List<(int x, int y)> nonMountainLandFromCells(
    List<(int x, int y)> landCells,
    List<List<TerrainType?>> terrainGrid,
  ) {
    return [
      for (final (x, y) in landCells)
        if (terrainGrid[y][x] != TerrainType.mountain) (x, y),
    ];
  }
}
