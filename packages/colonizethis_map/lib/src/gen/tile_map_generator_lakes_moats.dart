/// Pass 4 moat collapse (Refs #4654).
///
/// SPEC/program/tile-map-gen-algorithm.md.
library;

import 'dart:math';

import '../tile_map_directions.dart';
import '../tile_map_grid.dart';
import 'tile_map_gen_continent_join_pass.dart';
import 'tile_map_generator_lakes_fill.dart';
import 'tile_map_grid_graph.dart';
import 'tile_map_land_sentinel.dart';
import 'tile_map_params.dart';

/// Narrow-ocean moat fill, then preserve sea fraction via [ContinentJoinPass].
class TileMapGenLakesMoats {
  TileMapGenLakesMoats(this.params, this.graph, this.join);

  final TileMapParams params;
  final TileMapGridGraph graph;
  final ContinentJoinPass join;

  /// Collapse narrow ocean moats around a single continent into land.
  List<List<String>> fillMoats(
    List<List<String>> grid,
    String seaZoneId,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
    Random rnd, {
    Set<(int x, int y)>? ocean,
  }) {
    final oceanResolver = TileMapGenLakesFill(params, graph);
    final resolvedOcean = oceanResolver.resolveOceanCells(
      grid,
      seaZoneId,
      landSeeds,
      continentBySeedIndex,
      ocean: ocean,
    );
    if (resolvedOcean.isEmpty) return grid;

    final next = TileMapGrid.copy(grid);
    final moatCells = <(int x, int y)>[];

    TileMapGrid.forEachIndex(params.height, params.width, (y, x) {
      if (next[y][x] != seaZoneId) return;
      if (!resolvedOcean.contains((x, y))) return;

      final neighbouringContinents = <int>{};
      final sameContinentDirectionCounts = <int, int>{};

      for (final (dx, dy) in kTileMapDirections4) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
          continue;
        }
        if (next[ny][nx] == seaZoneId) continue;
        final continent = graph.continentForLandCell(
          nx,
          ny,
          landSeeds,
          continentBySeedIndex,
        );
        neighbouringContinents.add(continent);
        sameContinentDirectionCounts[continent] =
            (sameContinentDirectionCounts[continent] ?? 0) + 1;
      }

      if (neighbouringContinents.isEmpty) return;
      if (neighbouringContinents.length > 1) {
        return;
      }

      final c = neighbouringContinents.single;
      final dirCount = sameContinentDirectionCounts[c] ?? 0;
      if (dirCount < 2) return;

      moatCells.add((x, y));
    });

    if (moatCells.isEmpty) return grid;

    for (final (x, y) in moatCells) {
      next[y][x] = kTileMapLandSentinel;
    }

    join.preserveSeaFraction(
      next,
      null,
      null,
      seaZoneId,
      resolvedOcean,
      moatCells.length,
    );

    return next;
  }
}
