/// Sentinel value for "land not yet assigned to a province". Replaced in Pass 9.

part of 'tile_map_generator.dart';

const String _landSentinel = kTileMapLandSentinel;

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
  }) : assert(targetTilesPerProvince >= 1),
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
Map<String, int> buildProvinceToContinentMap(
  int numProvinces,
  int numContinents,
) {
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

/// Maps `p1`..`pN` to continent indices `0..C-1` using explicit per-continent province
/// counts (locked full-init OW `[13,13,17,17]`, NW `[6,6,9,9]` — GitHub #1834).
Map<String, int> buildProvinceToContinentMapFromCounts(
  List<int> provinceCountsPerContinent,
) {
  if (provinceCountsPerContinent.isEmpty) return {};
  final result = <String, int>{};
  var idx = 0;
  for (var c = 0; c < provinceCountsPerContinent.length; c++) {
    final n = provinceCountsPerContinent[c];
    for (var i = 0; i < n; i++) {
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
      _continentBfsEnqueueNeighbors(cur, p2p, continent, idx, queue);
    }
    idx++;
  }
  return continent;
}

void _continentBfsEnqueueNeighbors(
  String cur,
  Map<String, Set<String>> p2p,
  Map<String, int> continent,
  int idx,
  List<String> queue,
) {
  for (final n in p2p[cur]!) {
    if (continent.containsKey(n)) continue;
    continent[n] = idx;
    queue.add(n);
  }
}

// `TileMapParams` was moved out of this part file into the standalone library
// `tile_map_params.dart` (Refs #3588) so the extracted generation passes can
// reference it without `part`/`part of` coupling. It is imported and
// re-exported by `tile_map_generator.dart`.
