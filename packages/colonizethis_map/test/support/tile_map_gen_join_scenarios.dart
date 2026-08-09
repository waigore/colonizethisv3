import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_map/package_logger.dart';
import 'package:colonizethis_map/src/gen/tile_map_gen_continent_join_pass.dart';
import 'package:colonizethis_map/src/gen/tile_map_gen_sea_zone_subdivide_pass.dart';
import 'package:colonizethis_map/src/gen/tile_map_gen_terrain_jitter_pass.dart';
import 'package:colonizethis_map/src/gen/tile_map_grid_graph.dart';

import 'tile_map_gen_fixtures.dart';

/// Shared pass factories and grid builders for `tile_map_gen_join_passes_test.dart`.
/// Refs #4297 wave-5 test densify.

const joinTestSeaId = 's1';

ContinentJoinPass continentJoinPassFor(TileMapParams params) =>
    ContinentJoinPass(params, packageLogger(), TileMapGridGraph(params));

SeaZoneSubdividePass seaZoneSubdividePassFor(TileMapParams params) =>
    SeaZoneSubdividePass(params, TileMapGridGraph(params));

TerrainJitterPass terrainJitterPassFor(TileMapParams params) =>
    TerrainJitterPass(params);

List<List<String>> provinceOnlyGrid(int size) => List<List<String>>.generate(
      size,
      (_) => List<String>.filled(size, 'p1'),
    );

List<List<TerrainType?>> plainsTerrainGrid(int size) =>
    List<List<TerrainType?>>.generate(
      size,
      (_) => List<TerrainType?>.filled(size, TerrainType.plains),
    );

List<List<Resource?>> emptyResourceGrid(int size) =>
    List<List<Resource?>>.generate(
      size,
      (_) => List<Resource?>.filled(size, null),
    );

int countTerrainType(
  List<List<TerrainType?>> terrain,
  TerrainType type,
) {
  var count = 0;
  for (final row in terrain) {
    count += row.where((t) => t == type).length;
  }
  return count;
}
