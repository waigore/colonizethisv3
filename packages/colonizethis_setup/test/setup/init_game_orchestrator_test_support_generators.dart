import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

/// Wraps [defaultTileMapRegionGenerator] for tests, exposing the per-region
/// [TileMapParams] via [onParams] and allowing a [continentProvinceSizes]
/// override via [resolveContinentProvinceSizes]. Removes the copy-pasted full
/// generator signature from orchestrator tests (Refs #3712).
TileMapRegionGenerator wrapRegionGenerator({
  void Function(String regionId, TileMapParams params)? onParams,
  List<int>? Function({
    required String regionId,
    required int numProvinces,
    required int numContinents,
    required List<int>? continentProvinceSizes,
  })?
  resolveContinentProvinceSizes,
}) {
  return ({
    required TileMapParams params,
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
    onParams?.call(regionId, params);
    final sizes =
        resolveContinentProvinceSizes?.call(
          regionId: regionId,
          numProvinces: numProvinces,
          numContinents: numContinents,
          continentProvinceSizes: continentProvinceSizes,
        ) ??
        continentProvinceSizes;
    return defaultTileMapRegionGenerator(
      params: params,
      numProvinces: numProvinces,
      numContinents: numContinents,
      regionId: regionId,
      seaZoneId: seaZoneId,
      resourceRules: resourceRules,
      onLog: onLog,
      onLandSeedsPlaced: onLandSeedsPlaced,
      onContinentSeedsPlaced: onContinentSeedsPlaced,
      continentProvinceSizes: sizes,
    );
  };
}
