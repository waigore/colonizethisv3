/// Pass 4–5: lakes, moats, and border noise.
///
/// SPEC/program/tile-map-gen-algorithm.md.
///
/// Province seeding (Passes 8–9) lives in [TileMapGenProvinces]
/// (`tile_map_generator_provinces.dart`, Refs #4371).
library;

import 'dart:math';

import 'map_gen_pass_payloads.dart';
import 'map_gen_stage.dart';
import 'tile_map_gen_continent_join_pass.dart';
import 'tile_map_generator_border_noise.dart';
import 'tile_map_land_sentinel.dart';
import 'tile_map_params.dart';
import 'tile_map_grid_graph.dart';
import '../tile_map_directions.dart';
import '../tile_map_grid.dart';

/// Pass 4–5 service: lake/moat fill and border noise. Implements [MapGenPass]
/// so [TileMapGenerator] drives Pass 4–5 through the uniform [run] entry.
class TileMapGenLakesProvinces
    implements MapGenPass<LakesPassPayload, List<List<String>>> {
  TileMapGenLakesProvinces(this.params, this._graph, this._join);

  @override
  final TileMapParams params;
  final TileMapGridGraph _graph;
  final ContinentJoinPass _join;

  /// Uniform pass entry: Pass 4 lake/moat fill (unless `skipFillLakes`) then
  /// Pass 5 border noise (when `borderNoise > 0`). Returns the updated grid;
  /// behaviour matches the prior inline orchestration (Refs #3574, slice 4).
  @override
  List<List<String>> run(MapGenPassContext<LakesPassPayload> ctx) {
    final payload = ctx.payload;
    var nextGrid = payload.grid;
    if (params.skipFillLakes) {
      ctx.log('Pass 4: Fill lakes and moats skipped');
    } else {
      var ocean = _graph.oceanCells(
        nextGrid,
        payload.seaZoneId,
        payload.landSeeds,
        payload.continentBySeedIndex,
      );
      nextGrid = fillLakes(
        nextGrid,
        payload.seaZoneId,
        payload.landSeeds,
        payload.continentBySeedIndex,
        ocean: ocean,
      );
      ocean = _graph.oceanCells(
        nextGrid,
        payload.seaZoneId,
        payload.landSeeds,
        payload.continentBySeedIndex,
      );
      nextGrid = fillMoats(
        nextGrid,
        payload.seaZoneId,
        payload.landSeeds,
        payload.continentBySeedIndex,
        payload.rnd,
        ocean: ocean,
      );
      ctx.log('Pass 4: Fill lakes and moats done');
    }
    if (params.borderNoise > 0) {
      nextGrid = applyBorderNoise(params, nextGrid, payload.seaZoneId, payload.rnd);
      ctx.log('Pass 5: Border noise applied');
    } else {
      ctx.log('Pass 5: Border noise skipped (0)');
    }
    return nextGrid;
  }

  void _addCoastalLandCandidatesAroundLakeCell(
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
          _graph.oceanNeighbourCount(next, nx, ny, seaZoneId, ocean) >= 1) {
        coastalLandCandidates.add((nx, ny));
      }
    }
  }

  Set<(int x, int y)> _resolveOceanCells(
    List<List<String>> grid,
    String seaZoneId,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex, {
    Set<(int x, int y)>? ocean,
  }) {
    return ocean ??
        _graph.oceanCells(
          grid,
          seaZoneId,
          landSeeds,
          continentBySeedIndex,
        );
  }

  /// Fill lakes: convert lake (sea not in ocean) to land; skip lakes that
  /// border 2+ continents (straits).
  ///
  /// When [ocean] is omitted, the ocean set is derived from [grid] (direct test
  /// entry points). [run] passes an explicit snapshot per step (Refs #4371).
  List<List<String>> fillLakes(
    List<List<String>> grid,
    String seaZoneId,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex, {
    Set<(int x, int y)>? ocean,
  }) {
    final resolvedOcean = _resolveOceanCells(
      grid,
      seaZoneId,
      landSeeds,
      continentBySeedIndex,
      ocean: ocean,
    );
    final next = snapshotGrid(grid);
    final lakeCells = <(int x, int y)>[];
    TileMapGrid.forEachIndex(params.height, params.width, (y, x) {
      if (grid[y][x] != seaZoneId) return;
      if (resolvedOcean.contains((x, y))) return;
      lakeCells.add((x, y));
    });
    final lakeComponents = _graph.connectedComponentsOfLand(lakeCells.toSet());
    var lakesFilled = 0;
    final coastalLandCandidates = <(int x, int y)>{};
    for (final component in lakeComponents) {
      for (final (x, y) in component) {
        next[y][x] = kTileMapLandSentinel;
        lakesFilled++;
        _addCoastalLandCandidatesAroundLakeCell(
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
        final na = _graph.oceanNeighbourCount(
          next,
          a.$1,
          a.$2,
          seaZoneId,
          resolvedOcean,
        );
        final nb = _graph.oceanNeighbourCount(
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

  /// Collapse narrow ocean moats: convert ocean cells that are effectively
  /// thin moats around a single continent into land, then preserve overall sea
  /// fraction by converting an equal number of coastal land tiles back to sea.
  ///
  /// A moat candidate is an ocean cell whose 4-neighbourhood contains land
  /// belonging to the **same** continent in at least two directions and no
  /// land from any other continent.
  ///
  /// When [ocean] is omitted, the ocean set is derived from [grid]. [run]
  /// recomputes and passes the post-lake snapshot (Refs #4371).
  List<List<String>> fillMoats(
    List<List<String>> grid,
    String seaZoneId,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
    Random rnd, {
    Set<(int x, int y)>? ocean,
  }) {
    final resolvedOcean = _resolveOceanCells(
      grid,
      seaZoneId,
      landSeeds,
      continentBySeedIndex,
      ocean: ocean,
    );
    if (resolvedOcean.isEmpty) return grid;

    final next = snapshotGrid(grid);
    final moatCells = <(int x, int y)>[];

    TileMapGrid.forEachIndex(params.height, params.width, (y, x) {
      if (next[y][x] != seaZoneId) return;
      if (!resolvedOcean.contains((x, y))) return;

      // Examine 4-neighbourhood for bordering land.
      final neighbouringContinents = <int>{};
      final sameContinentDirectionCounts = <int, int>{};

      for (final (dx, dy) in kTileMapDirections4) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
          continue;
        }
        if (next[ny][nx] == seaZoneId) continue;
        final continent = _graph.continentForLandCell(
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
        return; // multi-continent strait, keep as sea
      }

      final c = neighbouringContinents.single;
      final dirCount = sameContinentDirectionCounts[c] ?? 0;
      if (dirCount < 2) return; // not strongly enclosed by that continent

      moatCells.add((x, y));
    });

    if (moatCells.isEmpty) return grid;

    for (final (x, y) in moatCells) {
      next[y][x] = kTileMapLandSentinel;
    }

    // Preserve overall sea fraction by converting an equal number of coastal
    // land tiles back to sea, using the existing helper.
    _join.preserveSeaFraction(
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
