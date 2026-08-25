/// Factory/DI wiring for [TileMapGenerator] (Refs #4654).
///
/// SPEC/program/tile-map-gen-algorithm.md.
library;

import 'package:colonizethis_map/package_logger.dart';

import 'tile_map_gen_continent_join_pass.dart';
import 'tile_map_gen_sea_zone_subdivide_pass.dart';
import 'tile_map_gen_terrain_jitter_pass.dart';
import 'tile_map_generator_land_seeds.dart';
import 'tile_map_generator_lakes_provinces.dart';
import 'tile_map_generator_provinces.dart';
import 'tile_map_generator_terrain_assign.dart';
import 'tile_map_grid_graph.dart';
import 'tile_map_params.dart';

/// Pass services constructed once per [TileMapGenerator] instance.
class TileMapGeneratorServices {
  const TileMapGeneratorServices({
    required this.landSeedService,
    required this.lakesService,
    required this.provinceService,
    required this.terrainResourceService,
    required this.continentJoinService,
    required this.terrainJitterService,
    required this.seaZoneSubdivideService,
  });

  final TileMapGenLandSeeds landSeedService;
  final TileMapGenLakesProvinces lakesService;
  final TileMapGenProvinces provinceService;
  final TileMapGenTerrainResource terrainResourceService;
  final ContinentJoinPass continentJoinService;
  final TerrainJitterPass terrainJitterService;
  final SeaZoneSubdividePass seaZoneSubdivideService;
}

/// Builds the default pass graph and service graph for [params].
TileMapGeneratorServices createTileMapGeneratorServices(TileMapParams params) {
  final graph = TileMapGridGraph(params);
  final landImpl = TileMapGenLandSeeds(params);
  final terrainImpl = TileMapGenTerrainResource(params, graph);
  final continentJoinImpl = ContinentJoinPass(params, packageLogger(), graph);
  final terrainJitterImpl = TerrainJitterPass(params);
  final seaZoneSubdivideImpl = SeaZoneSubdividePass(params, graph);
  final lakesImpl = TileMapGenLakesProvinces(params, graph, continentJoinImpl);
  final provinceImpl = TileMapGenProvinces(params, graph);
  return TileMapGeneratorServices(
    landSeedService: landImpl,
    lakesService: lakesImpl,
    provinceService: provinceImpl,
    terrainResourceService: terrainImpl,
    continentJoinService: continentJoinImpl,
    terrainJitterService: terrainJitterImpl,
    seaZoneSubdivideService: seaZoneSubdivideImpl,
  );
}
