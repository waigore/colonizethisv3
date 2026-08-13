/// Pass 5 border noise (land/sea boundary swaps).
///
/// SPEC/program/tile-map-gen-algorithm.md. Extracted from
/// [TileMapGenLakesProvinces] for wave-6 headroom (Refs #4371).
library;

import 'dart:math';

import 'tile_map_land_sentinel.dart';
import 'tile_map_params.dart';
import '../tile_map_directions.dart';
import '../tile_map_grid.dart';

/// Border noise: swap only at land/sea boundary (sentinel vs [seaZoneId]).
List<List<String>> applyBorderNoise(
  TileMapParams params,
  List<List<String>> grid,
  String seaZoneId,
  Random rnd,
) {
  final next = TileMapGrid.copy(grid);
  // ct-lint-allow: nested-grid-walk — bordered interior walk (skips the grid
  // edge, y/x in 1..n-2), so the full-grid TileMapGrid.forEachIndex contract
  // does not apply.
  for (var y = 1; y < params.height - 1; y++) {
    for (var x = 1; x < params.width - 1; x++) {
      _tryBorderNoiseSwapAtCell(params, grid, next, x, y, seaZoneId, rnd);
    }
  }
  return next;
}

void _tryBorderNoiseSwapAtCell(
  TileMapParams params,
  List<List<String>> grid,
  List<List<String>> next,
  int x,
  int y,
  String seaZoneId,
  Random rnd,
) {
  if (rnd.nextDouble() >= params.borderNoise) return;
  final id = grid[y][x];
  for (final (dx, dy) in kTileMapDirections4WestEastNorthSouth) {
    final nx = x + dx;
    final ny = y + dy;
    final nid = grid[ny][nx];
    final atBoundary =
        (id == kTileMapLandSentinel && nid == seaZoneId) ||
        (id == seaZoneId && nid == kTileMapLandSentinel);
    if (atBoundary) {
      next[ny][nx] = id;
      next[y][x] = nid;
      break;
    }
  }
}
