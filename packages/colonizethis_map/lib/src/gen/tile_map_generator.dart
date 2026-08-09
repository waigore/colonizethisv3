// SPEC/program/tile-map-gen-algorithm.md, tile-map-gen-resources.md, tile-map-gen-config.md.

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/package_logger.dart';

import 'tile_map_gen_continent_join_pass.dart';
import 'tile_map_gen_sea_zone_subdivide_pass.dart';
import 'tile_map_gen_terrain_jitter_pass.dart';
import 'tile_map_generator_land_seeds.dart';
import 'tile_map_generator_lakes_provinces.dart';
import 'tile_map_generator_pass_adapters.dart';
import 'tile_map_generator_terrain_assign.dart';
import 'tile_map_grid_graph.dart';
import 'tile_map_params.dart';
import '../tile_map_grid.dart';
import 'tile_map_generator_args.dart';
import 'topology_inference.dart';

export 'tile_map_generator_lakes_test_api.dart' show fillLakesPass4ForTest;
export 'tile_map_params.dart';
export 'tile_map_generator_types.dart';

abstract class _TileMapGeneratorShell {
  _TileMapGeneratorShell({this.params = const TileMapParams()});

  final TileMapParams params;
}

/// Generates a per-region tile map from province/continent params. SPEC/program/tile-map-gen-algorithm.md, tile-map-gen-resources.md, tile-map-gen-config.md.
/// Map-first: topology is inferred from the grid after generation.
class TileMapGenerator extends _TileMapGeneratorShell {
  factory TileMapGenerator({TileMapParams params = const TileMapParams()}) {
    final graph = TileMapGridGraph(params);
    final landImpl = TileMapGenLandSeeds(params);
    final terrainImpl = TileMapGenTerrainResource(params, graph);
    final continentJoinImpl = ContinentJoinPass(params, packageLogger(), graph);
    final terrainJitterImpl = TerrainJitterPass(params);
    final seaZoneSubdivideImpl = SeaZoneSubdividePass(params, graph);
    final lakesImpl = TileMapGenLakesProvinces(
      params,
      graph,
      continentJoinImpl,
    );
    return TileMapGenerator._(
      params: params,
      landSeedService: landImpl,
      lakeAndProvinceService: lakesImpl,
      terrainResourceService: terrainImpl,
      continentJoinService: continentJoinImpl,
      terrainJitterService: terrainJitterImpl,
      seaZoneSubdivideService: seaZoneSubdivideImpl,
    );
  }

  TileMapGenerator._({
    required super.params,
    required TileMapGenLandSeeds landSeedService,
    required TileMapGenLakesProvinces lakeAndProvinceService,
    required TileMapGenTerrainResource terrainResourceService,
    required ContinentJoinPass continentJoinService,
    required TerrainJitterPass terrainJitterService,
    required SeaZoneSubdividePass seaZoneSubdivideService,
  }) : _landSeedService = landSeedService,
       _lakeAndProvinceService = lakeAndProvinceService,
       _terrainResourceService = terrainResourceService,
       _continentJoinService = continentJoinService,
       _terrainJitterService = terrainJitterService,
       _seaZoneSubdivideService = seaZoneSubdivideService;

  final TileMapGenLandSeeds _landSeedService;
  final TileMapGenLakesProvinces _lakeAndProvinceService;
  final TileMapGenTerrainResource _terrainResourceService;
  final ContinentJoinPass _continentJoinService;
  final TerrainJitterPass _terrainJitterService;
  final SeaZoneSubdividePass _seaZoneSubdivideService;

  /// Generate a tile map from province/continent count. Returns (TileMapResult, inferred MapTopology).
  /// Optional [onLog] receives one line per pass.
  /// If [resourceRules] is provided, assigns terrain and optional resource per land cell (Pass 6–7).
  /// Optional [onLandSeedsPlaced] receives the land seed positions (Pass 2) and a parallel list of
  /// continent indices (0, 1, …) for each seed, for visualization.
  /// Optional [onContinentSeedsPlaced] receives the continent seed positions (one per continent).
  (TileMapResult, MapTopology) generate({
    required int numProvinces,
    required int numContinents,
    required String regionId,
    String seaZoneId = 's1',
    ResourceRules? resourceRules,
    void Function(String)? onLog,
    void Function(List<(int x, int y)> landSeeds, List<int> continentIndices)?
    onLandSeedsPlaced,
    void Function(List<(int x, int y)> continentSeeds)? onContinentSeedsPlaced,
    List<int>? continentProvinceSizes,
  }) {
    final log = packageLogger();
    log.i(
      'TileMapGenerator.generate start regionId=$regionId numProvinces=$numProvinces seed=${params.seed}',
    );
    validateTileMapGenerateArgs(numProvinces, numContinents);
    log.i(
      'generation_params '
      'regionId=$regionId '
      'numProvinces=$numProvinces '
      'numContinents=$numContinents '
      'width=${params.width} '
      'height=${params.height} '
      'seed=${params.seed} '
      'seaFraction=${params.seaFraction} '
      'joinContinents=${params.joinContinents} '
      'skipFillLakes=${params.skipFillLakes} '
      'seedBeforeAssignment=${params.seedBeforeAssignment}',
    );
    final provinceToContinent = resolveProvinceToContinentForGenerate(
      numProvinces: numProvinces,
      numContinents: numContinents,
      continentProvinceSizes: continentProvinceSizes,
    );
    final rnd = Random(params.seed);

    var grid = TileMapGrid.filled(params.height, params.width, seaZoneId);
    onLog?.call(
      'Pass 1: Grid initialized (${params.width}x${params.height}), all sea',
    );
    final seeded = runSeedAndAssignLandPass(
      params: params,
      landSeedService: _landSeedService,
      grid: grid,
      provinceToContinent: provinceToContinent,
      seaZoneId: seaZoneId,
      rnd: rnd,
      onLog: onLog,
    );
    grid = seeded.$1;
    final continentSeeds = seeded.$2;
    final landSeeds = seeded.$3;
    final continentBySeedIndex = seeded.$4;

    if (landSeeds.isNotEmpty) {
      onLandSeedsPlaced?.call(
        List<(int x, int y)>.from(landSeeds),
        List<int>.from(continentBySeedIndex),
      );
    }
    if (continentSeeds.isNotEmpty) {
      onContinentSeedsPlaced?.call(List<(int x, int y)>.from(continentSeeds));
    }
    final landCount = countLandCells(grid);
    onLog?.call(
      'Pass 3: Land assignment complete ($landCount land, ${params.width * params.height - landCount} sea)',
    );
    grid = runLakesAndBorderNoisePass(
      params: params,
      lakeAndProvinceService: _lakeAndProvinceService,
      grid: grid,
      seaZoneId: seaZoneId,
      landSeeds: landSeeds,
      continentBySeedIndex: continentBySeedIndex,
      rnd: rnd,
      onLog: onLog,
    );
    final terrainAndResources = runTerrainAndResourcesPass(
      params: params,
      terrainResourceService: _terrainResourceService,
      grid: grid,
      regionId: regionId,
      resourceRules: resourceRules,
      rnd: rnd,
      onLog: onLog,
    );
    var terrainGrid = terrainAndResources.$1;
    var resourceGrid = terrainAndResources.$2;

    final provinceSeeds = _lakeAndProvinceService.placeProvinceSeedsOnLand(
      grid,
      provinceToContinent,
      landSeeds,
      continentBySeedIndex,
      seaZoneId,
      rnd,
    );
    onLog?.call(
      'Pass 8: Province seeds on land (${provinceSeeds.length} provinces)',
    );
    grid = _lakeAndProvinceService.assignProvincesFromSeeds(
      grid,
      provinceSeeds,
      seaZoneId,
    );
    onLog?.call('Pass 9: Province assignment complete');
    final joined = runJoinContinentsPass(
      params: params,
      continentJoinService: _continentJoinService,
      grid: grid,
      terrainGrid: terrainGrid,
      resourceGrid: resourceGrid,
      provinceToContinent: provinceToContinent,
      seaZoneId: seaZoneId,
      regionId: regionId,
      landSeeds: landSeeds,
      continentBySeedIndex: continentBySeedIndex,
      resourceRules: resourceRules,
      rnd: rnd,
      onLog: onLog,
    );
    grid = joined.$1;
    terrainGrid = joined.$2;
    resourceGrid = joined.$3;
    runTerrainJitterPass(
      params: params,
      terrainJitterService: _terrainJitterService,
      grid: grid,
      terrainGrid: terrainGrid,
      resourceGrid: resourceGrid,
      regionId: regionId,
      rnd: rnd,
    );
    grid = runSubdivideSeaZonesPass(
      params: params,
      seaZoneSubdivideService: _seaZoneSubdivideService,
      grid: grid,
      seaZoneId: seaZoneId,
      onLog: onLog,
    );

    final result = TileMapResult(
      width: params.width,
      height: params.height,
      grid: grid,
      terrainGrid: terrainGrid,
      resourceGrid: resourceGrid,
    );
    final topology = inferTopologyFromTileMap(result, regionId);
    final provincesCount = topology.nodes
        .where((n) => n.type == TopologyNodeType.province)
        .length;
    // Topology inference only yields `province` and `seaZone` nodes, so the
    // realized continent count is the generator input.
    final continentsCount = numContinents;
    log.i(
      'TileMapGenerator.generate end regionId=$regionId provinces=$provincesCount continents=$continentsCount success=true',
    );
    return (result, topology);
  }
}
