/// Pass 6a mountain-ridge random-walk steps (Refs #4654).
///
/// SPEC/program/tile-map-gen-algorithm.md.
library;

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';

import 'tile_map_land_sentinel.dart';
import 'tile_map_params.dart';

/// Random-walk start pick and single-step ridge extension.
class MountainRidgeWalk {
  const MountainRidgeWalk(this.params);

  final TileMapParams params;

  (int x, int y)? pickStart(
    List<(int x, int y)> landCells,
    List<List<TerrainType?>> terrainGrid,
    Random rnd,
  ) {
    const maxAttempts = 1000;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final (cx, cy) = landCells[rnd.nextInt(landCells.length)];
      if (terrainGrid[cy][cx] == TerrainType.mountain) continue;
      if (cx <= 0 ||
          cx >= params.width - 1 ||
          cy <= 0 ||
          cy >= params.height - 1) {
        if (rnd.nextDouble() < 0.7) continue;
      }
      return (cx, cy);
    }
    return null;
  }

  (int x, int y, (int, int) dir)? extendMountainRandomWalkOnce(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    Random rnd,
    int x,
    int y,
    (int dx, int dy) dir,
    List<(int dx, int dy)> directions,
  ) {
    const pForward = 0.6;
    const pTurn = 0.3;
    const maxTurnRetries = 4;

    (int dx, int dy) pickDirection((int dx, int dy) current) {
      final roll = rnd.nextDouble();
      if (roll < pForward) return current;
      if (roll < pForward + pTurn) {
        final left = (-current.$2, current.$1);
        final right = (current.$2, -current.$1);
        return rnd.nextBool() ? left : right;
      }
      return directions[rnd.nextInt(directions.length)];
    }

    var attempts = 0;
    var d = dir;
    while (attempts < maxTurnRetries) {
      d = pickDirection(d);
      final nx = x + d.$1;
      final ny = y + d.$2;
      attempts++;
      if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
        continue;
      }
      if (grid[ny][nx] != kTileMapLandSentinel) continue;
      if (terrainGrid[ny][nx] == TerrainType.mountain) continue;
      return (nx, ny, d);
    }
    return null;
  }
}
