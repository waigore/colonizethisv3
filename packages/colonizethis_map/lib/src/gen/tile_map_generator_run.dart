/// [TileMapGenerator.generate] pass orchestration (Refs #4654).
///
/// SPEC/program/tile-map-gen-algorithm.md, tile-map-gen-resources.md,
/// tile-map-gen-config.md.
library;

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/package_logger.dart';

import '../tile_map_grid.dart';
import 'tile_map_generator_args.dart';
import 'tile_map_generator_pass_adapters.dart';
import 'tile_map_generator_services.dart';
import 'tile_map_params.dart';
import 'topology_inference.dart';

/// Generate a tile map from province/continent count.
(TileMapResult, MapTopology) runTileMapGenerate({
  required TileMapParams params,
  required TileMapGeneratorServices services,
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
    landSeedService: services.landSeedService,
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
    lakesService: services.lakesService,
    grid: grid,
    seaZoneId: seaZoneId,
    landSeeds: landSeeds,
    continentBySeedIndex: continentBySeedIndex,
    rnd: rnd,
    onLog: onLog,
  );
  final terrainAndResources = runTerrainAndResourcesPass(
    params: params,
    terrainResourceService: services.terrainResourceService,
    grid: grid,
    regionId: regionId,
    resourceRules: resourceRules,
    rnd: rnd,
    onLog: onLog,
  );
  var terrainGrid = terrainAndResources.$1;
  var resourceGrid = terrainAndResources.$2;

  final provinceSeeds = services.provinceService.placeProvinceSeedsOnLand(
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
  grid = services.provinceService.assignProvincesFromSeeds(
    grid,
    provinceSeeds,
    seaZoneId,
  );
  onLog?.call('Pass 9: Province assignment complete');
  final joined = runJoinContinentsPass(
    params: params,
    continentJoinService: services.continentJoinService,
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
    terrainJitterService: services.terrainJitterService,
    grid: grid,
    terrainGrid: terrainGrid,
    resourceGrid: resourceGrid,
    regionId: regionId,
    rnd: rnd,
  );
  grid = runSubdivideSeaZonesPass(
    params: params,
    seaZoneSubdivideService: services.seaZoneSubdivideService,
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
  final continentsCount = numContinents;
  log.i(
    'TileMapGenerator.generate end regionId=$regionId provinces=$provincesCount continents=$continentsCount success=true',
  );
  return (result, topology);
}
