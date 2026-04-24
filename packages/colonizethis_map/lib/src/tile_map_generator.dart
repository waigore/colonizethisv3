// SPEC/program/tile-map-gen-algorithm.md, tile-map-gen-resources.md, tile-map-gen-config.md.

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'grid_voronoi.dart';
import 'map_validation_exception.dart';
import 'tile_map_distance_sentinels.dart';
import 'topology_inference.dart';

part 'tile_map_generator_types.dart';
part 'tile_map_grid_graph.dart';
part 'tile_map_generator_join_sea.dart';
part 'tile_map_generator_terrain_assign.dart';
part 'tile_map_generator_land_seeds.dart';
part 'tile_map_generator_lakes_provinces.dart';

/// Shared params for [TileMapGenerator] (generation orchestration only).
abstract class _TileMapGeneratorShell {
  _TileMapGeneratorShell({this.params = const TileMapParams()});

  final TileMapParams params;
}

class _LandSeedService {
  _LandSeedService(this._impl);
  final TileMapGenLandSeeds _impl;

  (List<(int x, int y)>, List<(int x, int y)>, List<int>) placeLandSeeds(
    Map<String, int> provinceToContinent,
    Random rnd,
  ) => _impl.placeLandSeeds(provinceToContinent, rnd);

  (List<(int x, int y)>, List<(int x, int y)>, List<int>, List<List<String>>)
  placeLandSeedsOrganic(
    List<List<String>> grid,
    Map<String, int> provinceToContinent,
    String seaZoneId,
    Random rnd,
  ) => _impl.placeLandSeedsOrganic(grid, provinceToContinent, seaZoneId, rnd);

  List<List<String>> assignLandByLandSeeds(
    List<List<String>> grid,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
    Map<String, int> provinceToContinent,
    String seaZoneId,
  ) => _impl.assignLandByLandSeeds(
    grid,
    landSeeds,
    continentBySeedIndex,
    provinceToContinent,
    seaZoneId,
  );
}

class _LakeAndProvinceService {
  _LakeAndProvinceService(this._impl);
  final _TileMapGenLakesProvinces _impl;

  List<List<String>> fillLakes(
    List<List<String>> grid,
    String seaZoneId,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
  ) => _impl.fillLakes(grid, seaZoneId, landSeeds, continentBySeedIndex);

  List<List<String>> fillMoats(
    List<List<String>> grid,
    String seaZoneId,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
    Random rnd,
  ) => _impl.fillMoats(grid, seaZoneId, landSeeds, continentBySeedIndex, rnd);

  List<List<String>> borderNoise(
    List<List<String>> grid,
    String seaZoneId,
    Random rnd,
  ) => _impl.borderNoise(grid, seaZoneId, rnd);

  Map<String, (int x, int y)> placeProvinceSeedsOnLand(
    List<List<String>> grid,
    Map<String, int> provinceToContinent,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
    String seaZoneId,
    Random rnd,
  ) => _impl.placeProvinceSeedsOnLand(
    grid,
    provinceToContinent,
    landSeeds,
    continentBySeedIndex,
    seaZoneId,
    rnd,
  );

  List<List<String>> assignProvincesFromSeeds(
    List<List<String>> grid,
    Map<String, (int x, int y)> provinceSeeds,
    String seaZoneId,
  ) => _impl.assignProvincesFromSeeds(grid, provinceSeeds, seaZoneId);
}

class _TerrainResourceService {
  _TerrainResourceService(this._impl);
  final _TileMapGenTerrainResource _impl;

  (List<List<TerrainType?>>, List<List<Resource?>>) assignTerrainAndResources(
    List<List<String>> grid,
    String regionId,
    ResourceRules rules,
    Random rnd,
  ) => _impl.assignTerrainAndResources(grid, regionId, rules, rnd);
}

class _JoinAndSeaService {
  _JoinAndSeaService(this._impl);
  final _TileMapGenJoinSea _impl;

  (List<List<String>>, List<List<TerrainType?>>?, List<List<Resource?>>?, bool)
  joinContinents(
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
  ) => _impl.joinContinents(
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

  void jitterTerrainByProvince(
    List<List<String>> grid,
    List<List<TerrainType?>> terrainGrid,
    List<List<Resource?>> resourceGrid,
    String regionId,
    Random rnd,
  ) => _impl.jitterTerrainByProvince(
    grid,
    terrainGrid,
    resourceGrid,
    regionId,
    rnd,
  );

  int countSeaCells(List<List<String>> grid, String seaZoneId) =>
      _impl.countSeaCells(grid, seaZoneId);

  (List<List<String>>, int) subdivideSeaZonesWithCap(
    List<List<String>> grid,
    String seaZoneId,
    int totalSea,
  ) => _impl.subdivideSeaZonesWithCap(grid, seaZoneId, totalSea);
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
      landSeedService: _LandSeedService(landImpl),
      lakeAndProvinceService: _LakeAndProvinceService(lakesImpl),
      terrainResourceService: _TerrainResourceService(terrainImpl),
      joinAndSeaService: _JoinAndSeaService(joinImpl),
    );
  }

  TileMapGenerator._({
    required super.params,
    required _LandSeedService landSeedService,
    required _LakeAndProvinceService lakeAndProvinceService,
    required _TerrainResourceService terrainResourceService,
    required _JoinAndSeaService joinAndSeaService,
  }) : _landSeedService = landSeedService,
       _lakeAndProvinceService = lakeAndProvinceService,
       _terrainResourceService = terrainResourceService,
       _joinAndSeaService = joinAndSeaService;

  final _LandSeedService _landSeedService;
  final _LakeAndProvinceService _lakeAndProvinceService;
  final _TerrainResourceService _terrainResourceService;
  final _JoinAndSeaService _joinAndSeaService;

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
    if (numProvinces < 1) {
      throw MapValidationException('numProvinces must be at least 1');
    }
    if (numContinents < 1) {
      throw MapValidationException('numContinents must be at least 1');
    }
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
    final Map<String, int> provinceToContinent;
    if (continentProvinceSizes != null) {
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
      provinceToContinent = buildProvinceToContinentMapFromCounts(
        continentProvinceSizes,
      );
    } else {
      provinceToContinent = buildProvinceToContinentMap(
        numProvinces,
        numContinents,
      );
    }
    final rnd = Random(params.seed);

    // Pass 1: Initialize grid (all sea)
    var grid = List.generate(
      params.height,
      (_) => List.filled(params.width, seaZoneId),
    );
    onLog?.call(
      'Pass 1: Grid initialized (${params.width}x${params.height}), all sea',
    );

    List<(int x, int y)> continentSeeds;
    List<(int x, int y)> landSeeds;
    List<int> continentBySeedIndex;

    if (params.seedBeforeAssignment) {
      // Pass 2–3 (fallback): Place all seeds, then one global Voronoi
      final placed = _landSeedService.placeLandSeeds(provinceToContinent, rnd);
      continentSeeds = placed.$1;
      landSeeds = placed.$2;
      continentBySeedIndex = placed.$3;
      onLog?.call(
        'Pass 2: Continent seeds ${continentSeeds.length}, land seeds ${landSeeds.length}',
      );
      grid = _landSeedService.assignLandByLandSeeds(
        grid,
        landSeeds,
        continentBySeedIndex,
        provinceToContinent,
        seaZoneId,
      );
    } else {
      // Organic: interleaved seed placement + small Voronoi + coastline growth
      final organic = _landSeedService.placeLandSeedsOrganic(
        grid,
        provinceToContinent,
        seaZoneId,
        rnd,
      );
      continentSeeds = organic.$1;
      landSeeds = organic.$2;
      continentBySeedIndex = organic.$3;
      grid = organic.$4;
      onLog?.call(
        'Pass 2–3 (organic): Continent seeds ${continentSeeds.length}, land seeds ${landSeeds.length}',
      );
    }

    if (landSeeds.isNotEmpty) {
      onLandSeedsPlaced?.call(
        List<(int x, int y)>.from(landSeeds),
        List<int>.from(continentBySeedIndex),
      );
    }
    if (continentSeeds.isNotEmpty) {
      onContinentSeedsPlaced?.call(List<(int x, int y)>.from(continentSeeds));
    }

    var landCount = 0;
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] == _landSentinel) landCount++;
      }
    }
    onLog?.call(
      'Pass 3: Land assignment complete ($landCount land, ${params.width * params.height - landCount} sea)',
    );

    // Pass 4: Fill lakes (ocean / lake per SPEC § Pass 4; lake → land; optional coastal swap)
    if (params.skipFillLakes) {
      onLog?.call('Pass 4: Fill lakes and moats skipped');
    } else {
      grid = _lakeAndProvinceService.fillLakes(
        grid,
        seaZoneId,
        landSeeds,
        continentBySeedIndex,
      );
      grid = _lakeAndProvinceService.fillMoats(
        grid,
        seaZoneId,
        landSeeds,
        continentBySeedIndex,
        rnd,
      );
      onLog?.call('Pass 4: Fill lakes and moats done');
    }

    // Pass 5: Border randomization (optional; sentinel = land)
    if (params.borderNoise > 0) {
      grid = _lakeAndProvinceService.borderNoise(grid, seaZoneId, rnd);
      onLog?.call('Pass 5: Border noise applied');
    } else {
      onLog?.call('Pass 5: Border noise skipped (0)');
    }

    // Pass 6–7: Terrain and resource assignment (by map regionId; no province id)
    List<List<TerrainType?>>? terrainGrid;
    List<List<Resource?>>? resourceGrid;
    if (resourceRules != null) {
      final t = _terrainResourceService.assignTerrainAndResources(
        grid,
        regionId,
        resourceRules,
        rnd,
      );
      terrainGrid = t.$1;
      resourceGrid = t.$2;
      var terrainCount = 0;
      var resourceCount = 0;
      for (var y = 0; y < params.height; y++) {
        for (var x = 0; x < params.width; x++) {
          if (terrainGrid[y][x] != null) terrainCount++;
          if (resourceGrid[y][x] != null) resourceCount++;
        }
      }
      onLog?.call('Pass 6: Terrain assigned ($terrainCount land cells)');
      onLog?.call('Pass 7: Resources placed ($resourceCount cells)');
    } else {
      onLog?.call(
        'Pass 6–7: Terrain/resources skipped (no rules or no provinces)',
      );
    }

    // Pass 8: Province seeds on land (one per province, per continent)
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

    // Pass 9: Province assignment (Voronoi on land; replace sentinel with province id)
    grid = _lakeAndProvinceService.assignProvincesFromSeeds(
      grid,
      provinceSeeds,
      seaZoneId,
    );
    onLog?.call('Pass 9: Province assignment complete');

    // Join step (optional): connect split land components per continent
    if (params.joinContinents) {
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
      grid = joinResult.$1;
      terrainGrid = joinResult.$2;
      resourceGrid = joinResult.$3;
      if (joinResult.$4) {
        onLog?.call('Pass 10: Join continents (land bridges added)');
      }
    }

    // Optional Pass 10b: province-aware terrain jitter (tiles without resources only).
    if (terrainGrid != null && resourceGrid != null) {
      _joinAndSeaService.jitterTerrainByProvince(
        grid,
        terrainGrid,
        resourceGrid,
        regionId,
        rnd,
      );
    }

    // Pass 11: Sea zone subdivision with size cap (max fraction of total sea per zone).
    final totalSea = _joinAndSeaService.countSeaCells(grid, seaZoneId);
    if (totalSea > 0) {
      final (newGrid, numSeaZones) = _joinAndSeaService
          .subdivideSeaZonesWithCap(grid, seaZoneId, totalSea);
      grid = newGrid;
      onLog?.call(
        'Pass 11: Sea zone subdivision ($numSeaZones sea zones, cap ${(params.maxSeaZoneFraction * 100).toInt()}% of sea)',
      );
    }

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
