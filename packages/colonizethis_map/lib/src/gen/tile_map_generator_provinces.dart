/// Pass 8–9: province seed placement and Voronoi province assignment.
///
/// SPEC/program/tile-map-gen-algorithm.md, tile-map-gen-resources.md.
library;

import 'dart:math';

import 'grid_voronoi.dart';
import 'tile_map_land_sentinel.dart';
import 'tile_map_params.dart';
import 'tile_map_grid_graph.dart';
import '../tile_map_grid.dart';

/// Pass 8–9 service: place province seeds on land and assign provinces via
/// Voronoi from those seeds.
class TileMapGenProvinces {
  TileMapGenProvinces(this.params, this._graph);

  final TileMapParams params;
  final TileMapGridGraph _graph;

  /// Land cells grouped by continent (nearest land seed → continent via
  /// [continentBySeedIndex]).
  Map<int, List<(int x, int y)>> landCellsByContinent(
    List<List<String>> grid,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
  ) {
    final numContinents = continentBySeedIndex.isEmpty
        ? 0
        : continentBySeedIndex.reduce((a, b) => a > b ? a : b) + 1;
    final byContinent = <int, List<(int x, int y)>>{
      for (var c = 0; c < numContinents; c++) c: [],
    };
    TileMapGrid.forEachIndex(params.height, params.width, (y, x) {
      if (grid[y][x] != kTileMapLandSentinel) return;
      final bestSeedIndex = _graph.nearestLandSeedIndexForCell(x, y, landSeeds);
      final c = continentBySeedIndex[bestSeedIndex];
      byContinent[c]!.add((x, y));
    });
    return byContinent;
  }

  /// Place one province seed per province on that continent's land cells; min
  /// spacing.
  Map<String, (int x, int y)> placeProvinceSeedsOnLand(
    List<List<String>> grid,
    Map<String, int> provinceToContinent,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
    String seaZoneId,
    Random rnd,
  ) {
    if (provinceToContinent.isEmpty) return {};
    final numContinents = provinceToContinent.values.toSet().length;
    final byContinent = landCellsByContinent(
      grid,
      landSeeds,
      continentBySeedIndex,
    );
    final seeds = <String, (int x, int y)>{};
    const minDist = 3;
    for (var c = 0; c < numContinents; c++) {
      final cells = byContinent[c] ?? [];
      if (cells.isEmpty) continue;
      final provinceIds =
          provinceToContinent.entries
              .where((e) => e.value == c)
              .map((e) => e.key)
              .toList()
            ..sort();
      final used = <(int x, int y)>{};
      for (final provinceId in provinceIds) {
        final shuffled = List<(int x, int y)>.from(cells)..shuffle(rnd);
        for (final (x, y) in shuffled) {
          if (used.any(
            (p) => (p.$1 - x).abs() < minDist && (p.$2 - y).abs() < minDist,
          )) {
            continue;
          }
          seeds[provinceId] = (x, y);
          used.add((x, y));
          break;
        }
        if (!seeds.containsKey(provinceId) && cells.isNotEmpty) {
          final (x, y) = cells[rnd.nextInt(cells.length)];
          seeds[provinceId] = (x, y);
          used.add((x, y));
        }
      }
    }
    return seeds;
  }

  /// Replace each [kTileMapLandSentinel] cell with nearest province seed id.
  /// Uses generic Voronoi.
  List<List<String>> assignProvincesFromSeeds(
    List<List<String>> grid,
    Map<String, (int x, int y)> provinceSeeds,
    String seaZoneId,
  ) {
    if (provinceSeeds.isEmpty) return grid;
    final landCells = <(int x, int y)>[];
    TileMapGrid.forEachCell(grid, (y, x, value) {
      if (value == kTileMapLandSentinel) landCells.add((x, y));
    });
    final assignment = assignCellsToNearestSeed(
      landCells,
      provinceSeeds,
      noiseScale: 0,
      noiseSeed: params.seed,
    );
    final next = TileMapGrid.copy(grid);
    for (final entry in assignment.entries) {
      final (x, y) = entry.key;
      next[y][x] = entry.value;
    }
    return next;
  }
}
