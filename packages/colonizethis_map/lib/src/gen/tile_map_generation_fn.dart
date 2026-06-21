import 'package:colonizethis_data/colonizethis_data.dart';

import 'tile_map_generator.dart';

/// Callable seam for per-region tile map generation (used by init game and tests).
/// SPEC/program/dependency-injection.md.
typedef TileMapRegionGenerator = (TileMapResult, MapTopology) Function({
  required TileMapParams params,
  required int numProvinces,
  required int numContinents,
  required String regionId,
  String seaZoneId,
  ResourceRules? resourceRules,
  void Function(String)? onLog,
  void Function(List<(int x, int y)> landSeeds, List<int> continentIndices)?
      onLandSeedsPlaced,
  void Function(List<(int x, int y)> continentSeeds)? onContinentSeedsPlaced,
  List<int>? continentProvinceSizes,
});

/// Default implementation delegating to [TileMapGenerator].
(TileMapResult, MapTopology) defaultTileMapRegionGenerator({
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
  return TileMapGenerator(params: params).generate(
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
