/// Pass 6a: mountain-ridge placement via random walks over land cells.
///
/// Extracted from the `part of 'tile_map_generator.dart'` terrain fragment into
/// a standalone, independently importable strategy class injected into
/// [TileMapGenTerrainResource] (Refs #3588). Constructor-injected
/// [TileMapParams] replaces the former shared-scope access; pure relocation
/// otherwise (no logic, iteration order, or RNG-sequence change).
library;

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';

import '../tile_map_directions.dart';
import '../tile_map_grid.dart';
import 'tile_map_land_sentinel.dart';
import 'tile_map_params.dart';

/// Pass 6a mountain-ridge placement strategy.
class MountainRidgePlacer {
  const MountainRidgePlacer(this.params);

  final TileMapParams params;

  /// Pass 6a: generate mountain ridges via random walks over land cells.
  /// Returns non-mountain land cells for pass 6b (one scan shared with top-up).
  List<(int x, int y)> assignMountainRidges(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    List<(int x, int y)> landCells,
    TerrainDistribution distribution,
    Random rnd,
  ) {
    final totalLand = landCells.length;
    if (totalLand == 0) return const [];
    final targetMountain = (distribution.mountainFraction * totalLand)
        .round()
        .clamp(0, totalLand);
    if (targetMountain <= 0) {
      return _nonMountainLandFromCells(landCells, terrainGrid);
    }

    // Determine number of ranges based on target mountain tiles.
    final suggestedRanges = (params.mountainRangesFactor * sqrt(targetMountain))
        .round()
        .clamp(params.mountainRangesMin, params.mountainRangesMax);
    final numRanges = suggestedRanges.clamp(1, targetMountain);
    if (numRanges <= 0) {
      return _nonMountainLandFromCells(landCells, terrainGrid);
    }

    var remainingMountain = targetMountain;

    // Helper to pick a start cell biased away from edges and existing mountains.
    (int x, int y)? pickStart() {
      const maxAttempts = 1000;
      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        final (cx, cy) = landCells[rnd.nextInt(landCells.length)];
        if (terrainGrid[cy][cx] == TerrainType.mountain) continue;
        // Prefer interior cells (not on border).
        if (cx <= 0 ||
            cx >= params.width - 1 ||
            cy <= 0 ||
            cy >= params.height - 1) {
          // Still acceptable, but try to find interior cells first.
          if (rnd.nextDouble() < 0.7) continue;
        }
        return (cx, cy);
      }
      return null;
    }

    // 4-connected directions: up, right, down, left.
    const directions = kTileMapDirections4;

    for (var r = 0; r < numRanges && remainingMountain > 0; r++) {
      final start = pickStart();
      if (start == null) break;
      var (x, y) = start;
      terrainGrid[y][x] = TerrainType.mountain;
      remainingMountain--;

      // Target length per range, clipped by remaining budget and minimum.
      final idealLength = (targetMountain / numRanges).round();
      final maxLengthForRange = idealLength.clamp(
        params.mountainRangeMinLength,
        targetMountain,
      );
      var placedThisRange = 1;

      var dir = directions[rnd.nextInt(directions.length)];

      while (placedThisRange < maxLengthForRange && remainingMountain > 0) {
        final step = _extendMountainRandomWalkOnce(
          terrainGrid,
          grid,
          rnd,
          x,
          y,
          dir,
          directions,
        );
        if (step == null) break;
        x = step.$1;
        y = step.$2;
        dir = step.$3;
        terrainGrid[y][x] = TerrainType.mountain;
        placedThisRange++;
        remainingMountain--;
      }
    }

    // If we significantly undershot the target due to blocking or early
    // termination of ranges, top up mountain tiles by growing existing ridges
    // along their edges. This keeps the overall pattern ridge-like while
    // nudging the global count closer to the configured fraction.
    var scan = _scanPostMountainLand(terrainGrid, grid, directions);
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

    // As a final fallback, if we still undershoot (e.g. very small maps with
    // fragmented land), convert random remaining land cells until we reach
    // the target. This should be rare and only adjusts a handful of tiles.
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

  /// Single random-walk step for mountain ridge growth; returns updated
  /// position and direction, or `null` if the range cannot extend further.
  (int x, int y, (int, int) dir)? _extendMountainRandomWalkOnce(
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

  void _addMountainAdjacentFrontierFromCell(
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

  /// One full-grid pass after mountain placement: count, ridge-adjacent frontier,
  /// and remaining non-mountain land (Refs #2489 P3).
  ({
    int mountainCount,
    Set<(int x, int y)> mountainAdjacentFrontier,
    List<(int x, int y)> remainingNonMountainLand,
  })
  _scanPostMountainLand(
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
        _addMountainAdjacentFrontierFromCell(
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

  /// Non-mountain subset of [landCells] (O(|land|); avoids full-grid scan when
  /// mountain ridges are skipped). Refs #2489 (P3).
  List<(int x, int y)> _nonMountainLandFromCells(
    List<(int x, int y)> landCells,
    List<List<TerrainType?>> terrainGrid,
  ) {
    return [
      for (final (x, y) in landCells)
        if (terrainGrid[y][x] != TerrainType.mountain) (x, y),
    ];
  }
}
