import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

/// Shared scaffolding for the tile-map *generator* test suite
/// (`tile_map_generator_*_test.dart`, `tile_map_gen_*_test.dart`,
/// `tile_map_grid_graph_test.dart`, …).
///
/// The generator suite constructs [TileMapParams] dozens of times with the same
/// width/height/seed/seaFraction shape repeated inline. [genParams] is the
/// single source of truth for those params: every named argument keeps the
/// exact production [TileMapParams] default, so a bare `genParams()` and any
/// `genParams(width: …, height: …, seed: …)` call are byte-for-byte equivalent
/// to the inline `TileMapParams(...)` they replace (behavior-preserving). The
/// common `seaFraction: 0.6` argument matches both the [TileMapParams] default
/// and the value almost every generator test used, so call sites can drop it.
///
/// Only the parameters generator tests actually vary are exposed; the remaining
/// pass-tuning knobs (mountain/terrain-seed/pattern factors, `clusterShape`,
/// `voronoiNoiseScale`, `multiRegionResourceCapFraction`) keep their
/// [TileMapParams] defaults. A test that needs one of those rare knobs can still
/// construct [TileMapParams] directly. Refs #3746, #3846.
TileMapParams genParams({
  int width = 100,
  int height = 100,
  int seed = 42,
  double seaFraction = 0.6,
  double borderNoise = 0.0,
  int maxEnforceIterations = 10,
  int continentBufferTiles = 2,
  bool skipFillLakes = false,
  bool joinContinents = true,
  bool seedBeforeAssignment = false,
  double maxSeaZoneFraction = 0.05,
  double terrainVariation = 0.5,
  double jitterHomogeneityThreshold = 0.85,
  double jitterMaxFraction = 0.1,
  double jitterProbability = 0.25,
  int jitterMinProvinceSize = 10,
  int jitterNeighborSupportThreshold = 2,
}) {
  return TileMapParams(
    width: width,
    height: height,
    seed: seed,
    seaFraction: seaFraction,
    borderNoise: borderNoise,
    maxEnforceIterations: maxEnforceIterations,
    continentBufferTiles: continentBufferTiles,
    skipFillLakes: skipFillLakes,
    joinContinents: joinContinents,
    seedBeforeAssignment: seedBeforeAssignment,
    maxSeaZoneFraction: maxSeaZoneFraction,
    terrainVariation: terrainVariation,
    jitterHomogeneityThreshold: jitterHomogeneityThreshold,
    jitterMaxFraction: jitterMaxFraction,
    jitterProbability: jitterProbability,
    jitterMinProvinceSize: jitterMinProvinceSize,
    jitterNeighborSupportThreshold: jitterNeighborSupportThreshold,
  );
}

/// Stable fingerprint of province, terrain, and resource grids for regression
/// guards after map-package refactors (Refs #2489, #3846).
String tileMapGenerationDigest(TileMapResult result) {
  final buffer = StringBuffer();
  for (var y = 0; y < result.height; y++) {
    for (var x = 0; x < result.width; x++) {
      buffer
        ..write(result.cell(x, y))
        ..write('|')
        ..write(result.terrainAt(x, y)?.name ?? '')
        ..write('|')
        ..write(result.resourceAt(x, y)?.name ?? '')
        ..write(';');
    }
  }
  return buffer.toString().hashCode.toRadixString(16);
}

List<(String, TopologyNodeType, String)> topologyNodeKeys(
  Iterable<TopologyNode> nodes,
) =>
    nodes.map((n) => (n.id, n.type, n.regionId)).toList();

List<String> topologyEdgeKeys(Iterable<TopologyEdge> edges) => edges
    .map((e) => '${e.id1}|${e.id2}')
    .toList()
  ..sort();

/// Runs [TileMapGenerator.generate] with shared defaults for generator tests.
(TileMapResult result, MapTopology topology) runTileMapGeneration({
  TileMapParams? params,
  int width = 100,
  int height = 100,
  int seed = 42,
  int numProvinces = 8,
  int numContinents = 2,
  String regionId = 'oldWorld',
  ResourceRules? resourceRules,
}) {
  final resolvedParams = params ??
      genParams(
        width: width,
        height: height,
        seed: seed,
      );
  return TileMapGenerator(params: resolvedParams).generate(
    numProvinces: numProvinces,
    numContinents: numContinents,
    regionId: regionId,
    resourceRules: resourceRules ?? ResourceRules.defaultRules,
  );
}
