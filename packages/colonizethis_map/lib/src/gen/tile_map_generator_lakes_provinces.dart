/// Pass 4–5: lakes, moats, and border noise.
///
/// SPEC/program/tile-map-gen-algorithm.md.
///
/// [run] orchestration only; [fillLakes] / [fillMoats] live in sibling
/// libraries (Refs #4654 Slice B). Province seeding is [TileMapGenProvinces].
library;

import 'dart:math';

import 'map_gen_pass_payloads.dart';
import 'map_gen_stage.dart';
import 'tile_map_gen_continent_join_pass.dart';
import 'tile_map_generator_border_noise.dart';
import 'tile_map_generator_lakes_fill.dart';
import 'tile_map_generator_lakes_moats.dart';
import 'tile_map_grid_graph.dart';
import 'tile_map_params.dart';

/// Pass 4–5 service: lake/moat fill and border noise. Implements [MapGenPass]
/// so [TileMapGenerator] drives Pass 4–5 through the uniform [run] entry.
class TileMapGenLakesProvinces
    implements MapGenPass<LakesPassPayload, List<List<String>>> {
  TileMapGenLakesProvinces(this.params, this._graph, ContinentJoinPass join)
    : _fill = TileMapGenLakesFill(params, _graph),
      _moats = TileMapGenLakesMoats(params, _graph, join);

  @override
  final TileMapParams params;
  final TileMapGridGraph _graph;
  final TileMapGenLakesFill _fill;
  final TileMapGenLakesMoats _moats;

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
      nextGrid = applyBorderNoise(
        params,
        nextGrid,
        payload.seaZoneId,
        payload.rnd,
      );
      ctx.log('Pass 5: Border noise applied');
    } else {
      ctx.log('Pass 5: Border noise skipped (0)');
    }
    return nextGrid;
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
    return _fill.fillLakes(
      grid,
      seaZoneId,
      landSeeds,
      continentBySeedIndex,
      ocean: ocean,
    );
  }

  /// Collapse narrow ocean moats around a single continent into land.
  List<List<String>> fillMoats(
    List<List<String>> grid,
    String seaZoneId,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
    Random rnd, {
    Set<(int x, int y)>? ocean,
  }) {
    return _moats.fillMoats(
      grid,
      seaZoneId,
      landSeeds,
      continentBySeedIndex,
      rnd,
      ocean: ocean,
    );
  }
}
