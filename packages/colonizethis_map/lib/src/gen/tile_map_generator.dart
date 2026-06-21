// SPEC/program/tile-map-gen-algorithm.md, tile-map-gen-resources.md, tile-map-gen-config.md.

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/package_logger.dart';

import 'grid_voronoi.dart';
import 'map_gen_pass_payloads.dart';
import '../map_validation_exception.dart';
import 'tile_map_gen_continent_join_pass.dart';
import 'tile_map_gen_sea_zone_subdivide_pass.dart';
import 'tile_map_gen_terrain_jitter_pass.dart';
import 'tile_map_generator_land_seeds.dart';
import 'tile_map_land_sentinel.dart';
import 'tile_map_land_seed_contract.dart';
import 'tile_map_params.dart';
import '../tile_map_directions.dart';
import 'map_gen_stage.dart';
import '../tile_map_grid.dart';
import 'tile_map_grid_graph.dart';
import 'tile_map_resource_cap_state.dart';
import 'tile_map_resource_placement.dart';
import 'topology_inference.dart';

export 'tile_map_params.dart';

/// Shared params for [TileMapGenerator] (generation orchestration only).

part 'tile_map_generator_types.dart';
part 'tile_map_generator_terrain_assign.dart';
part 'tile_map_generator_terrain_hardwood_part.dart';
part 'tile_map_generator_terrain_noise.dart';
part 'tile_map_generator_lakes_provinces.dart';

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
    final terrainImpl = _TileMapGenTerrainResource(params, graph);
    final continentJoinImpl = ContinentJoinPass(params, packageLogger(), graph);
    final terrainJitterImpl = TerrainJitterPass(params);
    final seaZoneSubdivideImpl = SeaZoneSubdividePass(params, graph);
    final lakesImpl = _TileMapGenLakesProvinces(
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
    required _TileMapGenLakesProvinces lakeAndProvinceService,
    required _TileMapGenTerrainResource terrainResourceService,
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
  final _TileMapGenLakesProvinces _lakeAndProvinceService;
  final _TileMapGenTerrainResource _terrainResourceService;
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
    _validateGenerateArgs(numProvinces, numContinents);
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
    final provinceToContinent = _resolveProvinceToContinent(
      numProvinces,
      numContinents,
      continentProvinceSizes,
    );
    final rnd = Random(params.seed);

    var grid = TileMapGrid.filled(params.height, params.width, seaZoneId);
    onLog?.call(
      'Pass 1: Grid initialized (${params.width}x${params.height}), all sea',
    );
    final seeded = _seedAndAssignLand(
      grid,
      provinceToContinent,
      seaZoneId,
      rnd,
      onLog,
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
    final landCount = _countLandCells(grid);
    onLog?.call(
      'Pass 3: Land assignment complete ($landCount land, ${params.width * params.height - landCount} sea)',
    );
    grid = _applyLakesAndBorderNoise(
      grid,
      seaZoneId,
      landSeeds,
      continentBySeedIndex,
      rnd,
      onLog,
    );
    final terrainAndResources = _assignTerrainAndResourcesPass(
      grid,
      regionId,
      resourceRules,
      rnd,
      onLog,
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
    final joined = _maybeJoinContinents(
      grid,
      terrainGrid,
      resourceGrid,
      provinceToContinent,
      seaZoneId,
      regionId,
      landSeeds,
      continentBySeedIndex,
      resourceRules,
      rnd,
      onLog,
    );
    grid = joined.$1;
    terrainGrid = joined.$2;
    resourceGrid = joined.$3;
    _maybeJitterTerrainByProvince(
      grid,
      terrainGrid,
      resourceGrid,
      regionId,
      rnd,
    );
    grid = _subdivideSeaZones(grid, seaZoneId, onLog);

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

  void _validateGenerateArgs(int numProvinces, int numContinents) {
    if (numProvinces < 1) {
      throw MapValidationException('numProvinces must be at least 1');
    }
    if (numContinents < 1) {
      throw MapValidationException('numContinents must be at least 1');
    }
  }

  Map<String, int> _resolveProvinceToContinent(
    int numProvinces,
    int numContinents,
    List<int>? continentProvinceSizes,
  ) {
    if (continentProvinceSizes == null) {
      return buildProvinceToContinentMap(numProvinces, numContinents);
    }
    if (continentProvinceSizes.length != numContinents) {
      throw MapValidationException(
        'continentProvinceSizes.length (${continentProvinceSizes.length}) '
        'must equal numContinents ($numContinents)',
      );
    }
    final sum = continentProvinceSizes.fold<int>(0, (a, b) => a + b);
    if (sum != numProvinces) {
      throw MapValidationException(
        'continentProvinceSizes sum ($sum) must equal numProvinces ($numProvinces)',
      );
    }
    return buildProvinceToContinentMapFromCounts(continentProvinceSizes);
  }

  (List<List<String>>, List<(int x, int y)>, List<(int x, int y)>, List<int>)
  _seedAndAssignLand(
    List<List<String>> grid,
    Map<String, int> provinceToContinent,
    String seaZoneId,
    Random rnd,
    void Function(String)? onLog,
  ) {
    final result = _landSeedService.run(
      MapGenPassContext<LandSeedPassPayload>(
        params: params,
        payload: LandSeedPassPayload(
          grid: grid,
          provinceToContinent: provinceToContinent,
          seaZoneId: seaZoneId,
          rnd: rnd,
          seedBeforeAssignment: params.seedBeforeAssignment,
        ),
        onLog: onLog,
      ),
    );
    return (
      result.grid,
      result.continentSeeds,
      result.landSeeds,
      result.continentBySeedIndex,
    );
  }

  int _countLandCells(List<List<String>> grid) {
    var landCount = 0;
    TileMapGrid.forEachCell(grid, (_, __, value) {
      if (value == _landSentinel) landCount++;
    });
    return landCount;
  }

  List<List<String>> _applyLakesAndBorderNoise(
    List<List<String>> grid,
    String seaZoneId,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
    Random rnd,
    void Function(String)? onLog,
  ) {
    return _lakeAndProvinceService.run(
      MapGenPassContext<LakesPassPayload>(
        params: params,
        payload: LakesPassPayload(
          grid: grid,
          seaZoneId: seaZoneId,
          landSeeds: landSeeds,
          continentBySeedIndex: continentBySeedIndex,
          rnd: rnd,
        ),
        onLog: onLog,
      ),
    );
  }

  (List<List<TerrainType?>>?, List<List<Resource?>>?)
  _assignTerrainAndResourcesPass(
    List<List<String>> grid,
    String regionId,
    ResourceRules? resourceRules,
    Random rnd,
    void Function(String)? onLog,
  ) {
    return _terrainResourceService.run(
      MapGenPassContext<TerrainPassPayload>(
        params: params,
        payload: TerrainPassPayload(
          grid: grid,
          regionId: regionId,
          resourceRules: resourceRules,
          rnd: rnd,
        ),
        onLog: onLog,
      ),
    );
  }

  (List<List<String>>, List<List<TerrainType?>>?, List<List<Resource?>>?)
  _maybeJoinContinents(
    List<List<String>> grid,
    List<List<TerrainType?>>? terrainGrid,
    List<List<Resource?>>? resourceGrid,
    Map<String, int> provinceToContinent,
    String seaZoneId,
    String regionId,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
    ResourceRules? resourceRules,
    Random rnd,
    void Function(String)? onLog,
  ) {
    final joinResult = _continentJoinService.run(
      MapGenPassContext<ContinentJoinPassPayload>(
        params: params,
        payload: ContinentJoinPassPayload(
          grid: grid,
          terrainGrid: terrainGrid,
          resourceGrid: resourceGrid,
          provinceToContinent: provinceToContinent,
          seaZoneId: seaZoneId,
          mapRegionId: regionId,
          landSeeds: landSeeds,
          continentBySeedIndex: continentBySeedIndex,
          resourceRules: resourceRules,
          rnd: rnd,
        ),
        onLog: onLog,
      ),
    );
    return (joinResult.grid, joinResult.terrainGrid, joinResult.resourceGrid);
  }

  void _maybeJitterTerrainByProvince(
    List<List<String>> grid,
    List<List<TerrainType?>>? terrainGrid,
    List<List<Resource?>>? resourceGrid,
    String regionId,
    Random rnd,
  ) {
    if (terrainGrid == null || resourceGrid == null) return;
    _terrainJitterService.run(
      MapGenPassContext<TerrainJitterPassPayload>(
        params: params,
        payload: TerrainJitterPassPayload(
          grid: grid,
          terrainGrid: terrainGrid,
          resourceGrid: resourceGrid,
          regionId: regionId,
          rnd: rnd,
        ),
      ),
    );
  }

  List<List<String>> _subdivideSeaZones(
    List<List<String>> grid,
    String seaZoneId,
    void Function(String)? onLog,
  ) {
    final totalSea = _seaZoneSubdivideService.countSeaCells(grid, seaZoneId);
    if (totalSea <= 0) return grid;
    final (newGrid, _) = _seaZoneSubdivideService.run(
      MapGenPassContext<SeaZoneSubdividePassPayload>(
        params: params,
        payload: SeaZoneSubdividePassPayload(
          grid: grid,
          seaZoneId: seaZoneId,
          totalSea: totalSea,
        ),
        onLog: onLog,
      ),
    );
    return newGrid;
  }

  /// Runs Pass 4 **lake fill only** on a grid at post-Pass-3 semantics (sea =
  /// [seaZoneId], land = `_land` sentinel). Intended for **automated tests**;
  /// production code should use [generate].
  static List<List<String>> fillLakesPass4ForTest({
    required TileMapParams params,
    required List<List<String>> grid,
    String seaZoneId = 's1',
    required List<(int x, int y)> landSeeds,
    required List<int> continentBySeedIndex,
  }) {
    final graph = TileMapGridGraph(params);
    final continentJoinImpl = ContinentJoinPass(params, packageLogger(), graph);
    final lakesImpl = _TileMapGenLakesProvinces(
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
}
