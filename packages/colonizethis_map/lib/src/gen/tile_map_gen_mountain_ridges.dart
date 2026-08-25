/// Pass 6a: mountain-ridge placement via random walks over land cells.
///
/// Walk vs top-up live in sibling libraries (Refs #4654 Slice B).
library;

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';

import '../tile_map_directions.dart';
import 'tile_map_gen_mountain_ridges_topup.dart';
import 'tile_map_gen_mountain_ridges_walk.dart';
import 'tile_map_params.dart';

/// Pass 6a mountain-ridge placement strategy.
class MountainRidgePlacer {
  MountainRidgePlacer(this.params)
    : _walk = MountainRidgeWalk(params),
      _topUp = MountainRidgeTopUp(params);

  final TileMapParams params;
  final MountainRidgeWalk _walk;
  final MountainRidgeTopUp _topUp;

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
      return _topUp.nonMountainLandFromCells(landCells, terrainGrid);
    }

    final suggestedRanges = (params.mountainRangesFactor * sqrt(targetMountain))
        .round()
        .clamp(params.mountainRangesMin, params.mountainRangesMax);
    final numRanges = suggestedRanges.clamp(1, targetMountain);
    if (numRanges <= 0) {
      return _topUp.nonMountainLandFromCells(landCells, terrainGrid);
    }

    var remainingMountain = targetMountain;
    const directions = kTileMapDirections4;

    for (var r = 0; r < numRanges && remainingMountain > 0; r++) {
      final start = _walk.pickStart(landCells, terrainGrid, rnd);
      if (start == null) break;
      var (x, y) = start;
      terrainGrid[y][x] = TerrainType.mountain;
      remainingMountain--;

      final idealLength = (targetMountain / numRanges).round();
      final maxLengthForRange = idealLength.clamp(
        params.mountainRangeMinLength,
        targetMountain,
      );
      var placedThisRange = 1;

      var dir = directions[rnd.nextInt(directions.length)];

      while (placedThisRange < maxLengthForRange && remainingMountain > 0) {
        final step = _walk.extendMountainRandomWalkOnce(
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

    return _topUp.applyTopUp(
      terrainGrid,
      grid,
      directions,
      targetMountain,
      rnd,
    );
  }
}
