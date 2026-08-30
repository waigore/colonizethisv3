/// Coastline-growth helpers for [TileMapGenLandSeeds].
///
/// SPEC/program/tile-map-gen-algorithm.md.
///
/// Grow driver only; registration and scoring live in sibling libraries
/// (Refs #4654 Slice B).
library;

import 'dart:math';

import 'tile_map_generator_land_seeds_shared.dart';
import 'tile_map_distance_sentinels.dart';
import 'tile_map_land_seed_contract.dart';
import '../tile_map_grid.dart';
import 'tile_map_generator_land_seeds_coast_membership.dart';
import 'tile_map_generator_land_seeds_coast_register.dart';
import 'tile_map_generator_land_seeds_coast_score.dart';
import 'tile_map_land_sentinel.dart';
import 'tile_map_province_budget.dart';

/// Top-level thickness-first coastline growth driver.
class LandSeedCoast {
  const LandSeedCoast._();

  /// Grow coastlines with a thickness-first heuristic; do not bring land within
  /// buffer of another continent. Preference is given to coastal sea cells that
  /// already have a high density of same-continent land in a local neighborhood
  /// (bays and coves) so they are filled before long, thin tendrils into open
  /// ocean.
  static (List<List<String>>, List<List<int>>) growCoastlines(
    TileMapLandSeedParams params,
    List<List<String>> grid,
    List<List<int>> continentGrid,
    int remaining,
    Map<String, int> provinceToContinent,
    String seaZoneId,
    Random rnd,
  ) {
    if (provinceToContinent.isEmpty) return (grid, continentGrid);
    final numContinents = provinceToContinent.values.toSet().length;
    final provincesByContinent = <int, List<String>>{};
    for (final e in provinceToContinent.entries) {
      provincesByContinent.putIfAbsent(e.value, () => []).add(e.key);
    }

    var g = TileMapGrid.copy(grid);
    var cg = TileMapGrid.copy(continentGrid);
    final coastalByContinent = <int, LandSeedCoastalCells>{};
    for (var c = 0; c < numContinents; c++) {
      coastalByContinent[c] = LandSeedCoastalCells();
    }

    LandSeedCoastRegister.registerCoastalSeaTilesAdjacentToLand(
      params,
      g,
      cg,
      seaZoneId,
      coastalByContinent,
    );

    final budgetPerContinent = allocateBudgetByProvinceCount(
      totalBudget: remaining,
      provincesByContinent: provincesByContinent,
      numContinents: numContinents,
    );

    const scoreRadius = 3;
    final buffer = params.continentBufferTiles == 0
        ? 1
        : params.continentBufferTiles;
    final bufferOffsets = LandSeedShared.bufferOffsets(buffer);

    var added = 0;
    const maxAttempts = 10000;
    var attempts = 0;
    while (added < remaining && attempts < maxAttempts) {
      attempts++;
      var anyProgress = false;

      for (var c = 0; c < numContinents; c++) {
        if (!_tryGrowOneCoastalCellForContinent(
          params,
          c,
          g,
          cg,
          seaZoneId,
          coastalByContinent,
          budgetPerContinent,
          bufferOffsets,
          scoreRadius,
          rnd,
        )) {
          continue;
        }
        added++;
        anyProgress = true;
      }

      if (!anyProgress) {
        break;
      }
    }
    return (g, cg);
  }

  static bool _tryGrowOneCoastalCellForContinent(
    TileMapLandSeedParams params,
    int continentIndex,
    List<List<String>> g,
    List<List<int>> cg,
    String seaZoneId,
    Map<int, LandSeedCoastalCells> coastalByContinent,
    List<int> budgetPerContinent,
    List<(int, int)> bufferOffsets,
    int scoreRadius,
    Random rnd,
  ) {
    if (budgetPerContinent[continentIndex] <= 0) return false;
    final coastal = coastalByContinent[continentIndex]!;
    if (coastal.isEmpty) return false;

    var bestScore = kMinLandSeedScoreSentinel;
    final bestCandidates = <(int x, int y)>[];

    for (final (sx, sy) in coastal.list) {
      if (g[sy][sx] != seaZoneId) continue;

      if (LandSeedShared.wouldJoinOtherContinentInBuffer(
        cg,
        params,
        sx,
        sy,
        continentIndex,
        bufferOffsets,
      )) {
        continue;
      }

      final score = LandSeedCoastScore.scoreCoastalCellForContinent(
        g,
        cg,
        params,
        sx,
        sy,
        continentIndex,
        scoreRadius,
      );
      if (score < bestScore) continue;
      if (score > bestScore) {
        bestScore = score;
        bestCandidates.clear();
      }
      bestCandidates.add((sx, sy));
    }

    if (bestCandidates.isEmpty) return false;

    final (sx, sy) = bestCandidates[rnd.nextInt(bestCandidates.length)];
    if (g[sy][sx] != seaZoneId) return false;

    g[sy][sx] = kTileMapLandSentinel;
    cg[sy][sx] = continentIndex;
    budgetPerContinent[continentIndex]--;

    coastal.removeCell((sx, sy));
    LandSeedCoastRegister.appendOrthogonalSeaNeighborsToCoastalList(
      params,
      g,
      seaZoneId,
      sx,
      sy,
      coastal,
    );
    return true;
  }
}
