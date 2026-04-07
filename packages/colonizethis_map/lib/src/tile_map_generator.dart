// SPEC/program/tile-map-gen-algorithm.md, tile-map-gen-resources.md, tile-map-gen-config.md.

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';

import 'grid_voronoi.dart';
import 'topology_inference.dart';

part 'tile_map_generator_types.dart';
part 'tile_map_generator_graph.dart';
part 'tile_map_generator_join_sea.dart';
part 'tile_map_generator_terrain_assign.dart';
part 'tile_map_generator_land_seeds.dart';
part 'tile_map_generator_lakes_provinces.dart';

/// Shared state for [TileMapGenerator] mixins (avoids recursive `mixin on TileMapGenerator`).
abstract class _TileMapGeneratorShell {
  _TileMapGeneratorShell({this.params = const TileMapParams()});

  final TileMapParams params;
  final _log = mapLogger();
}

/// Generates a per-region tile map from province/continent params. SPEC/program/tile-map-gen-algorithm.md, tile-map-gen-resources.md, tile-map-gen-config.md.
/// Map-first: topology is inferred from the grid after generation.
class TileMapGenerator extends _TileMapGeneratorShell
    with
        _TileMapGeneratorGraph,
        _TileMapGeneratorJoinSeaAndJitter,
        _TileMapGeneratorTerrainAssign,
        _TileMapGeneratorLandSeeds,
        _TileMapGeneratorLakesProvinces {
  TileMapGenerator({super.params});

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
  }) {
    _log.i(
      'TileMapGenerator.generate start regionId=$regionId numProvinces=$numProvinces seed=${params.seed}',
    );
    if (numProvinces < 1) {
      throw ArgumentError('numProvinces must be at least 1');
    }
    if (numContinents < 1) {
      throw ArgumentError('numContinents must be at least 1');
    }
    _log.i(
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
    final provinceToContinent = buildProvinceToContinentMap(
      numProvinces,
      numContinents,
    );
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
      final placed = _placeLandSeeds(provinceToContinent, rnd);
      continentSeeds = placed.$1;
      landSeeds = placed.$2;
      continentBySeedIndex = placed.$3;
      onLog?.call(
        'Pass 2: Continent seeds ${continentSeeds.length}, land seeds ${landSeeds.length}',
      );
      grid = _assignLandByLandSeeds(
        grid,
        landSeeds,
        continentBySeedIndex,
        provinceToContinent,
        seaZoneId,
      );
    } else {
      // Organic: interleaved seed placement + small Voronoi + coastline growth
      final organic = _placeLandSeedsOrganic(
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

    // Pass 4: Fill lakes (ocean = sea connected to edge; lake → land; optional coastal swap)
    if (params.skipFillLakes) {
      onLog?.call('Pass 4: Fill lakes and moats skipped');
    } else {
      grid = _fillLakes(grid, seaZoneId, landSeeds, continentBySeedIndex);
      grid = _fillMoats(grid, seaZoneId, landSeeds, continentBySeedIndex, rnd);
      onLog?.call('Pass 4: Fill lakes and moats done');
    }

    // Pass 5: Border randomization (optional; sentinel = land)
    if (params.borderNoise > 0) {
      grid = _borderNoise(grid, seaZoneId, rnd);
      onLog?.call('Pass 5: Border noise applied');
    } else {
      onLog?.call('Pass 5: Border noise skipped (0)');
    }

    // Pass 6–7: Terrain and resource assignment (by map regionId; no province id)
    List<List<TerrainType?>>? terrainGrid;
    List<List<Resource?>>? resourceGrid;
    if (resourceRules != null) {
      final t = _assignTerrainAndResources(grid, regionId, resourceRules, rnd);
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
    final provinceSeeds = _placeProvinceSeedsOnLand(
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
    grid = _assignProvincesFromSeeds(grid, provinceSeeds, seaZoneId);
    onLog?.call('Pass 9: Province assignment complete');

    // Join step (optional): connect split land components per continent
    if (params.joinContinents) {
      final joinResult = _joinContinents(
        grid,
        terrainGrid,
        resourceGrid,
        provinceToContinent,
        seaZoneId,
        regionId,
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
      _jitterTerrainByProvince(grid, terrainGrid, resourceGrid, regionId, rnd);
    }

    // Pass 11: Sea zone subdivision with size cap (max fraction of total sea per zone).
    final totalSea = _countSeaCells(grid, seaZoneId);
    if (totalSea > 0) {
      final (newGrid, numSeaZones) = _subdivideSeaZonesWithCap(
        grid,
        seaZoneId,
        totalSea,
      );
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
    _log.i(
      'TileMapGenerator.generate end regionId=$regionId provinces=$provincesCount continents=$continentsCount success=true',
    );
    return (result, topology);
  }
}
