// SPEC/program/tile-map-gen-algorithm.md, tile-map-gen-resources.md, tile-map-gen-config.md. Reference: SPEC/archive/tile-based-map-generation.md.

import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:logger/logger.dart';

import 'grid_voronoi.dart';
import 'topology_inference.dart';

/// Sentinel value for "land not yet assigned to a province". Replaced in Pass 9.
const String _landSentinel = '_land';

/// How land-shape seeds are placed around each continent seed. SPEC/program/tile-map-gen-algorithm.md § Pass 2.
enum LandSeedClusterShape {
  gaussian,
  uniformDisk,
  uniformAnnulus,
}

/// Centralized map generation parameters. SPEC/program/tile-map-gen-config.md § Grid size derivation.
class MapGenerationParams {
  const MapGenerationParams({
    this.targetTilesPerProvince = 35,
    this.seaFraction = 0.6,
    this.numContinents = 3,
    this.seed = 42,
    this.borderNoise = 0.0,
    this.maxEnforceIterations = 10,
    this.clusterShape = LandSeedClusterShape.gaussian,
    this.voronoiNoiseScale = 1.0,
    this.continentBufferTiles = 2,
    this.skipFillLakes = false,
    this.joinContinents = true,
    this.seedBeforeAssignment = false,
  })  : assert(targetTilesPerProvince >= 1),
        assert(seaFraction >= 0 && seaFraction < 1),
        assert(numContinents >= 1),
        assert(voronoiNoiseScale >= 0),
        assert(continentBufferTiles >= 0);

  /// Average land tiles per province; used to derive total land and grid size.
  final int targetTilesPerProvince;
  /// Fraction of grid that is sea (0–1); e.g. 0.6 for 60:40 sea:land.
  final double seaFraction;
  /// Number of continents; used when deriving grid size (e.g. when loading topology from file).
  final int numContinents;
  final int seed;
  /// 0–1; 0 = no border noise.
  final double borderNoise;
  final int maxEnforceIterations;
  /// How land-shape seeds are clustered around each continent seed.
  final LandSeedClusterShape clusterShape;
  /// Voronoi noise scale (0 = off). When > 0, perturb distance in Pass 3 for irregular boundaries.
  final double voronoiNoiseScale;
  /// Minimum Manhattan distance from another continent when assigning land (organic). 0 = legacy 1-tile.
  final int continentBufferTiles;
  /// When true, skip Pass 4 (no lake-to-land conversion).
  final bool skipFillLakes;
  /// When true, run join step after Pass 9 if a topology continent has multiple land components.
  final bool joinContinents;
  /// When true, use legacy land assignment (place all seeds first, then one Voronoi).
  /// When false (default), use organic land growing.
  final bool seedBeforeAssignment;
}

/// Computes grid width and height from province count and map params.
/// Uses land count, target tiles per province, and sea fraction. SPEC/program/tile-map-gen-config.md § Grid size derivation.
({int width, int height}) computeGridSizeFromParams(
  int numProvinces,
  MapGenerationParams params,
) {
  if (numProvinces == 0) return (width: 32, height: 24);
  final totalLandTiles = numProvinces * params.targetTilesPerProvince;
  final safeSea = params.seaFraction.clamp(0.0, 0.99);
  final totalTiles = (totalLandTiles / (1 - safeSea)).round();
  const aspect = 4 / 3;
  var height = sqrt(totalTiles / aspect).round();
  if (height < 8) height = 8;
  var width = (totalTiles / height).round();
  if (width < 8) width = 8;
  return (width: width, height: height);
}

/// Builds province-to-continent map by partitioning p1..pN across C continents.
/// Each continent gets a similar number of provinces (≈ N/C, remainder distributed).
Map<String, int> buildProvinceToContinentMap(int numProvinces, int numContinents) {
  if (numProvinces <= 0 || numContinents <= 0) return {};
  final result = <String, int>{};
  final continentSize = numProvinces ~/ numContinents;
  final remainder = numProvinces % numContinents;
  var idx = 0;
  for (var c = 0; c < numContinents; c++) {
    final size = continentSize + (c < remainder ? 1 : 0);
    for (var i = 0; i < size; i++) {
      result['p${idx + 1}'] = c;
      idx++;
    }
  }
  return result;
}

/// Returns continent index (0, 1, …) per province id from topology.
/// Continents = connected components of the land subgraph (P–P edges only). Sea zone is not in the result.
Map<String, int> computeContinentMembership(MapTopology topology) {
  final provinceIds = topology.nodes
      .where((n) => n.type == TopologyNodeType.province)
      .map((n) => n.id)
      .toSet();
  if (provinceIds.isEmpty) return {};
  final p2p = <String, Set<String>>{};
  for (final id in provinceIds) {
    p2p[id] = {};
  }
  for (final e in topology.edges) {
    if (provinceIds.contains(e.id1) && provinceIds.contains(e.id2)) {
      p2p[e.id1]!.add(e.id2);
      p2p[e.id2]!.add(e.id1);
    }
  }
  final continent = <String, int>{};
  var idx = 0;
  for (final start in provinceIds) {
    if (continent.containsKey(start)) continue;
    final queue = <String>[start];
    continent[start] = idx;
    while (queue.isNotEmpty) {
      final cur = queue.removeLast();
      for (final n in p2p[cur]!) {
        if (!continent.containsKey(n)) {
          continent[n] = idx;
          queue.add(n);
        }
      }
    }
    idx++;
  }
  return continent;
}

/// Runtime parameters for tile-based map generation (grid dimensions and generator options).
/// Pass 6 and Pass 10b terrain/jitter parameters are tunable here; see SPEC/program/tile-map-gen-config.md.
class TileMapParams {
  const TileMapParams({
    this.width = 100,
    this.height = 100,
    this.seed = 42,
    this.seaFraction = 0.6,
    this.borderNoise = 0.0,
    this.maxEnforceIterations = 10,
    this.clusterShape = LandSeedClusterShape.gaussian,
    this.voronoiNoiseScale = 1.0,
    this.continentBufferTiles = 2,
    this.skipFillLakes = false,
    this.joinContinents = true,
    this.seedBeforeAssignment = false,
    this.maxSeaZoneFraction = 0.05,
    // Pass 6a — mountain ridges
    this.mountainRangesFactor = 0.3,
    this.mountainRangesMin = 1,
    this.mountainRangesMax = 8,
    this.mountainRangeMinLength = 10,
    // Pass 6b — region-growing
    this.terrainSeedsFactor = 0.35,
    this.terrainSeedsMin = 1,
    this.terrainSeedsMax = 48,
    this.terrainMacroFraction = 0.7,
    // Pass 6b — pattern refinement
    this.patternMinBlobSize = 20,
    this.patternMaxFractionPerBlob = 0.1,
    this.patternSeedFactor = 0.3,
    this.patternMaxSeedsPerBlob = 6,
    this.patternMaxChangesPerSeed = 12,
    this.patternMaxRadius = 4,
    // Pass 10b — jitter
    this.jitterHomogeneityThreshold = 0.85,
    this.jitterMaxFraction = 0.1,
    this.jitterProbability = 0.25,
    this.jitterMinProvinceSize = 10,
    this.jitterNeighborSupportThreshold = 2,
    // Pass 7 — multi-region resource cap
    this.multiRegionResourceCapFraction = 0.30,
  })  : assert(seaFraction >= 0 && seaFraction < 1),
        assert(voronoiNoiseScale >= 0),
        assert(continentBufferTiles >= 0),
        assert(maxSeaZoneFraction > 0 && maxSeaZoneFraction <= 1),
        assert(mountainRangesFactor >= 0),
        assert(mountainRangesMin >= 0),
        assert(mountainRangesMax >= mountainRangesMin),
        assert(mountainRangeMinLength >= 0),
        assert(terrainSeedsFactor >= 0),
        assert(terrainSeedsMin >= 0),
        assert(terrainSeedsMax >= terrainSeedsMin),
        assert(terrainMacroFraction >= 0 && terrainMacroFraction <= 1),
        assert(patternMinBlobSize >= 0),
        assert(patternMaxFractionPerBlob >= 0 && patternMaxFractionPerBlob <= 1),
        assert(patternSeedFactor >= 0),
        assert(patternMaxSeedsPerBlob >= 0),
        assert(patternMaxChangesPerSeed >= 0),
        assert(patternMaxRadius >= 0),
        assert(jitterHomogeneityThreshold >= 0 && jitterHomogeneityThreshold <= 1),
        assert(jitterMaxFraction >= 0 && jitterMaxFraction <= 1),
        assert(jitterProbability >= 0 && jitterProbability <= 1),
        assert(jitterMinProvinceSize >= 0),
        assert(jitterNeighborSupportThreshold >= 0),
        assert(multiRegionResourceCapFraction >= 0 && multiRegionResourceCapFraction <= 1);

  final int width;
  final int height;
  final int seed;
  /// Fraction of grid that is sea (0–1); used for land budget in Pass 3.
  final double seaFraction;
  /// 0–1; 0 = no border noise.
  final double borderNoise;
  final int maxEnforceIterations;
  /// How land-shape seeds are clustered around each continent seed.
  final LandSeedClusterShape clusterShape;
  /// Voronoi noise scale (0 = off). When > 0, perturb distance in Pass 3.
  final double voronoiNoiseScale;
  /// Minimum Manhattan distance from another continent when assigning land (organic). 0 = legacy 1-tile.
  final int continentBufferTiles;
  /// When true, skip Pass 4 (no lake-to-land conversion).
  final bool skipFillLakes;
  /// When true, run join step after Pass 9 when needed.
  final bool joinContinents;
  /// When true, use legacy land assignment (place all seeds first, then one Voronoi).
  final bool seedBeforeAssignment;
  /// Max fraction of total sea tiles per sea zone (Pass 11); e.g. 0.05 = 5%.
  final double maxSeaZoneFraction;

  // --- Pass 6a (mountain ridges)
  final double mountainRangesFactor;
  final int mountainRangesMin;
  final int mountainRangesMax;
  final int mountainRangeMinLength;

  // --- Pass 6b (region-growing)
  final double terrainSeedsFactor;
  final int terrainSeedsMin;
  final int terrainSeedsMax;
  final double terrainMacroFraction;

  // --- Pass 6b (pattern refinement)
  final int patternMinBlobSize;
  final double patternMaxFractionPerBlob;
  final double patternSeedFactor;
  final int patternMaxSeedsPerBlob;
  final int patternMaxChangesPerSeed;
  final int patternMaxRadius;

  // --- Pass 10b (jitter)
  final double jitterHomogeneityThreshold;
  final double jitterMaxFraction;
  final double jitterProbability;
  final int jitterMinProvinceSize;
  final int jitterNeighborSupportThreshold;

  // --- Pass 7 (resources)
  /// Max fraction of placed resources that may be multi-region ("both") per map. Default 0.30.
  final double multiRegionResourceCapFraction;
}

/// Tracks both-count and total for multi-region resource cap (Pass 7). SPEC/game/resource-terrain-region-rules.md.
class _MultiRegionCapState {
  _MultiRegionCapState(this.capFraction, this.rules, this.regionId);

  factory _MultiRegionCapState.fromExisting(
    double capFraction,
    ResourceRules rules,
    String regionId,
    List<List<Resource?>> resourceGrid,
  ) {
    var both = 0, total = 0;
    for (final row in resourceGrid) {
      for (final r in row) {
        if (r == null) continue;
        total++;
        if (rules.regionRule[r] == ResourceRegionRule.both) both++;
      }
    }
    final s = _MultiRegionCapState(capFraction, rules, regionId);
    s.bothCount = both;
    s.totalCount = total;
    return s;
  }

  int bothCount = 0;
  int totalCount = 0;
  final double capFraction;
  final ResourceRules rules;
  final String regionId;

  bool shouldRestrictToRegionOnly(List<Resource> allowed) {
    if (totalCount == 0) return false;
    if (bothCount / totalCount < capFraction) return false;
    final hasBoth =
        allowed.any((r) => rules.regionRule[r] == ResourceRegionRule.both);
    final hasRegionOnly =
        allowed.any((r) => rules.regionRule[r] != ResourceRegionRule.both);
    return hasBoth && hasRegionOnly;
  }

  List<Resource> filterToRegionOnly(List<Resource> allowed) => allowed
      .where((r) => rules.regionRule[r] != ResourceRegionRule.both)
      .toList();

  void record(Resource r) {
    totalCount++;
    if (rules.regionRule[r] == ResourceRegionRule.both) bothCount++;
  }
}

/// Generates a per-region tile map from province/continent params. SPEC/program/tile-map-gen-algorithm.md, tile-map-gen-resources.md, tile-map-gen-config.md.
/// Map-first: topology is inferred from the grid after generation.
class TileMapGenerator {
  TileMapGenerator({this.params = const TileMapParams()});

  final TileMapParams params;

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
    void Function(List<(int x, int y)> landSeeds, List<int> continentIndices)? onLandSeedsPlaced,
    void Function(List<(int x, int y)> continentSeeds)? onContinentSeedsPlaced,
  }) {
    Logger().i('map: TileMapGenerator.generate start regionId=$regionId numProvinces=$numProvinces seed=${params.seed}');
    if (numProvinces < 1) {
      throw ArgumentError('numProvinces must be at least 1');
    }
    if (numContinents < 1) {
      throw ArgumentError('numContinents must be at least 1');
    }
    final provinceToContinent = buildProvinceToContinentMap(numProvinces, numContinents);
    final rnd = Random(params.seed);

    // Pass 1: Initialize grid (all sea)
    var grid = List.generate(
      params.height,
      (_) => List.filled(params.width, seaZoneId),
    );
    onLog?.call('Pass 1: Grid initialized (${params.width}x${params.height}), all sea');

    List<(int x, int y)> continentSeeds;
    List<(int x, int y)> landSeeds;
    List<int> continentBySeedIndex;

    if (params.seedBeforeAssignment) {
      // Pass 2–3 (fallback): Place all seeds, then one global Voronoi
      final placed = _placeLandSeeds(provinceToContinent, rnd);
      continentSeeds = placed.$1;
      landSeeds = placed.$2;
      continentBySeedIndex = placed.$3;
      onLog?.call('Pass 2: Continent seeds ${continentSeeds.length}, land seeds ${landSeeds.length}');
      grid = _assignLandByLandSeeds(grid, landSeeds, continentBySeedIndex, provinceToContinent, seaZoneId);
    } else {
      // Organic: interleaved seed placement + small Voronoi + coastline growth
      final organic = _placeLandSeedsOrganic(grid, provinceToContinent, seaZoneId, rnd);
      continentSeeds = organic.$1;
      landSeeds = organic.$2;
      continentBySeedIndex = organic.$3;
      grid = organic.$4;
      onLog?.call('Pass 2–3 (organic): Continent seeds ${continentSeeds.length}, land seeds ${landSeeds.length}');
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
    onLog?.call('Pass 3: Land assignment complete ($landCount land, ${params.width * params.height - landCount} sea)');

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
      onLog?.call('Pass 6–7: Terrain/resources skipped (no rules or no provinces)');
    }

    // Pass 8: Province seeds on land (one per province, per continent)
    final provinceSeeds = _placeProvinceSeedsOnLand(
        grid, provinceToContinent, landSeeds, continentBySeedIndex, seaZoneId, rnd);
    onLog?.call('Pass 8: Province seeds on land (${provinceSeeds.length} provinces)');

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
      final (newGrid, numSeaZones) = _subdivideSeaZonesWithCap(grid, seaZoneId, totalSea);
      grid = newGrid;
      onLog?.call('Pass 11: Sea zone subdivision ($numSeaZones sea zones, cap ${(params.maxSeaZoneFraction * 100).toInt()}% of sea)');
    }

    final result = TileMapResult(
      width: params.width,
      height: params.height,
      grid: grid,
      terrainGrid: terrainGrid,
      resourceGrid: resourceGrid,
    );
    final topology = inferTopologyFromTileMap(result, regionId, seaZoneId);
    Logger().i('map: TileMapGenerator.generate end regionId=$regionId provinces=${topology.nodes.where((n) => n.type == TopologyNodeType.province).length}');
    return (result, topology);
  }

  /// Province-aware terrain jitter (Pass 10b): introduce small variation inside
  /// highly homogeneous provinces by changing terrain on a limited number of
  /// tiles that have no resource assigned.
  void _jitterTerrainByProvince(
    List<List<String>> grid,
    List<List<TerrainType?>> terrainGrid,
    List<List<Resource?>> resourceGrid,
    String regionId,
    Random rnd,
  ) {
    final allowedNonMountain = allowedTerrainsForRegion(regionId)
        .where((t) => t != TerrainType.mountain)
        .toList();
    if (allowedNonMountain.isEmpty) return;

    final height = grid.length;
    if (height == 0) return;
    final width = grid[0].length;

    // Build province -> tiles mapping.
    final tilesByProvince = <String, List<(int x, int y)>>{};
    final provinceIdPattern = RegExp(r'^p\d+$');
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final id = grid[y][x];
        if (!provinceIdPattern.hasMatch(id)) continue;
        tilesByProvince.putIfAbsent(id, () => []).add((x, y));
      }
    }
    if (tilesByProvince.isEmpty) return;

    const directions4 = <(int dx, int dy)>[
      (0, -1),
      (1, 0),
      (0, 1),
      (-1, 0),
    ];
    const directions8 = <(int dx, int dy)>[
      (0, -1),
      (1, 0),
      (0, 1),
      (-1, 0),
      (-1, -1),
      (1, -1),
      (1, 1),
      (-1, 1),
    ];

    for (final entry in tilesByProvince.entries) {
      final tiles = entry.value;
      if (tiles.length < params.jitterMinProvinceSize) continue;

      // Terrain histogram.
      final counts = <TerrainType, int>{};
      var terrainTiles = 0;
      for (final (x, y) in tiles) {
        final t = terrainGrid[y][x];
        if (t == null) continue;
        counts[t] = (counts[t] ?? 0) + 1;
        terrainTiles++;
      }
      if (terrainTiles == 0 || counts.isEmpty) continue;

      // Find dominant terrain.
      TerrainType dominant = counts.keys.first;
      var maxCount = counts[dominant]!;
      for (final e in counts.entries) {
        if (e.value > maxCount) {
          dominant = e.key;
          maxCount = e.value;
        }
      }
      final fDom = maxCount / terrainTiles;
      if (fDom < params.jitterHomogeneityThreshold) continue;

      // Candidate tiles: dominant terrain, no resource, and lying on a
      // terrain or province edge.
      final candidates = <(int x, int y)>[];
      for (final (x, y) in tiles) {
        if (terrainGrid[y][x] != dominant) continue;
        if (resourceGrid[y][x] != null) continue;

        var isEdge = false;
        // Terrain-edge or province-edge in 4-neighborhood.
        for (final (dx, dy) in directions4) {
          final nx = x + dx;
          final ny = y + dy;
          if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
          final neighborProvince = grid[ny][nx];
          final neighborTerrain = terrainGrid[ny][nx];
          if (neighborProvince != entry.key) {
            isEdge = true; // province-edge
            break;
          }
          if (neighborTerrain != null && neighborTerrain != dominant) {
            isEdge = true; // terrain-edge within same province
            break;
          }
        }
        if (!isEdge) continue;

        candidates.add((x, y));
      }
      if (candidates.isEmpty) continue;

      candidates.shuffle(rnd);
      final maxChanges = (params.jitterMaxFraction * tiles.length).floor();
      if (maxChanges <= 0) continue;
      var changes = 0;

      for (final (x, y) in candidates) {
        if (changes >= maxChanges) break;
        if (rnd.nextDouble() > params.jitterProbability) continue;

        // Prefer neighboring terrains within same province that are not
        // dominant, and require a minimum neighbor support threshold.
        final neighborCounts = <TerrainType, int>{};
        for (final (dx, dy) in directions8) {
          final nx = x + dx;
          final ny = y + dy;
          if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
          if (grid[ny][nx] != entry.key) continue; // same province only
          final nt = terrainGrid[ny][nx];
          if (nt == null || nt == dominant || nt == TerrainType.mountain) continue;
          neighborCounts[nt] = (neighborCounts[nt] ?? 0) + 1;
        }

        final supported = neighborCounts.entries
            .where((e) => e.value >= params.jitterNeighborSupportThreshold)
            .map((e) => e.key)
            .toList();
        if (supported.isEmpty) {
          // No terrain with enough local support; skip to avoid isolated speckles.
          continue;
        }

        final newTerrain = supported[rnd.nextInt(supported.length)];
        terrainGrid[y][x] = newTerrain;
        changes++;
      }
    }
  }

  /// Join step: for each continent with >1 land component, connect two by a shortest path of sea cells. Returns (grid, terrainGrid, resourceGrid, didJoin).
  (List<List<String>>, List<List<TerrainType?>>?, List<List<Resource?>>?, bool) _joinContinents(
    List<List<String>> grid,
    List<List<TerrainType?>>? terrainGrid,
    List<List<Resource?>>? resourceGrid,
    Map<String, int> provinceToContinent,
    String seaZoneId,
    String? mapRegionId,
    ResourceRules? resourceRules,
    Random rnd,
  ) {
    if (provinceToContinent.isEmpty) return (grid, terrainGrid, resourceGrid, false);
    final numContinents = provinceToContinent.values.toSet().length;
    var didJoin = false;
    var g = grid.map((row) => row.toList()).toList();
    var tg = terrainGrid != null ? terrainGrid.map((row) => row.toList()).toList() : null;
    var rg = resourceGrid != null ? resourceGrid.map((row) => row.toList()).toList() : null;
    final ocean = _oceanCells(g, seaZoneId);

    final capState = (tg != null &&
            rg != null &&
            mapRegionId != null &&
            resourceRules != null &&
            (mapRegionId == 'oldWorld' || mapRegionId == 'newWorld'))
        ? _MultiRegionCapState.fromExisting(
            params.multiRegionResourceCapFraction,
            resourceRules,
            mapRegionId,
            rg,
          )
        : null;

    for (var c = 0; c < numContinents; c++) {
      while (true) {
        final landCells = _landCellsForContinent(g, provinceToContinent, c, seaZoneId);
        final components = _connectedComponentsOfLand(landCells);
        if (components.length <= 1) break;
        didJoin = true;
        final compA = components[0];
        final compB = components[1];
        final path = _shortestSeaPath(g, seaZoneId, compA, compB);
        if (path.isEmpty) break;
        final provinceId = _provinceIdAdjacentToSeaPath(g, compA, path);
        for (final (x, y) in path) {
          g[y][x] = provinceId;
          if (tg != null && rg != null && mapRegionId != null && resourceRules != null) {
            _assignTerrainAndResourceForCell(
              tg,
              rg,
              x,
              y,
              mapRegionId,
              resourceRules,
              rnd,
              capState: capState,
            );
          }
        }
        _preserveSeaFraction(g, tg, rg, seaZoneId, ocean, path.length);
      }
    }
    return (g, tg, rg, didJoin);
  }

  Set<(int x, int y)> _landCellsForContinent(
    List<List<String>> grid,
    Map<String, int> membership,
    int continentIndex,
    String seaZoneId,
  ) {
    final out = <(int x, int y)>{};
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        final id = grid[y][x];
        if (id == seaZoneId) continue;
        if (membership[id] == continentIndex) out.add((x, y));
      }
    }
    return out;
  }

  List<Set<(int x, int y)>> _connectedComponentsOfLand(Set<(int x, int y)> landCells) {
    if (landCells.isEmpty) return [];
    final result = <Set<(int x, int y)>>[];
    final remaining = Set<(int x, int y)>.from(landCells);
    while (remaining.isNotEmpty) {
      final start = remaining.first;
      remaining.remove(start);
      final component = <(int x, int y)>{start};
      final queue = <(int x, int y)>[start];
      while (queue.isNotEmpty) {
        final (x, y) = queue.removeLast();
        for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
          final n = (x + dx, y + dy);
          if (remaining.remove(n)) {
            component.add(n);
            queue.add(n);
          }
        }
      }
      result.add(component);
    }
    return result;
  }

  /// Pass 11: 4-connected components of sea cells (grid cells with seaZoneId).
  List<Set<(int x, int y)>> _connectedComponentsOfSea(
    List<List<String>> grid,
    String seaZoneId,
  ) {
    final seaCells = <(int x, int y)>{};
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] == seaZoneId) seaCells.add((x, y));
      }
    }
    return _connectedComponentsOfLand(seaCells);
  }

  /// Assign s1, s2, … to sea components; sort by (minY, minX). Returns new grid.
  List<List<String>> _assignSeaZoneIds(
    List<List<String>> grid,
    List<Set<(int x, int y)>> components,
    String seaZoneId,
  ) {
    final sorted = List<Set<(int x, int y)>>.from(components)
      ..sort((a, b) {
        final (minYa, minXa) = _minYx(a);
        final (minYb, minXb) = _minYx(b);
        if (minYa != minYb) return minYa.compareTo(minYb);
        return minXa.compareTo(minXb);
      });
    final g = grid.map((row) => row.toList()).toList();
    for (var i = 0; i < sorted.length; i++) {
      final id = 's${i + 1}';
      for (final (x, y) in sorted[i]) {
        g[y][x] = id;
      }
    }
    return g;
  }

  (int, int) _minYx(Set<(int x, int y)> cells) {
    var minY = params.height;
    var minX = params.width;
    for (final (x, y) in cells) {
      if (y < minY || (y == minY && x < minX)) {
        minY = y;
        minX = x;
      }
    }
    return (minY, minX);
  }

  int _countSeaCells(List<List<String>> grid, String seaZoneId) {
    var n = 0;
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] == seaZoneId) n++;
      }
    }
    return n;
  }

  /// Pass 11: Subdivide sea so each zone has at most maxSeaZoneFraction * totalSea tiles.
  /// Returns (newGrid, total sea zone count).
  (List<List<String>>, int) _subdivideSeaZonesWithCap(
    List<List<String>> grid,
    String seaZoneId,
    int totalSea,
  ) {
    final components = _connectedComponentsOfSea(grid, seaZoneId);
    if (components.isEmpty) return (grid, 0);
    final sorted = List<Set<(int x, int y)>>.from(components)
      ..sort((a, b) {
        final (minYa, minXa) = _minYx(a);
        final (minYb, minXb) = _minYx(b);
        if (minYa != minYb) return minYa.compareTo(minYb);
        return minXa.compareTo(minXb);
      });
    final g = grid.map((row) => row.toList()).toList();
    final maxPerZone = (params.maxSeaZoneFraction * totalSea).floor();
    var nextSeaZoneIndex = 1;
    for (final component in sorted) {
      final size = component.length;
      if (maxPerZone <= 0 || size <= maxPerZone) {
        final id = 's$nextSeaZoneIndex';
        nextSeaZoneIndex++;
        for (final (x, y) in component) {
          g[y][x] = id;
        }
        continue;
      }
      final K = (size / maxPerZone).ceil().clamp(1, size);
      final seeds = _placeSeaSeedsFarthestPoint(component, K);
      final seedMap = <String, (int x, int y)>{
        for (var i = 0; i < seeds.length; i++) 's${nextSeaZoneIndex + i}': seeds[i],
      };
      final assignment = assignCellsToNearestSeed(
        component,
        seedMap,
        noiseScale: params.voronoiNoiseScale,
        noiseSeed: params.seed,
      );
      for (final entry in assignment.entries) {
        final (x, y) = entry.key;
        g[y][x] = entry.value;
      }
      nextSeaZoneIndex += K;
    }
    return (g, nextSeaZoneIndex - 1);
  }

  /// Place K well-spread seeds in [cells] using farthest-point sampling.
  List<(int x, int y)> _placeSeaSeedsFarthestPoint(Set<(int x, int y)> cells, int K) {
    if (cells.isEmpty || K <= 0) return [];
    final list = cells.toList();
    if (K >= list.length) return list;
    list.sort((a, b) {
      if (a.$2 != b.$2) return a.$2.compareTo(b.$2);
      return a.$1.compareTo(b.$1);
    });
    final chosen = <(int x, int y)>[list.first];
    for (var i = 1; i < K; i++) {
      var bestCell = list.first;
      var bestMinD2 = 0;
      for (final (x, y) in list) {
        if (chosen.contains((x, y))) continue;
        var minD2 = 0x7fffffff;
        for (final (sx, sy) in chosen) {
          final d2 = (x - sx) * (x - sx) + (y - sy) * (y - sy);
          if (d2 < minD2) minD2 = d2;
        }
        if (minD2 > bestMinD2) {
          bestMinD2 = minD2;
          bestCell = (x, y);
        }
      }
      chosen.add(bestCell);
    }
    return chosen;
  }

  /// Shortest path of sea cells from (sea cells adjacent to compA) to (sea cells adjacent to compB). BFS; returns path including endpoints.
  List<(int x, int y)> _shortestSeaPath(
    List<List<String>> grid,
    String seaZoneId,
    Set<(int x, int y)> compA,
    Set<(int x, int y)> compB,
  ) {
    final compASet = compA;
    final compBSet = compB;
    final seaAdjacentToA = <(int x, int y)>{};
    for (final (x, y) in compASet) {
      for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx >= 0 && nx < params.width && ny >= 0 && ny < params.height &&
            grid[ny][nx] == seaZoneId) {
          seaAdjacentToA.add((nx, ny));
        }
      }
    }
    final seaAdjacentToB = <(int x, int y)>{};
    for (final (x, y) in compBSet) {
      for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx >= 0 && nx < params.width && ny >= 0 && ny < params.height &&
            grid[ny][nx] == seaZoneId) {
          seaAdjacentToB.add((nx, ny));
        }
      }
    }
    if (seaAdjacentToA.isEmpty || seaAdjacentToB.isEmpty) return [];
    final prev = <(int x, int y), (int x, int y)?>{};
    final queue = <(int x, int y)>[];
    for (final p in seaAdjacentToA) {
      prev[p] = null;
      queue.add(p);
    }
    (int x, int y)? goal;
    while (queue.isNotEmpty && goal == null) {
      final (x, y) = queue.removeAt(0);
      if (seaAdjacentToB.contains((x, y))) {
        goal = (x, y);
        break;
      }
      for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) continue;
        if (grid[ny][nx] != seaZoneId) continue;
        final n = (nx, ny);
        if (prev.containsKey(n)) continue;
        prev[n] = (x, y);
        queue.add(n);
      }
    }
    if (goal == null) return [];
    final path = <(int x, int y)>[];
    (int x, int y)? cur = goal;
    while (cur != null) {
      path.add(cur);
      cur = prev[cur];
    }
    return path.reversed.toList();
  }

  String _provinceIdAdjacentToSeaPath(
    List<List<String>> grid,
    Set<(int x, int y)> compA,
    List<(int x, int y)> path,
  ) {
    for (final (px, py) in path) {
      for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
        final nx = px + dx;
        final ny = py + dy;
        if (nx >= 0 && nx < params.width && ny >= 0 && ny < params.height &&
            compA.contains((nx, ny))) {
          return grid[ny][nx];
        }
      }
    }
    final anyInA = compA.first;
    return grid[anyInA.$2][anyInA.$1];
  }

  void _assignTerrainAndResourceForCell(
    List<List<TerrainType?>> terrainGrid,
    List<List<Resource?>> resourceGrid,
    int x,
    int y,
    String mapRegionId,
    ResourceRules rules,
    Random rnd, {
    _MultiRegionCapState? capState,
  }) {
    final landTerrains = allowedTerrainsForRegion(mapRegionId);
    if (landTerrains.isEmpty) return;
    terrainGrid[y][x] = landTerrains[rnd.nextInt(landTerrains.length)];
    final terrain = terrainGrid[y][x]!;
    var allowed = Resource.values
        .where((r) =>
            rules.isAllowedInRegion(r, mapRegionId) &&
            rules.isAllowedOnTerrain(r, terrain))
        .toList();
    if (allowed.isEmpty) return;
    if (capState != null &&
        (mapRegionId == 'oldWorld' || mapRegionId == 'newWorld') &&
        capState.shouldRestrictToRegionOnly(allowed)) {
      allowed = capState.filterToRegionOnly(allowed);
      if (allowed.isEmpty) return;
    }
    if (rnd.nextDouble() > 0.4) return;
    final weights = allowed.map((r) => rules.spawnWeight(r)).toList();
    final sum = weights.reduce((a, b) => a + b);
    var roll = rnd.nextDouble() * sum;
    for (var i = 0; i < allowed.length; i++) {
      roll -= weights[i];
      if (roll <= 0) {
        final placed = allowed[i];
        resourceGrid[y][x] = placed;
        capState?.record(placed);
        break;
      }
    }
  }

  void _preserveSeaFraction(
    List<List<String>> grid,
    List<List<TerrainType?>>? terrainGrid,
    List<List<Resource?>>? resourceGrid,
    String seaZoneId,
    Set<(int x, int y)> ocean,
    int count,
  ) {
    final coastal = <(int x, int y)>[];
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] == seaZoneId) continue;
        final oceanNeighbours = [
          (x - 1, y),
          (x + 1, y),
          (x, y - 1),
          (x, y + 1),
        ].where((p) => p.$1 >= 0 && p.$1 < params.width && p.$2 >= 0 && p.$2 < params.height &&
            grid[p.$2][p.$1] == seaZoneId && ocean.contains(p)).length;
        if (oceanNeighbours >= 1) coastal.add((x, y));
      }
    }
    coastal.sort((a, b) {
      final na = [
        (a.$1 - 1, a.$2),
        (a.$1 + 1, a.$2),
        (a.$1, a.$2 - 1),
        (a.$1, a.$2 + 1),
      ].where((p) => p.$1 >= 0 && p.$1 < params.width && p.$2 >= 0 && p.$2 < params.height &&
          grid[p.$2][p.$1] == seaZoneId && ocean.contains(p)).length;
      final nb = [
        (b.$1 - 1, b.$2),
        (b.$1 + 1, b.$2),
        (b.$1, b.$2 - 1),
        (b.$1, b.$2 + 1),
      ].where((p) => p.$1 >= 0 && p.$1 < params.width && p.$2 >= 0 && p.$2 < params.height &&
          grid[p.$2][p.$1] == seaZoneId && ocean.contains(p)).length;
      return nb.compareTo(na);
    });
    for (var i = 0; i < count && i < coastal.length; i++) {
      final (x, y) = coastal[i];
      grid[y][x] = seaZoneId;
      if (terrainGrid != null) terrainGrid[y][x] = null;
      if (resourceGrid != null) resourceGrid[y][x] = null;
    }
  }

  (List<List<TerrainType?>>, List<List<Resource?>>) _assignTerrainAndResources(
    List<List<String>> grid,
    String mapRegionId,
    ResourceRules rules,
    Random rnd,
  ) {
    final terrainGrid = List.generate(
      params.height,
      (_) => List.filled(params.width, null as TerrainType?),
    );
    final resourceGrid = List.generate(
      params.height,
      (_) => List.filled(params.width, null as Resource?),
    );

    // Collect land cells (sentinel) for terrain assignment.
    final landCells = <(int x, int y)>[];
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] == _landSentinel) {
          landCells.add((x, y));
        }
      }
    }
    if (landCells.isEmpty) {
      // No land; nothing to assign.
      return (terrainGrid, resourceGrid);
    }

    final distribution = terrainDistributionForRegion(mapRegionId);

    // Pass 6a: mountain ridges (random-walk ranges).
    _assignMountainRidges(terrainGrid, grid, landCells, distribution, rnd);

    // Pass 6b: region-growing for non-mountain terrains.
    _assignNonMountainTerrainsRegionGrowing(
      terrainGrid,
      grid,
      mapRegionId,
      distribution,
      rnd,
    );

    // Pass 7: resources, using final terrainGrid and existing rules.
    final capState = (mapRegionId == 'oldWorld' || mapRegionId == 'newWorld')
        ? _MultiRegionCapState(
            params.multiRegionResourceCapFraction,
            rules,
            mapRegionId,
          )
        : null;

    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] != _landSentinel) {
          // Sea: no terrain, no resource.
          continue;
        }
        final terrain = terrainGrid[y][x];
        if (terrain == null) continue;
        var allowed = Resource.values
            .where((r) =>
                rules.isAllowedInRegion(r, mapRegionId) &&
                rules.isAllowedOnTerrain(r, terrain))
            .toList();
        if (allowed.isEmpty) continue;
        // Multi-region cap: when at cap, restrict to region-only where possible.
        if (capState != null && capState.shouldRestrictToRegionOnly(allowed)) {
          allowed = capState.filterToRegionOnly(allowed);
          if (allowed.isEmpty) continue;
        }
        // 40% chance to place any resource on eligible land; then weighted pick.
        if (rnd.nextDouble() > 0.4) continue;
        final weights = allowed.map((r) => rules.spawnWeight(r)).toList();
        final sum = weights.reduce((a, b) => a + b);
        var roll = rnd.nextDouble() * sum;
        for (var i = 0; i < allowed.length; i++) {
          roll -= weights[i];
          if (roll <= 0) {
            final placed = allowed[i];
            resourceGrid[y][x] = placed;
            capState?.record(placed);
            break;
          }
        }
      }
    }

    return (terrainGrid, resourceGrid);
  }

  /// Pass 6a: generate mountain ridges via random walks over land cells.
  void _assignMountainRidges(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    List<(int x, int y)> landCells,
    TerrainDistribution distribution,
    Random rnd,
  ) {
    final totalLand = landCells.length;
    if (totalLand == 0) return;
    final targetMountain =
        (distribution.mountainFraction * totalLand).round().clamp(0, totalLand);
    if (targetMountain <= 0) return;

    // Determine number of ranges based on target mountain tiles.
    final suggestedRanges =
        (params.mountainRangesFactor * sqrt(targetMountain)).round().clamp(
              params.mountainRangesMin,
              params.mountainRangesMax,
            );
    final numRanges = suggestedRanges.clamp(1, targetMountain);
    if (numRanges <= 0) return;

    var remainingMountain = targetMountain;

    // Helper to pick a start cell biased away from edges and existing mountains.
    (int x, int y)? pickStart() {
      const maxAttempts = 1000;
      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        final (cx, cy) = landCells[rnd.nextInt(landCells.length)];
        if (terrainGrid[cy][cx] == TerrainType.mountain) continue;
        // Prefer interior cells (not on border).
        if (cx <= 0 ||
            cx >= params.width - 1 ||
            cy <= 0 ||
            cy >= params.height - 1) {
          // Still acceptable, but try to find interior cells first.
          if (rnd.nextDouble() < 0.7) continue;
        }
        return (cx, cy);
      }
      return null;
    }

    // 4-connected directions: up, right, down, left.
    const directions = <(int dx, int dy)>[
      (0, -1),
      (1, 0),
      (0, 1),
      (-1, 0),
    ];

    for (var r = 0; r < numRanges && remainingMountain > 0; r++) {
      final start = pickStart();
      if (start == null) break;
      var (x, y) = start;
      terrainGrid[y][x] = TerrainType.mountain;
      remainingMountain--;

      // Target length per range, clipped by remaining budget and minimum.
      final idealLength = (targetMountain / numRanges).round();
      final maxLengthForRange = idealLength.clamp(
        params.mountainRangeMinLength,
        targetMountain,
      );
      var placedThisRange = 1;

      // Initial direction.
      var dir = directions[rnd.nextInt(directions.length)];

      const pForward = 0.6;
      const pTurn = 0.3;
      const maxTurnRetries = 4;

      while (placedThisRange < maxLengthForRange && remainingMountain > 0) {
        // Choose a new direction with persistence.
        (int dx, int dy) pickDirection((int dx, int dy) current) {
          final roll = rnd.nextDouble();
          if (roll < pForward) {
            return current;
          } else if (roll < pForward + pTurn) {
            // Turn left or right relative to current direction.
            final left = (-current.$2, current.$1);
            final right = (current.$2, -current.$1);
            return rnd.nextBool() ? left : right;
          } else {
            return directions[rnd.nextInt(directions.length)];
          }
        }

        var attempts = 0;
        (int nx, int ny)? nextCell;
        while (attempts < maxTurnRetries && nextCell == null) {
          dir = pickDirection(dir);
          final nx = x + dir.$1;
          final ny = y + dir.$2;
          attempts++;
          if (nx < 0 ||
              nx >= params.width ||
              ny < 0 ||
              ny >= params.height) {
            continue;
          }
          if (grid[ny][nx] != _landSentinel) continue;
          if (terrainGrid[ny][nx] == TerrainType.mountain) continue;
          nextCell = (nx, ny);
        }
        if (nextCell == null) {
          // This range is blocked; stop it.
          break;
        }
        (x, y) = nextCell;
        terrainGrid[y][x] = TerrainType.mountain;
        placedThisRange++;
        remainingMountain--;
      }
    }

    // If we significantly undershot the target due to blocking or early
    // termination of ranges, top up mountain tiles by growing existing ridges
    // along their edges. This keeps the overall pattern ridge-like while
    // nudging the global count closer to the configured fraction.
    var currentMountain = 0;
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (terrainGrid[y][x] == TerrainType.mountain) currentMountain++;
      }
    }
    if (currentMountain >= targetMountain) {
      return;
    }

    // Prefer to grow from existing mountain fronts into adjacent land.
    final frontier = <(int x, int y)>{};
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (terrainGrid[y][x] != TerrainType.mountain) continue;
        for (final (dx, dy) in directions) {
          final nx = x + dx;
          final ny = y + dy;
          if (nx < 0 ||
              nx >= params.width ||
              ny < 0 ||
              ny >= params.height) {
            continue;
          }
          if (grid[ny][nx] != _landSentinel) continue;
          if (terrainGrid[ny][nx] == TerrainType.mountain) continue;
          frontier.add((nx, ny));
        }
      }
    }

    final frontierList = frontier.toList();
    frontierList.shuffle(rnd);
    var idx = 0;
    while (currentMountain < targetMountain && idx < frontierList.length) {
      final (fx, fy) = frontierList[idx++];
      if (terrainGrid[fy][fx] == TerrainType.mountain) continue;
      terrainGrid[fy][fx] = TerrainType.mountain;
      currentMountain++;
    }

    // As a final fallback, if we still undershoot (e.g. very small maps with
    // fragmented land), convert random remaining land cells until we reach
    // the target. This should be rare and only adjusts a handful of tiles.
    if (currentMountain < targetMountain) {
      final remainingLand = <(int x, int y)>[];
      for (var y = 0; y < params.height; y++) {
        for (var x = 0; x < params.width; x++) {
          if (grid[y][x] == _landSentinel &&
              terrainGrid[y][x] != TerrainType.mountain) {
            remainingLand.add((x, y));
          }
        }
      }
      remainingLand.shuffle(rnd);
      var i = 0;
      while (currentMountain < targetMountain && i < remainingLand.length) {
        final (lx, ly) = remainingLand[i++];
        if (terrainGrid[ly][lx] == TerrainType.mountain) continue;
        terrainGrid[ly][lx] = TerrainType.mountain;
        currentMountain++;
      }
    }
  }

  /// Pass 6b: region-growing assignment for non-mountain terrains.
  void _assignNonMountainTerrainsRegionGrowing(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    String mapRegionId,
    TerrainDistribution distribution,
    Random rnd,
  ) {
    // Allowed non-mountain terrains for this region.
    final allowed = allowedTerrainsForRegion(mapRegionId)
        .where((t) => t != TerrainType.mountain)
        .toList();
    if (allowed.isEmpty) return;

    // Collect remaining land cells (not sea, not mountain).
    final remainingLand = <(int x, int y)>[];
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] != _landSentinel) continue;
        if (terrainGrid[y][x] == TerrainType.mountain) continue;
        remainingLand.add((x, y));
      }
    }
    if (remainingLand.isEmpty) return;

    // Split remaining land into connected components (continents) and run the
    // region-growing per component so each continent gets its own mix.
    final components = _connectedComponentsOfLand(remainingLand.toSet());
    if (components.isEmpty) return;

    const directions = <(int dx, int dy)>[
      (0, -1),
      (1, 0),
      (0, 1),
      (-1, 0),
    ];

    for (final component in components) {
      if (component.isEmpty) continue;
      final cells = component.toList();
      final totalRemaining = cells.length;

      // Per-component targets: same regional fractions, applied to this
      // continent's non-mountain land. Adjust so the sum matches exactly.
      final targets = <TerrainType, int>{};
      var sum = 0;
      for (final t in allowed) {
        final frac = distribution.nonMountainFractions[t] ?? 0.0;
        final n = (frac * totalRemaining).round();
        targets[t] = n;
        sum += n;
      }
      if (sum <= 0) {
        // Fallback: uniform among allowed for this component.
        final per = (totalRemaining / allowed.length).round();
        targets.clear();
        sum = 0;
        for (final t in allowed) {
          targets[t] = per;
          sum += per;
        }
      }
      final delta = totalRemaining - sum;
      if (delta != 0) {
        final last = allowed.last;
        targets[last] = (targets[last] ?? 0) + delta;
      }

      // --- Macro phase: coarse blobs ---------------------------------------

      final macroTargets = <TerrainType, int>{};
      final macroRemaining = <TerrainType, int>{};
      for (final t in allowed) {
        final target = targets[t] ?? 0;
        if (target <= 0) continue;
        final macro = max(
          1,
          (target * params.terrainMacroFraction).round().clamp(1, target),
        );
        macroTargets[t] = macro;
        macroRemaining[t] = macro;
      }

      // Seed placement within this component for macro phase.
      final macroQueues = <TerrainType, List<(int x, int y)>>{};
      final availableMacro = List<(int x, int y)>.from(cells);

      for (final t in allowed) {
        final macroTarget = macroTargets[t] ?? 0;
        if (macroTarget <= 0) continue;
        final seedCount = max(
          params.terrainSeedsMin,
          min(
            params.terrainSeedsMax,
            (params.terrainSeedsFactor * sqrt(macroTarget)).round(),
          ),
        );
        final q = <(int x, int y)>[];
        macroQueues[t] = q;

        var placedSeeds = 0;
        while (placedSeeds < seedCount &&
            macroRemaining[t]! > 0 &&
            availableMacro.isNotEmpty) {
          final idx = rnd.nextInt(availableMacro.length);
          final (sx, sy) = availableMacro.removeAt(idx);
          if (terrainGrid[sy][sx] != null) continue;
          terrainGrid[sy][sx] = t;
          q.add((sx, sy));
          macroRemaining[t] = macroRemaining[t]! - 1;
          placedSeeds++;
        }
      }

      bool hasActiveMacroTerrain() {
        for (final t in allowed) {
          final rem = macroRemaining[t] ?? 0;
          final q = macroQueues[t];
          if (rem > 0 && q != null && q.isNotEmpty) return true;
        }
        return false;
      }

      // Macro region-growing loop, restricted to this component's cells.
      final cellSet = component;
      while (hasActiveMacroTerrain()) {
        var totalRem = 0;
        for (final t in allowed) {
          totalRem += macroRemaining[t] ?? 0;
        }
        if (totalRem <= 0) break;
        var roll = rnd.nextInt(totalRem) + 1;
        TerrainType? chosen;
        for (final t in allowed) {
          final rem = macroRemaining[t] ?? 0;
          if (rem <= 0) continue;
          roll -= rem;
          if (roll <= 0) {
            chosen = t;
            break;
          }
        }
        if (chosen == null) break;
        final queue = macroQueues[chosen]!;
        if (queue.isEmpty) continue;

        final (cx, cy) = queue.removeLast();

        final dirs = List<(int dx, int dy)>.from(directions)..shuffle(rnd);
        for (final (dx, dy) in dirs) {
          final nx = cx + dx;
          final ny = cy + dy;
          if (nx < 0 ||
              nx >= params.width ||
              ny < 0 ||
              ny >= params.height) {
            continue;
          }
          if (!cellSet.contains((nx, ny))) continue;
          if (grid[ny][nx] != _landSentinel) continue;
          if (terrainGrid[ny][nx] != null) continue;
          terrainGrid[ny][nx] = chosen;
          macroRemaining[chosen] = macroRemaining[chosen]! - 1;
          queue.add((nx, ny));
          if (macroRemaining[chosen]! <= 0) break;
        }
      }

      // --- Micro phase: fill residual quotas with refinement ---------------

      final residualTargets = <TerrainType, int>{};
      for (final t in allowed) {
        final target = targets[t] ?? 0;
        if (target <= 0) continue;
        final macro = macroTargets[t] ?? 0;
        final usedMacro = macro - (macroRemaining[t] ?? 0);
        final residual = max(0, target - usedMacro);
        if (residual > 0) {
          residualTargets[t] = residual;
        }
      }

      if (residualTargets.isNotEmpty) {
        final microQueues = <TerrainType, List<(int x, int y)>>{};
        final microRemaining = <TerrainType, int>{};
        final availableMicro = <(int x, int y)>[];
        for (final (x, y) in cells) {
          if (terrainGrid[y][x] == null) {
            availableMicro.add((x, y));
          }
        }

        for (final t in allowed) {
          final residual = residualTargets[t] ?? 0;
          if (residual <= 0) continue;
          final seedCount = max(
            params.terrainSeedsMin,
            min(
              params.terrainSeedsMax,
              (params.terrainSeedsFactor * sqrt(residual)).round(),
            ),
          );
          final q = <(int x, int y)>[];
          microQueues[t] = q;
          microRemaining[t] = residual;

          var placedSeeds = 0;
          while (placedSeeds < seedCount &&
              microRemaining[t]! > 0 &&
              availableMicro.isNotEmpty) {
            final idx = rnd.nextInt(availableMicro.length);
            final (sx, sy) = availableMicro.removeAt(idx);
            if (terrainGrid[sy][sx] != null) continue;
            terrainGrid[sy][sx] = t;
            q.add((sx, sy));
            microRemaining[t] = microRemaining[t]! - 1;
            placedSeeds++;
          }
        }

        bool hasActiveMicroTerrain() {
          for (final t in allowed) {
            final rem = microRemaining[t] ?? 0;
            final q = microQueues[t];
            if (rem > 0 && q != null && q.isNotEmpty) return true;
          }
          return false;
        }

        while (hasActiveMicroTerrain()) {
          var totalRem = 0;
          for (final t in allowed) {
            totalRem += microRemaining[t] ?? 0;
          }
          if (totalRem <= 0) break;
          var roll = rnd.nextInt(totalRem) + 1;
          TerrainType? chosen;
          for (final t in allowed) {
            final rem = microRemaining[t] ?? 0;
            if (rem <= 0) continue;
            roll -= rem;
            if (roll <= 0) {
              chosen = t;
              break;
            }
          }
          if (chosen == null) break;
          final queue = microQueues[chosen]!;
          if (queue.isEmpty) continue;

          final (cx, cy) = queue.removeLast();

          final dirs = List<(int dx, int dy)>.from(directions)..shuffle(rnd);
          for (final (dx, dy) in dirs) {
            final nx = cx + dx;
            final ny = cy + dy;
            if (nx < 0 ||
                nx >= params.width ||
                ny < 0 ||
                ny >= params.height) {
              continue;
            }
            if (!cellSet.contains((nx, ny))) continue;
            if (grid[ny][nx] != _landSentinel) continue;
            if (terrainGrid[ny][nx] != null) continue;
            terrainGrid[ny][nx] = chosen;
            microRemaining[chosen] = microRemaining[chosen]! - 1;
            queue.add((nx, ny));
            if (microRemaining[chosen]! <= 0) break;
          }
        }
      }

      // Cleanup within this component: assign any remaining unassigned land
      // cells to neighboring terrains (majority vote), or random fallback.
      for (final (x, y) in cells) {
        if (terrainGrid[y][x] != null) continue;
        final counts = <TerrainType, int>{};
        for (final (dx, dy) in directions) {
          final nx = x + dx;
          final ny = y + dy;
          if (nx < 0 ||
              nx >= params.width ||
              ny < 0 ||
              ny >= params.height) {
            continue;
          }
          if (!cellSet.contains((nx, ny))) continue;
          final t = terrainGrid[ny][nx];
          if (t == null || t == TerrainType.mountain) continue;
          counts[t] = (counts[t] ?? 0) + 1;
        }
        if (counts.isNotEmpty) {
          TerrainType best = counts.keys.first;
          var bestCount = counts[best]!;
          for (final entry in counts.entries) {
            if (entry.value > bestCount) {
              best = entry.key;
              bestCount = entry.value;
            }
          }
          terrainGrid[y][x] = best;
        } else {
          terrainGrid[y][x] = allowed[rnd.nextInt(allowed.length)];
        }
      }

      // Optional pattern refinement phase: carve small pockets of alternate
      // non-mountain terrains inside large blobs, per continent.
      _refineTerrainPatternsInComponent(
        terrainGrid,
        grid,
        component,
        allowed,
        distribution,
        rnd,
      );
    }
  }

  /// Optional Pass 6b pattern refinement: for a given connected land component
  /// (continent), find large blobs of a single non-mountain terrain and carve
  /// small pockets of other non-mountain terrains into their interior while
  /// keeping blob shapes recognizable and overall fractions stable.
  void _refineTerrainPatternsInComponent(
    List<List<TerrainType?>> terrainGrid,
    List<List<String>> grid,
    Set<(int x, int y)> component,
    List<TerrainType> allowedNonMountain,
    TerrainDistribution distribution,
    Random rnd,
  ) {
    if (component.isEmpty || allowedNonMountain.isEmpty) return;

    // Restrict connected-components search to this continent's cells.
    Set<(int x, int y)> cellsOfTerrain(TerrainType t) {
      final out = <(int x, int y)>{};
      for (final (x, y) in component) {
        if (terrainGrid[y][x] == t) {
          out.add((x, y));
        }
      }
      return out;
    }

    // Helper to compute connected blobs within the component for a terrain.
    List<Set<(int x, int y)>> blobsForTerrain(TerrainType t) {
      final cells = cellsOfTerrain(t);
      if (cells.isEmpty) return const [];
      return _connectedComponentsOfLand(cells);
    }

    // Neighbour directions for interior tests and BFS (4-connected).
    const directions = <(int dx, int dy)>[
      (0, -1),
      (1, 0),
      (0, 1),
      (-1, 0),
    ];

    for (final terrain in allowedNonMountain) {
      final blobs = blobsForTerrain(terrain);
      if (blobs.isEmpty) continue;

      for (final blob in blobs) {
        final size = blob.length;
        if (size < params.patternMinBlobSize) continue;

        // Budget: how many tiles in this blob we may convert away from [terrain].
        final maxChangesForBlob =
            (params.patternMaxFractionPerBlob * size).floor().clamp(0, size);
        if (maxChangesForBlob <= 0) continue;

        // Identify interior cells: all 4-neighbors are also in this blob.
        final interior = <(int x, int y)>[];
        for (final (x, y) in blob) {
          var isInterior = true;
          for (final (dx, dy) in directions) {
            final nx = x + dx;
            final ny = y + dy;
            if (nx < 0 ||
                nx >= params.width ||
                ny < 0 ||
                ny >= params.height ||
                !blob.contains((nx, ny))) {
              isInterior = false;
              break;
            }
          }
          if (isInterior) {
            interior.add((x, y));
          }
        }
        if (interior.isEmpty) continue;

        // Determine how many seeds to use in this blob.
        final seedCount = max(
          1,
          min(
            params.patternMaxSeedsPerBlob,
            (params.patternSeedFactor * sqrt(size)).round(),
          ),
        ).clamp(1, maxChangesForBlob);

        final interiorShuffled = List<(int x, int y)>.from(interior)..shuffle(rnd);
        final seeds = <(int x, int y, TerrainType target)>[];
        var interiorIndex = 0;

        for (var i = 0; i < seedCount && interiorIndex < interiorShuffled.length; i++) {
          final (sx, sy) = interiorShuffled[interiorIndex++];
          // Choose a target terrain different from the blob terrain, optionally
          // preferring underrepresented terrains according to distribution.
          final options = allowedNonMountain.where((t) => t != terrain).toList();
          if (options.isEmpty) break;

          // Weight by desired fraction heuristic (simplified).
          final weights = <double>[];
          for (final t in options) {
            final desired = distribution.nonMountainFractions[t] ?? 0.0;
            weights.add(max(0.0001, desired));
          }
          final total = weights.fold<double>(0, (a, b) => a + b);
          var roll = rnd.nextDouble() * total;
          TerrainType chosen = options.first;
          for (var idx = 0; idx < options.length; idx++) {
            roll -= weights[idx];
            if (roll <= 0) {
              chosen = options[idx];
              break;
            }
          }
          seeds.add((sx, sy, chosen));
        }

        if (seeds.isEmpty) continue;

        var remainingBlobBudget = maxChangesForBlob;

        for (final (sx, sy, target) in seeds) {
          if (remainingBlobBudget <= 0) break;

          var changesForSeed = 0;
          final queue = <(int x, int y, int dist)>[(sx, sy, 0)];
          final visited = <(int, int)>{(sx, sy)};

          while (queue.isNotEmpty &&
              changesForSeed < params.patternMaxChangesPerSeed &&
              remainingBlobBudget > 0) {
            final (cx, cy, dist) = queue.removeAt(0);
            if (dist > params.patternMaxRadius) continue;

            if (grid[cy][cx] == _landSentinel &&
                blob.contains((cx, cy)) &&
                terrainGrid[cy][cx] == terrain) {
              terrainGrid[cy][cx] = target;
              changesForSeed++;
              remainingBlobBudget--;
            }

            if (dist == params.patternMaxRadius) continue;

            for (final (dx, dy) in directions) {
              final nx = cx + dx;
              final ny = cy + dy;
              if (nx < 0 ||
                  nx >= params.width ||
                  ny < 0 ||
                  ny >= params.height) {
                continue;
              }
              final key = (nx, ny);
              if (!blob.contains(key) || visited.contains(key)) continue;
              visited.add(key);
              queue.add((nx, ny, dist + 1));
            }
          }
        }
      }
    }
  }

  /// One continent seed per continent; then a cluster of land-shape seeds per continent (K from province count). No province seeds yet.
  (List<(int x, int y)>, List<(int x, int y)>, List<int>) _placeLandSeeds(Map<String, int> provinceToContinent, Random rnd) {
    if (provinceToContinent.isEmpty) return (<(int x, int y)>[], <(int x, int y)>[], <int>[]);
    final numContinents = provinceToContinent.values.toSet().length;
    if (numContinents < 1) return (<(int x, int y)>[], <(int x, int y)>[], <int>[]);
    final provincesByContinent = <int, List<String>>{};
    for (final e in provinceToContinent.entries) {
      provincesByContinent.putIfAbsent(e.value, () => []).add(e.key);
    }
    for (final list in provincesByContinent.values) {
      list.sort();
    }
    const minSeedsPerContinent = 5;
    final continentSeeds = <(int x, int y)>[];
    final landSeeds = <(int x, int y)>[];
    final continentBySeedIndex = <int>[];

    for (var c = 0; c < numContinents; c++) {
      final yLo = (params.height * c / numContinents).floor();
      final yHi = c + 1 == numContinents
          ? params.height
          : (params.height * (c + 1) / numContinents).floor();
      final bandHeight = (yHi - yLo).clamp(1, params.height);
      final bandWidth = params.width;

      // One continent seed per continent (random in band)
      final cx = rnd.nextInt(params.width);
      final cy = yLo + rnd.nextInt(bandHeight);
      continentSeeds.add((cx, cy));

      // K = max(minSeeds, provinces in this continent)
      final provincesInContinent = provincesByContinent[c]!.length;
      final K = (minSeedsPerContinent > provincesInContinent)
          ? minSeedsPerContinent
          : provincesInContinent;

      // Sigma for Gaussian: fraction of band size so cluster stays roughly in band
      final sigma = (bandWidth + bandHeight) / 8.0;
      final diskR = (min(bandWidth, bandHeight) / 2.0 * 0.8).ceil();
      final annulusInner = diskR ~/ 2;
      final annulusOuter = diskR;

      for (var k = 0; k < K; k++) {
        int dx;
        int dy;
        switch (params.clusterShape) {
          case LandSeedClusterShape.gaussian:
            final gx = _nextGaussian(rnd) * sigma;
            final gy = _nextGaussian(rnd) * sigma;
            dx = gx.round();
            dy = gy.round();
            break;
          case LandSeedClusterShape.uniformDisk:
            final angle = rnd.nextDouble() * 2 * pi;
            final r = sqrt(rnd.nextDouble()) * diskR;
            dx = (cos(angle) * r).round();
            dy = (sin(angle) * r).round();
            break;
          case LandSeedClusterShape.uniformAnnulus:
            final angle = rnd.nextDouble() * 2 * pi;
            final r = annulusInner + rnd.nextDouble() * (annulusOuter - annulusInner);
            dx = (cos(angle) * r).round();
            dy = (sin(angle) * r).round();
            break;
        }
        final x = (cx + dx).clamp(0, params.width - 1);
        final y = (cy + dy).clamp(yLo, yHi - 1);
        landSeeds.add((x, y));
        continentBySeedIndex.add(c);
      }
    }
    return (continentSeeds, landSeeds, continentBySeedIndex);
  }

  /// Organic land growing: interleaved seed placement + small Voronoi + coastline growth.
  /// Returns (continentSeeds, landSeeds, continentBySeedIndex, grid).
  (List<(int x, int y)>, List<(int x, int y)>, List<int>, List<List<String>>) _placeLandSeedsOrganic(
    List<List<String>> grid,
    Map<String, int> provinceToContinent,
    String seaZoneId,
    Random rnd,
  ) {
    if (provinceToContinent.isEmpty) return (<(int x, int y)>[], <(int x, int y)>[], <int>[], grid);
    final numContinents = provinceToContinent.values.toSet().length;
    if (numContinents < 1) return (<(int x, int y)>[], <(int x, int y)>[], <int>[], grid);

    final provincesByContinent = <int, List<String>>{};
    for (final e in provinceToContinent.entries) {
      provincesByContinent.putIfAbsent(e.value, () => []).add(e.key);
    }
    for (final list in provincesByContinent.values) {
      list.sort();
    }

    const minSeedsPerContinent = 5;
    final seedsPerContinent = <int>[];
    for (var c = 0; c < numContinents; c++) {
      final pc = provincesByContinent[c]!.length;
      seedsPerContinent.add(minSeedsPerContinent > pc ? minSeedsPerContinent : pc);
    }
    final totalSeeds = seedsPerContinent.reduce((a, b) => a + b);
    final totalRounds = (totalSeeds / numContinents).ceil().clamp(1, 999);

    final landBudgetTotal = ((1 - params.seaFraction) * params.width * params.height).round();
    if (landBudgetTotal <= 0) return (<(int x, int y)>[], <(int x, int y)>[], <int>[], grid);

    // Step 0: Place continent seeds
    final continentSeeds = <(int x, int y)>[];
    for (var c = 0; c < numContinents; c++) {
      final yLo = (params.height * c / numContinents).floor();
      final yHi = c + 1 == numContinents
          ? params.height
          : (params.height * (c + 1) / numContinents).floor();
      final bandHeight = (yHi - yLo).clamp(1, params.height);
      final cx = rnd.nextInt(params.width);
      final cy = yLo + rnd.nextInt(bandHeight);
      continentSeeds.add((cx, cy));
    }

    final landSeeds = <(int x, int y)>[];
    final continentBySeedIndex = <int>[];
    var g = grid.map((row) => row.toList()).toList();
    final continentGrid = List.generate(
      params.height,
      (_) => List.filled(params.width, -1),
    );

    const closeRadius = 5;
    const awayPenalty = 0.7;

    // Per-round land budget: reserve totalSeeds for seed positions, rest for Voronoi
    final voronoiBudgetTotal = (landBudgetTotal - totalSeeds).clamp(0, landBudgetTotal);
    final totalProvinces = provinceToContinent.length;

    final seedCountsPerContinent = List<int>.filled(numContinents, 0);
    var voronoiRemaining = voronoiBudgetTotal;

    for (var round = 0; round < totalRounds; round++) {
      final roundBudget = (round + 1 == totalRounds)
          ? voronoiRemaining
          : (voronoiBudgetTotal / totalRounds).round();
      final budgetPerContinent = <int>[];
      for (var c = 0; c < numContinents; c++) {
        budgetPerContinent.add((roundBudget * provincesByContinent[c]!.length / totalProvinces).round());
      }
      var roundUsed = 0;
      for (var c = 0; c < numContinents; c++) {
        roundUsed += budgetPerContinent[c];
      }
      if (roundUsed != roundBudget && numContinents > 0) {
        budgetPerContinent[0] += roundBudget - roundUsed;
      }
      voronoiRemaining -= roundBudget;
      // Step 1: Place one land seed per continent (if needed)
      for (var c = 0; c < numContinents; c++) {
        if (seedCountsPerContinent[c] >= seedsPerContinent[c]) continue;
        final (sx, sy) = _placeOneOrganicSeed(
          g,
          continentGrid,
          continentSeeds[c],
          landSeeds,
          continentBySeedIndex,
          c,
          closeRadius,
          awayPenalty,
          numContinents,
          seaZoneId,
          rnd,
        );
        if (sx >= 0 && sy >= 0) {
          landSeeds.add((sx, sy));
          continentBySeedIndex.add(c);
          seedCountsPerContinent[c]++;
          g[sy][sx] = _landSentinel;
          continentGrid[sy][sx] = c;
        }
      }

      // Step 2: Small Voronoi with no-join (use round's budgetPerContinent)
      final voronoiResult = _assignLandByLandSeedsWithNoJoin(
        g,
        continentGrid,
        landSeeds,
        continentBySeedIndex,
        seaZoneId,
        budgetPerContinent,
      );
      g = voronoiResult.$1;
      for (var y = 0; y < params.height; y++) {
        for (var x = 0; x < params.width; x++) {
          continentGrid[y][x] = voronoiResult.$2[y][x];
        }
      }
    }

    // Step 3: Coastline growth if budget remains
    var usedTotal = 0;
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (g[y][x] == _landSentinel) usedTotal++;
      }
    }
    if (usedTotal < landBudgetTotal) {
      final remaining = landBudgetTotal - usedTotal;
      final (g2, _) = _growCoastlines(g, continentGrid, remaining, provinceToContinent, seaZoneId, rnd);
      g = g2;
    }

    return (continentSeeds, landSeeds, continentBySeedIndex, g);
  }

  /// Place one land seed near existing land of continent c, preferably away from others.
  (int, int) _placeOneOrganicSeed(
    List<List<String>> grid,
    List<List<int>> continentGrid,
    (int x, int y) continentSeed,
    List<(int x, int y)> existingLandSeeds,
    List<int> continentBySeedIndex,
    int c,
    int closeRadius,
    double awayPenalty,
    int numContinents,
    String seaZoneId,
    Random rnd,
  ) {
    final candidates = <(int x, int y)>[];
    final ownLandOrSeed = <(int x, int y)>[continentSeed];
    for (var i = 0; i < existingLandSeeds.length; i++) {
      if (continentBySeedIndex[i] == c) {
        ownLandOrSeed.add(existingLandSeeds[i]);
      }
    }
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] != seaZoneId) continue;
        var minDistToOwn = closeRadius + 1;
        for (final (ox, oy) in ownLandOrSeed) {
          final d = (x - ox).abs() + (y - oy).abs();
          if (d < minDistToOwn) minDistToOwn = d;
        }
        if (minDistToOwn > closeRadius) continue;
        candidates.add((x, y));
      }
    }
    if (candidates.isEmpty) {
      final (cx, cy) = continentSeed;
      const jitter = 2;
      final jx = (cx + rnd.nextInt(jitter * 2 + 1) - jitter).clamp(0, params.width - 1);
      final jy = (cy + rnd.nextInt(jitter * 2 + 1) - jitter).clamp(0, params.height - 1);
      return (jx, jy);
    }
    var bestScore = -1e100;
    final bestCandidates = <(int x, int y)>[];
    for (final (x, y) in candidates) {
      var minDistToOwn = params.width + params.height;
      for (final (ox, oy) in ownLandOrSeed) {
        final d = (x - ox).abs() + (y - oy).abs();
        if (d < minDistToOwn) minDistToOwn = d;
      }
      var minDistToOther = params.width + params.height;
      for (var ny = 0; ny < params.height; ny++) {
        for (var nx = 0; nx < params.width; nx++) {
          if (continentGrid[ny][nx] >= 0 && continentGrid[ny][nx] != c) {
            final d = (x - nx).abs() + (y - ny).abs();
            if (d < minDistToOther) minDistToOther = d;
          }
        }
      }
      final score = -minDistToOwn + awayPenalty * minDistToOther;
      if (score > bestScore) {
        bestScore = score;
        bestCandidates.clear();
        bestCandidates.add((x, y));
      } else if ((score - bestScore).abs() < 0.01) {
        bestCandidates.add((x, y));
      }
    }
    if (bestCandidates.isEmpty) return (-1, -1);
    return bestCandidates[rnd.nextInt(bestCandidates.length)];
  }

  /// Offsets (dx, dy) where |dx|+|dy| in [1, maxDist], for no-join buffer.
  List<(int, int)> _bufferOffsets(int maxDist) {
    if (maxDist <= 0) return [];
    final out = <(int, int)>[];
    for (var dy = -maxDist; dy <= maxDist; dy++) {
      for (var dx = -maxDist; dx <= maxDist; dx++) {
        if (dx == 0 && dy == 0) continue;
        if (dx.abs() + dy.abs() <= maxDist) out.add((dx, dy));
      }
    }
    return out;
  }

  /// Voronoi with no-join: do not assign cell to c if any cell within buffer is land of another continent.
  (List<List<String>>, List<List<int>>) _assignLandByLandSeedsWithNoJoin(
    List<List<String>> grid,
    List<List<int>> continentGrid,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
    String seaZoneId,
    List<int> budgetPerContinent,
  ) {
    if (landSeeds.isEmpty) return (grid, continentGrid);
    final numContinents = budgetPerContinent.length;

    final seedStartByContinent = List<int>.filled(numContinents, 0);
    final seedEndByContinent = List<int>.filled(numContinents, 0);
    for (var c = 0; c < numContinents; c++) {
      var start = landSeeds.length;
      var end = 0;
      for (var i = 0; i < landSeeds.length; i++) {
        if (continentBySeedIndex[i] == c) {
          if (i < start) start = i;
          end = i + 1;
        }
      }
      seedStartByContinent[c] = start;
      seedEndByContinent[c] = end;
    }

    final entries = <(double effectiveD2, int x, int y, int continent)>[];
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        var bestD2 = 1e100;
        var bestC = 0;
        for (var c = 0; c < numContinents; c++) {
          final start = seedStartByContinent[c];
          final end = seedEndByContinent[c];
          var d2 = 0x7fffffff;
          for (var i = start; i < end; i++) {
            final (sx, sy) = landSeeds[i];
            final dd = (x - sx) * (x - sx) + (y - sy) * (y - sy);
            if (dd < d2) d2 = dd;
          }
          final noise = params.voronoiNoiseScale > 0
              ? _deterministicNoise(params.seed, x, y) * params.voronoiNoiseScale
              : 0.0;
          final effective = d2.toDouble() + noise;
          if (effective < bestD2) {
            bestD2 = effective;
            bestC = c;
          }
        }
        entries.add((bestD2, x, y, bestC));
      }
    }
    entries.sort((a, b) => a.$1.compareTo(b.$1));

    final next = grid.map((row) => row.toList()).toList();
    final nextContinent = continentGrid.map((row) => row.toList()).toList();
    final used = List<int>.filled(numContinents, 0);
    final buffer = params.continentBufferTiles == 0 ? 1 : params.continentBufferTiles;
    final offsets = _bufferOffsets(buffer);
    for (final (_, x, y, c) in entries) {
      if (next[y][x] == _landSentinel) continue;
      if (used[c] >= budgetPerContinent[c]) continue;
      var wouldJoin = false;
      for (final (dx, dy) in offsets) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx >= 0 && nx < params.width && ny >= 0 && ny < params.height) {
          final nc = nextContinent[ny][nx];
          if (nc >= 0 && nc != c) {
            wouldJoin = true;
            break;
          }
        }
      }
      if (wouldJoin) continue;
      next[y][x] = _landSentinel;
      nextContinent[y][x] = c;
      used[c]++;
    }
    return (next, nextContinent);
  }

  /// Grow coastlines with a thickness-first heuristic; do not bring land within
  /// buffer of another continent. Preference is given to coastal sea cells that
  /// already have a high density of same-continent land in a local neighborhood
  /// (bays and coves) so they are filled before long, thin tendrils into open
  /// ocean.
  (List<List<String>>, List<List<int>>) _growCoastlines(
    List<List<String>> grid,
    List<List<int>> continentGrid,
    int remaining,
    Map<String, int> provinceToContinent,
    String seaZoneId,
    Random rnd,
  ) {
    if (provinceToContinent.isEmpty) return (grid, continentGrid);
    final numContinents = provinceToContinent.values.toSet().length;
    final provincesByContinent = <int, List<String>>{};
    for (final e in provinceToContinent.entries) {
      provincesByContinent.putIfAbsent(e.value, () => []).add(e.key);
    }
    final totalProvinces = provinceToContinent.length;

    var g = grid.map((row) => row.toList()).toList();
    var cg = continentGrid.map((row) => row.toList()).toList();
    final coastalByContinent = <int, List<(int x, int y)>>{};
    for (var c = 0; c < numContinents; c++) coastalByContinent[c] = [];

    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (g[y][x] != _landSentinel) continue;
        final c = cg[y][x];
        if (c < 0) continue;
        for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
          final nx = x + dx;
          final ny = y + dy;
          if (nx >= 0 && nx < params.width && ny >= 0 && ny < params.height &&
              g[ny][nx] == seaZoneId) {
            coastalByContinent[c]!.add((nx, ny));
            break;
          }
        }
      }
    }

    final budgetPerContinent = List<int>.filled(numContinents, 0);
    var allocated = 0;
    for (var c = 0; c < numContinents; c++) {
      budgetPerContinent[c] = (remaining * provincesByContinent[c]!.length / totalProvinces).round();
      allocated += budgetPerContinent[c];
    }
    if (allocated < remaining && numContinents > 0) budgetPerContinent[0] += remaining - allocated;

    // Radius for local land-neighbour scoring when picking coastal cells.
    const scoreRadius = 3;
    final buffer = params.continentBufferTiles == 0 ? 1 : params.continentBufferTiles;
    final bufferOffsets = _bufferOffsets(buffer);

    // Local helper: score a coastal sea cell for continent [continentIndex].
    // Higher scores correspond to tiles that are already surrounded by that
    // continent's land in a radius-limited neighborhood (bays / coves).
    int scoreCoastalCell(int sx, int sy, int continentIndex) {
      var score = 0;
      for (var dy = -scoreRadius; dy <= scoreRadius; dy++) {
        for (var dx = -scoreRadius; dx <= scoreRadius; dx++) {
          final nx = sx + dx;
          final ny = sy + dy;
          if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
            continue;
          }
          if (dx == 0 && dy == 0) continue;
          if (g[ny][nx] != _landSentinel) continue;
          final nc = cg[ny][nx];
          if (nc == continentIndex) {
            score += 1;
          } else if (nc >= 0 && nc != continentIndex) {
            // Strongly discourage squeezing between other continents.
            score -= 10;
          }
        }
      }
      return score;
    }

    var added = 0;
    const maxAttempts = 10000;
    var attempts = 0;
    while (added < remaining && attempts < maxAttempts) {
      attempts++;
      var anyProgress = false;

      for (var c = 0; c < numContinents; c++) {
        if (budgetPerContinent[c] <= 0) continue;
        final coastal = coastalByContinent[c]!;
        if (coastal.isEmpty) continue;

        var bestScore = -0x7fffffff;
        final bestCandidates = <(int x, int y)>[];

        for (final (sx, sy) in coastal) {
          if (g[sy][sx] != seaZoneId) continue;

          // Respect continent buffer: never bring this continent's land too
          // close to another continent.
          var wouldJoin = false;
          for (final (dx, dy) in bufferOffsets) {
            final nx = sx + dx;
            final ny = sy + dy;
            if (nx >= 0 && nx < params.width && ny >= 0 && ny < params.height) {
              final nc = cg[ny][nx];
              if (nc >= 0 && nc != c) {
                wouldJoin = true;
                break;
              }
            }
          }
          if (wouldJoin) continue;

          final score = scoreCoastalCell(sx, sy, c);
          if (score > bestScore) {
            bestScore = score;
            bestCandidates
              ..clear()
              ..add((sx, sy));
          } else if (score == bestScore) {
            bestCandidates.add((sx, sy));
          }
        }

        if (bestCandidates.isEmpty) {
          continue;
        }

        final (sx, sy) = bestCandidates[rnd.nextInt(bestCandidates.length)];
        if (g[sy][sx] != seaZoneId) {
          continue;
        }

        g[sy][sx] = _landSentinel;
        cg[sy][sx] = c;
        budgetPerContinent[c]--;
        added++;
        anyProgress = true;

        coastalByContinent[c]!.removeWhere((p) => p.$1 == sx && p.$2 == sy);
        for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
          final nx = sx + dx;
          final ny = sy + dy;
          if (nx >= 0 &&
              nx < params.width &&
              ny >= 0 &&
              ny < params.height &&
              g[ny][nx] == seaZoneId &&
              !coastalByContinent[c]!.contains((nx, ny))) {
            coastalByContinent[c]!.add((nx, ny));
          }
        }
      }

      if (!anyProgress) {
        // No continent could grow further under current constraints; stop.
        break;
      }
    }
    return (g, cg);
  }

  /// Box-Muller transform: returns a standard normal sample.
  double _nextGaussian(Random rnd) {
    var u1 = rnd.nextDouble();
    var u2 = rnd.nextDouble();
    while (u1 <= 0) u1 = rnd.nextDouble();
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }

  /// Per-continent land budget; assign to _landSentinel by smallest effective distance (with optional Voronoi noise). Each cell at most one continent.
  List<List<String>> _assignLandByLandSeeds(
    List<List<String>> grid,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
    Map<String, int> provinceToContinent,
    String seaZoneId,
  ) {
    if (landSeeds.isEmpty) return grid;
    final landBudgetTotal = ((1 - params.seaFraction) * params.width * params.height).round();
    if (landBudgetTotal <= 0) return grid;

    if (provinceToContinent.isEmpty) return grid;
    final numContinents = provinceToContinent.values.toSet().length;
    final provincesByContinent = <int, List<String>>{};
    for (final e in provinceToContinent.entries) {
      provincesByContinent.putIfAbsent(e.value, () => []).add(e.key);
    }
    final totalProvinces = provinceToContinent.length;
    if (totalProvinces == 0) return grid;

    // Per-continent budget (proportional to province count)
    final budget = List<int>.filled(numContinents, 0);
    var allocated = 0;
    for (var c = 0; c < numContinents; c++) {
      final pc = provincesByContinent[c]!.length;
      budget[c] = (landBudgetTotal * pc / totalProvinces).round();
      allocated += budget[c];
    }
    if (allocated > landBudgetTotal) {
      budget[0] -= (allocated - landBudgetTotal);
    } else if (allocated < landBudgetTotal && numContinents > 0) {
      budget[0] += (landBudgetTotal - allocated);
    }

    // Seeds per continent (index ranges: [start, end) for each c)
    final seedStartByContinent = List<int>.filled(numContinents, 0);
    final seedEndByContinent = List<int>.filled(numContinents, 0);
    for (var c = 0; c < numContinents; c++) {
      var start = landSeeds.length;
      var end = 0;
      for (var i = 0; i < landSeeds.length; i++) {
        if (continentBySeedIndex[i] == c) {
          if (i < start) start = i;
          end = i + 1;
        }
      }
      seedStartByContinent[c] = start;
      seedEndByContinent[c] = end;
    }

    final entries = <(double effectiveD2, int x, int y, int continent)>[];
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        var bestD2 = 1e100;
        var bestC = 0;
        for (var c = 0; c < numContinents; c++) {
          final start = seedStartByContinent[c];
          final end = seedEndByContinent[c];
          var d2 = 0x7fffffff;
          for (var i = start; i < end; i++) {
            final (sx, sy) = landSeeds[i];
            final dd = (x - sx) * (x - sy) * (x - sx) + (y - sy) * (y - sy);
            if (dd < d2) d2 = dd;
          }
          final noise = params.voronoiNoiseScale > 0
              ? _deterministicNoise(params.seed, x, y) * params.voronoiNoiseScale
              : 0.0;
          final effective = d2.toDouble() + noise;
          if (effective < bestD2) {
            bestD2 = effective;
            bestC = c;
          }
        }
        entries.add((bestD2, x, y, bestC));
      }
    }
    entries.sort((a, b) => a.$1.compareTo(b.$1));

    final next = grid.map((row) => row.toList()).toList();
    final used = List<int>.filled(numContinents, 0);
    for (final (_, x, y, c) in entries) {
      if (used[c] < budget[c]) {
        next[y][x] = _landSentinel;
        used[c]++;
      }
    }
    return next;
  }

  /// Deterministic noise in [-1, 1] for Voronoi boundary irregularity.
  double _deterministicNoise(int seed, int x, int y) {
    var h = (seed * 31 + x) * 31 + y;
    h = (h ^ (h >> 16)) * 0x85ebca6b;
    h = (h ^ (h >> 13)) * 0xc2b2ae35;
    h = h ^ (h >> 16);
    return (h & 0x7FFFFFFF) / 0x7FFFFFFF * 2 - 1;
  }

  /// Ocean = sea cells reachable from grid boundary. Lake = sea not in ocean.
  Set<(int x, int y)> _oceanCells(List<List<String>> grid, String seaZoneId) {
    final ocean = <(int x, int y)>{};
    final queue = <(int x, int y)>[];
    for (var x = 0; x < params.width; x++) {
      if (grid[0][x] == seaZoneId) {
        ocean.add((x, 0));
        queue.add((x, 0));
      }
      if (params.height > 1 && grid[params.height - 1][x] == seaZoneId) {
        ocean.add((x, params.height - 1));
        queue.add((x, params.height - 1));
      }
    }
    for (var y = 0; y < params.height; y++) {
      if (grid[y][0] == seaZoneId && !ocean.contains((0, y))) {
        ocean.add((0, y));
        queue.add((0, y));
      }
      if (params.width > 1 && grid[y][params.width - 1] == seaZoneId &&
          !ocean.contains((params.width - 1, y))) {
        ocean.add((params.width - 1, y));
        queue.add((params.width - 1, y));
      }
    }
    while (queue.isNotEmpty) {
      final (x, y) = queue.removeLast();
      for (final (nx, ny) in [
        (x - 1, y),
        (x + 1, y),
        (x, y - 1),
        (x, y + 1),
      ]) {
        if (nx >= 0 && nx < params.width && ny >= 0 && ny < params.height &&
            grid[ny][nx] == seaZoneId && !ocean.contains((nx, ny))) {
          ocean.add((nx, ny));
          queue.add((nx, ny));
        }
      }
    }
    return ocean;
  }

  /// Continent index for a land cell from nearest land seed. Returns 0 when seeds empty.
  int _continentForLandCell(
    int x,
    int y,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
  ) {
    if (landSeeds.isEmpty) return 0;
    var bestSeedIndex = 0;
    var bestD2 = 0x7fffffff;
    for (var i = 0; i < landSeeds.length; i++) {
      final (sx, sy) = landSeeds[i];
      final d2 = (x - sx) * (x - sx) + (y - sy) * (y - sy);
      if (d2 < bestD2) {
        bestD2 = d2;
        bestSeedIndex = i;
      }
    }
    return continentBySeedIndex[bestSeedIndex];
  }

  /// Fill lakes: convert lake (sea not in ocean) to land; skip lakes that border 2+ continents (straits).
  List<List<String>> _fillLakes(
    List<List<String>> grid,
    String seaZoneId,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
  ) {
    final ocean = _oceanCells(grid, seaZoneId);
    final next = grid.map((row) => row.toList()).toList();
    final lakeCells = <(int x, int y)>[];
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] != seaZoneId) continue;
        if (ocean.contains((x, y))) continue;
        lakeCells.add((x, y));
      }
    }
    final lakeComponents = _connectedComponentsOfLand(lakeCells.toSet());
    var lakesFilled = 0;
    final coastalLandCandidates = <(int x, int y)>{};
    for (final component in lakeComponents) {
      final borderingLand = <(int x, int y)>{};
      for (final (x, y) in component) {
        for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
          final nx = x + dx;
          final ny = y + dy;
          if (nx >= 0 && nx < params.width && ny >= 0 && ny < params.height &&
              grid[ny][nx] != seaZoneId) {
            borderingLand.add((nx, ny));
          }
        }
      }
      final continentsBordering = <int>{};
      for (final (lx, ly) in borderingLand) {
        continentsBordering.add(_continentForLandCell(lx, ly, landSeeds, continentBySeedIndex));
      }
      if (continentsBordering.length >= 2) continue;
      for (final (x, y) in component) {
        next[y][x] = _landSentinel;
        lakesFilled++;
        for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
          final nx = x + dx;
          final ny = y + dy;
          if (nx >= 0 && nx < params.width && ny >= 0 && ny < params.height &&
              next[ny][nx] == seaZoneId &&
              _oceanNeighbourCount(next, nx, ny, seaZoneId, ocean) >= 1) {
            coastalLandCandidates.add((nx, ny));
          }
        }
      }
    }
    final sorted = coastalLandCandidates.toList()
      ..sort((a, b) {
        final na = _oceanNeighbourCount(next, a.$1, a.$2, seaZoneId, ocean);
        final nb = _oceanNeighbourCount(next, b.$1, b.$2, seaZoneId, ocean);
        return nb.compareTo(na);
      });
    for (final (fx, fy) in sorted.take(lakesFilled)) {
      next[fy][fx] = seaZoneId;
    }
    return next;
  }

  int _oceanNeighbourCount(List<List<String>> grid, int x, int y, String seaZoneId,
      Set<(int x, int y)> ocean) {
    var n = 0;
    for (final (dx, dy) in [(0, -1), (0, 1), (-1, 0), (1, 0)]) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx >= 0 && nx < params.width && ny >= 0 && ny < params.height &&
          grid[ny][nx] == seaZoneId && ocean.contains((nx, ny))) n++;
    }
    return n;
  }

  /// Collapse narrow ocean moats: convert ocean cells that are effectively
  /// thin moats around a single continent into land, then preserve overall sea
  /// fraction by converting an equal number of coastal land tiles back to sea.
  ///
  /// A moat candidate is an ocean cell whose 4-neighbourhood contains land
  /// belonging to the **same** continent in at least two directions and no
  /// land from any other continent.
  List<List<String>> _fillMoats(
    List<List<String>> grid,
    String seaZoneId,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
    Random rnd,
  ) {
    final ocean = _oceanCells(grid, seaZoneId);
    if (ocean.isEmpty) return grid;

    final next = grid.map((row) => row.toList()).toList();
    final moatCells = <(int x, int y)>[];

    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (next[y][x] != seaZoneId) continue;
        if (!ocean.contains((x, y))) continue;

        // Examine 4-neighbourhood for bordering land.
        final neighbouringContinents = <int>{};
        final sameContinentDirectionCounts = <int, int>{};

    for (final (dx, dy) in const <(int, int)>[
          (0, -1), // N
          (1, 0), // E
          (0, 1), // S
          (-1, 0), // W
        ]) {
          final nx = x + dx;
          final ny = y + dy;
          if (nx < 0 || nx >= params.width || ny < 0 || ny >= params.height) {
            continue;
          }
          if (next[ny][nx] == seaZoneId) continue;
          final continent = _continentForLandCell(nx, ny, landSeeds, continentBySeedIndex);
          neighbouringContinents.add(continent);
          sameContinentDirectionCounts[continent] =
              (sameContinentDirectionCounts[continent] ?? 0) + 1;
        }

        if (neighbouringContinents.isEmpty) continue;
        if (neighbouringContinents.length > 1) continue; // multi-continent strait, keep as sea

        final c = neighbouringContinents.single;
        final dirCount = sameContinentDirectionCounts[c] ?? 0;
        if (dirCount < 2) continue; // not strongly enclosed by that continent

        moatCells.add((x, y));
      }
    }

    if (moatCells.isEmpty) return grid;

    for (final (x, y) in moatCells) {
      next[y][x] = _landSentinel;
    }

    // Preserve overall sea fraction by converting an equal number of coastal
    // land tiles back to sea, using the existing helper.
    _preserveSeaFraction(
      next,
      null,
      null,
      seaZoneId,
      ocean,
      moatCells.length,
    );

    return next;
  }

  /// Land cells grouped by continent (nearest land seed → continent via continentBySeedIndex).
  Map<int, List<(int x, int y)>> _landCellsByContinent(
    List<List<String>> grid,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
  ) {
    final numContinents = continentBySeedIndex.isEmpty
        ? 0
        : continentBySeedIndex.reduce((a, b) => a > b ? a : b) + 1;
    final byContinent = <int, List<(int x, int y)>>{
      for (var c = 0; c < numContinents; c++) c: [],
    };
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] != _landSentinel) continue;
        var bestSeedIndex = 0;
        var bestD2 = 0x7fffffff;
        for (var i = 0; i < landSeeds.length; i++) {
          final (sx, sy) = landSeeds[i];
          final d2 = (x - sx) * (x - sx) + (y - sy) * (y - sy);
          if (d2 < bestD2) {
            bestD2 = d2;
            bestSeedIndex = i;
          }
        }
        final c = continentBySeedIndex[bestSeedIndex];
        byContinent[c]!.add((x, y));
      }
    }
    return byContinent;
  }

  /// Place one province seed per province on that continent's land cells; min spacing.
  Map<String, (int x, int y)> _placeProvinceSeedsOnLand(
    List<List<String>> grid,
    Map<String, int> provinceToContinent,
    List<(int x, int y)> landSeeds,
    List<int> continentBySeedIndex,
    String seaZoneId,
    Random rnd,
  ) {
    if (provinceToContinent.isEmpty) return {};
    final numContinents = provinceToContinent.values.toSet().length;
    final byContinent = _landCellsByContinent(grid, landSeeds, continentBySeedIndex);
    final seeds = <String, (int x, int y)>{};
    const minDist = 3;
    for (var c = 0; c < numContinents; c++) {
      final cells = byContinent[c] ?? [];
      if (cells.isEmpty) continue;
      final provinceIds = provinceToContinent.entries
          .where((e) => e.value == c)
          .map((e) => e.key)
          .toList()
        ..sort();
      final used = <(int x, int y)>{};
      for (final provinceId in provinceIds) {
        final shuffled = List<(int x, int y)>.from(cells)..shuffle(rnd);
        for (final (x, y) in shuffled) {
          if (used.any((p) => (p.$1 - x).abs() < minDist && (p.$2 - y).abs() < minDist)) continue;
          seeds[provinceId] = (x, y);
          used.add((x, y));
          break;
        }
        if (!seeds.containsKey(provinceId) && cells.isNotEmpty) {
          final (x, y) = cells[rnd.nextInt(cells.length)];
          seeds[provinceId] = (x, y);
          used.add((x, y));
        }
      }
    }
    return seeds;
  }

  /// Replace each _landSentinel cell with nearest province seed id. Uses generic Voronoi.
  List<List<String>> _assignProvincesFromSeeds(
    List<List<String>> grid,
    Map<String, (int x, int y)> provinceSeeds,
    String seaZoneId,
  ) {
    if (provinceSeeds.isEmpty) return grid;
    final landCells = <(int x, int y)>[];
    for (var y = 0; y < params.height; y++) {
      for (var x = 0; x < params.width; x++) {
        if (grid[y][x] == _landSentinel) landCells.add((x, y));
      }
    }
    final assignment = assignCellsToNearestSeed(
      landCells,
      provinceSeeds,
      noiseScale: 0,
      noiseSeed: params.seed,
    );
    final next = grid.map((row) => row.toList()).toList();
    for (final entry in assignment.entries) {
      final (x, y) = entry.key;
      next[y][x] = entry.value;
    }
    return next;
  }

  /// Border noise: swap only at land/sea boundary (sentinel vs seaZoneId).
  List<List<String>> _borderNoise(List<List<String>> grid, String seaZoneId, Random rnd) {
    final next = grid.map((row) => row.toList()).toList();
    for (var y = 1; y < params.height - 1; y++) {
      for (var x = 1; x < params.width - 1; x++) {
        if (rnd.nextDouble() >= params.borderNoise) continue;
        final id = grid[y][x];
        final neighbors = [
          (x - 1, y),
          (x + 1, y),
          (x, y - 1),
          (x, y + 1),
        ];
        for (final (nx, ny) in neighbors) {
          final nid = grid[ny][nx];
          final atBoundary = (id == _landSentinel && nid == seaZoneId) ||
              (id == seaZoneId && nid == _landSentinel);
          if (atBoundary) {
            next[ny][nx] = id;
            next[y][x] = nid;
            break;
          }
        }
      }
    }
    return next;
  }
}

