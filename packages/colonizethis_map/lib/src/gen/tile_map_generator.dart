// SPEC/program/tile-map-gen-algorithm.md, tile-map-gen-resources.md, tile-map-gen-config.md.

import 'package:colonizethis_data/colonizethis_data.dart';

import 'tile_map_generator_run.dart';
import 'tile_map_generator_services.dart';
import 'tile_map_params.dart';

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
    return TileMapGenerator._(
      params: params,
      services: createTileMapGeneratorServices(params),
    );
  }

  TileMapGenerator._({
    required super.params,
    required TileMapGeneratorServices services,
  }) : _services = services;

  final TileMapGeneratorServices _services;

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
    return runTileMapGenerate(
      params: params,
      services: _services,
      numProvinces: numProvinces,
      numContinents: numContinents,
      regionId: regionId,
      seaZoneId: seaZoneId,
      resourceRules: resourceRules,
      onLog: onLog,
      onLandSeedsPlaced: onLandSeedsPlaced,
      onContinentSeedsPlaced: onContinentSeedsPlaced,
      continentProvinceSizes: continentProvinceSizes,
    );
  }
}
