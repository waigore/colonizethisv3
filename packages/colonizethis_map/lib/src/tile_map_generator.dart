// SPEC/program/tile-map-gen-algorithm.md, tile-map-gen-resources.md, tile-map-gen-config.md.

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/package_logger.dart';

import 'grid_voronoi.dart';
import 'map_validation_exception.dart';
import 'tile_map_generator_land_seeds.dart';
import 'tile_map_land_sentinel.dart';
import 'tile_map_land_seed_contract.dart';
import 'tile_map_distance_sentinels.dart';
import 'tile_map_directions.dart';
import 'tile_map_grid_graph.dart';
import 'tile_map_resource_cap_state.dart';
import 'topology_inference.dart';

/// Shared params for [TileMapGenerator] (generation orchestration only).

part 'tile_map_generator_types.dart';
part 'tile_map_generator_join_sea.dart';
part 'tile_map_generator_join_sea_bridge_part.dart';
part 'tile_map_generator_join_sea_jitter_part.dart';
part 'tile_map_generator_join_sea_subdivide_part.dart';
part 'tile_map_generator_terrain_assign.dart';
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
    final joinImpl = _TileMapGenJoinSea(params, packageLogger(), graph);
    final lakesImpl = _TileMapGenLakesProvinces(params, graph, joinImpl);
    return TileMapGenerator._(
      params: params,
      landSeedService: landImpl,
      lakeAndProvinceService: lakesImpl,
      terrainResourceService: terrainImpl,
      joinAndSeaService: joinImpl,
    );
  }

  TileMapGenerator._({
    required super.params,
    required TileMapGenLandSeeds landSeedService,
    required _TileMapGenLakesProvinces lakeAndProvinceService,
    required _TileMapGenTerrainResource terrainResourceService,
    required _TileMapGenJoinSea joinAndSeaService,
  }) : _landSeedService = landSeedService,
       _lakeAndProvinceService = lakeAndProvinceService,
       _terrainResourceService = terrainResourceService,
       _joinAndSeaService = joinAndSeaService;

  final TileMapGenLandSeeds _landSeedService;
  final _TileMapGenLakesProvinces _lakeAndProvinceService;
  final _TileMapGenTerrainResource _terrainResourceService;
  final _TileMapGenJoinSea _joinAndSeaService;

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

    var grid = List.generate(
      params.height,
      (_) => List.filled(params.width, seaZoneId),
    );
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
    if (params.seedBeforeAssignment) {
      final placed = _landSeedService.placeLandSeeds(provinceToContinent, rnd);
      final continentSeeds = placed.$1;
      final landSeeds = placed.$2;
      final continentBySeedIndex = placed.$3;
      onLog?.call(
        'Pass 2: Continent seeds ${continentSeeds.length}, land seeds ${landSeeds.length}',
      );
      final assignedGrid = _landSeedService.assignLandByLandSeeds(
        grid,
        landSeeds,
        continentBySeedIndex,
        provinceToContinent,
        seaZoneId,
      );
      return (assignedGrid, continentSeeds, landSeeds, continentBySeedIndex);
    }
    final organic = _landSeedService.placeLandSeedsOrganic(
      grid,
      provinceToContinent,
      seaZoneId,
      rnd,
    );
    onLog?.call(
      'Pass 2–3 (organic): Continent seeds ${organic.$1.length}, land seeds ${organic.$2.length}',
    );
    return (organic.$4, organic.$1, organic.$2, organic.$3);
  }

  int _countLandCells(List<List<String>> grid) {
    var landCount = 0;
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] == _landSentinel) landCount++;
      }
    }
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
    var nextGrid = grid;
    if (params.skipFillLakes) {
      onLog?.call('Pass 4: Fill lakes and moats skipped');
    } else {
      nextGrid = _lakeAndProvinceService.fillLakes(
        nextGrid,
        seaZoneId,
        landSeeds,
        continentBySeedIndex,
      );
      nextGrid = _lakeAndProvinceService.fillMoats(
        nextGrid,
        seaZoneId,
        landSeeds,
        continentBySeedIndex,
        rnd,
      );
      onLog?.call('Pass 4: Fill lakes and moats done');
    }
    if (params.borderNoise > 0) {
      nextGrid = _lakeAndProvinceService.borderNoise(nextGrid, seaZoneId, rnd);
      onLog?.call('Pass 5: Border noise applied');
    } else {
      onLog?.call('Pass 5: Border noise skipped (0)');
    }
    return nextGrid;
  }

  (List<List<TerrainType?>>?, List<List<Resource?>>?)
  _assignTerrainAndResourcesPass(
    List<List<String>> grid,
    String regionId,
    ResourceRules? resourceRules,
    Random rnd,
    void Function(String)? onLog,
  ) {
    if (resourceRules == null) {
      onLog?.call(
        'Pass 6–7: Terrain/resources skipped (no rules or no provinces)',
      );
      return (null, null);
    }
    final t = _terrainResourceService.assignTerrainAndResources(
      grid,
      regionId,
      resourceRules,
      rnd,
    );
    var terrainCount = 0;
    var resourceCount = 0;
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (t.$1[y][x] != null) terrainCount++;
        if (t.$2[y][x] != null) resourceCount++;
      }
    }
    onLog?.call('Pass 6: Terrain assigned ($terrainCount land cells)');
    onLog?.call('Pass 7: Resources placed ($resourceCount cells)');
    return t;
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
    if (!params.joinContinents) {
      return (grid, terrainGrid, resourceGrid);
    }
    final joinResult = _joinAndSeaService.joinContinents(
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
    );
    if (joinResult.$4) {
      onLog?.call('Pass 10: Join continents (land bridges added)');
    }
    return (joinResult.$1, joinResult.$2, joinResult.$3);
  }

  void _maybeJitterTerrainByProvince(
    List<List<String>> grid,
    List<List<TerrainType?>>? terrainGrid,
    List<List<Resource?>>? resourceGrid,
    String regionId,
    Random rnd,
  ) {
    if (terrainGrid == null || resourceGrid == null) return;
    _joinAndSeaService.jitterTerrainByProvince(
      grid,
      terrainGrid,
      resourceGrid,
      regionId,
      rnd,
    );
  }

  List<List<String>> _subdivideSeaZones(
    List<List<String>> grid,
    String seaZoneId,
    void Function(String)? onLog,
  ) {
    final totalSea = _joinAndSeaService.countSeaCells(grid, seaZoneId);
    if (totalSea <= 0) return grid;
    final (newGrid, numSeaZones) = _joinAndSeaService.subdivideSeaZonesWithCap(
      grid,
      seaZoneId,
      totalSea,
    );
    onLog?.call(
      'Pass 11: Sea zone subdivision ($numSeaZones sea zones, cap ${(params.maxSeaZoneFraction * 100).toInt()}% of sea)',
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
    final joinImpl = _TileMapGenJoinSea(params, packageLogger(), graph);
    final lakesImpl = _TileMapGenLakesProvinces(params, graph, joinImpl);
    return lakesImpl.fillLakes(
      grid,
      seaZoneId,
      landSeeds,
      continentBySeedIndex,
    );
  }
}
