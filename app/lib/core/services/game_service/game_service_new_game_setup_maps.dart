import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart'
    show
        GameSetupResult,
        generateWarpZones,
        kDefaultSeaFraction;
import 'package:colonizethis_world/colonizethis_world.dart';

import 'game_service.dart';
import 'game_service_map_cache.dart';

(TileMapResult, MapTopology) gameServiceGenerateTileMapOldWorld(
  GameSetupConfig cfg,
  int effectiveSeed,
) {
  final mapGenParams = MapGenerationParams(
    numContinents: cfg.continentCount,
    seed: effectiveSeed,
    seaFraction: kDefaultSeaFraction,
  );
  final sizeOW = computeGridSizeFromParams(
    cfg.numProvincesOldWorld,
    mapGenParams,
  );
  final paramsOW = TileMapParams(
    width: sizeOW.width,
    height: sizeOW.height,
    seed: effectiveSeed,
    seaFraction: kDefaultSeaFraction,
    terrainVariation: cfg.terrainVariation,
  );
  return TileMapGenerator(params: paramsOW).generate(
    numProvinces: cfg.numProvincesOldWorld,
    numContinents: cfg.continentCount,
    regionId: kRegionOldWorld,
    resourceRules: ResourceRules.defaultRules,
    onLog: gameServiceMapGenPassLog.d,
  );
}

(TileMapResult, MapTopology) gameServiceGenerateTileMapNewWorld(
  GameSetupConfig cfg,
  int effectiveSeed,
) {
  final mapGenParams = MapGenerationParams(
    numContinents: cfg.continentCount,
    seed: effectiveSeed,
    seaFraction: kDefaultSeaFraction,
  );
  final sizeNW = computeGridSizeFromParams(
    cfg.numProvincesNewWorld,
    mapGenParams,
  );
  final paramsNW = TileMapParams(
    width: sizeNW.width,
    height: sizeNW.height,
    seed: effectiveSeed + 1,
    seaFraction: kDefaultSeaFraction,
    terrainVariation: cfg.terrainVariation,
  );
  return TileMapGenerator(params: paramsNW).generate(
    numProvinces: cfg.numProvincesNewWorld,
    numContinents: cfg.continentCount.clamp(1, cfg.numProvincesNewWorld),
    regionId: kRegionNewWorld,
    resourceRules: ResourceRules.defaultRules,
    onLog: gameServiceMapGenPassLog.d,
  );
}

List<WarpLink> gameServiceGenerateWarpLinks({
  required int effectiveSeed,
  required TileMapResult tileMapOW,
  required MapTopology topoOW,
  required TileMapResult tileMapNW,
  required MapTopology topoNW,
}) {
  return generateWarpZones(
    tileMapOldWorld: tileMapOW,
    topologyOldWorld: topoOW,
    tileMapNewWorld: tileMapNW,
    topologyNewWorld: topoNW,
    regionIdOld: kRegionOldWorld,
    regionIdNew: kRegionNewWorld,
    seed: effectiveSeed,
  );
}

void gameServicePersistNewGame(
  GameService service, {
  required String gameId,
  required GameSetupResult result,
}) {
  service.state.mapCache[gameId] = GameMapCache(
    combinedTopology: result.combinedTopology,
    tileMapByRegion: result.tileMapByRegion,
    topologyByRegion: result.topologyByRegion,
    warpLinks: result.warpLinks,
  );
  service.state.adapter.saveMapData(
    service.state.box,
    gameId,
    tileMapByRegion: result.tileMapByRegion,
    topologyByRegion: result.topologyByRegion,
    combinedTopology: result.combinedTopology,
    warpLinks: result.warpLinks,
  );
  service.saveGame(result.game);
  gameServiceMirrorAutoSave(service, result.game);
  service.eventBus?.emit(NewGameCreatedEvent(gameId: result.game.id));
}
