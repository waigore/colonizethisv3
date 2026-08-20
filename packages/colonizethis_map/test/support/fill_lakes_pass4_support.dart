// Test-only lake-fill entry point for Pass 4 semantics.
// SPEC/program/tile-map-gen-algorithm.md — automated tests only.

import 'package:colonizethis_map/package_logger.dart';
import 'package:colonizethis_map/src/gen/tile_map_gen_continent_join_pass.dart';
import 'package:colonizethis_map/src/gen/tile_map_generator_lakes_provinces.dart';
import 'package:colonizethis_map/src/gen/tile_map_grid_graph.dart';
import 'package:colonizethis_map/src/gen/tile_map_params.dart';

/// Runs Pass 4 **lake fill only** on a grid at post-Pass-3 semantics (sea =
/// [seaZoneId], land = `_land` sentinel). Intended for **automated tests**;
/// production code should use [TileMapGenerator.generate].
List<List<String>> fillLakesPass4ForTest({
  required TileMapParams params,
  required List<List<String>> grid,
  String seaZoneId = 's1',
  required List<(int x, int y)> landSeeds,
  required List<int> continentBySeedIndex,
}) {
  final graph = TileMapGridGraph(params);
  final continentJoinImpl = ContinentJoinPass(params, packageLogger(), graph);
  final lakesImpl = TileMapGenLakesProvinces(
    params,
    graph,
    continentJoinImpl,
  );
  return lakesImpl.fillLakes(
    grid,
    seaZoneId,
    landSeeds,
    continentBySeedIndex,
  );
}
