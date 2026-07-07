part of 'game_service.dart';

(TileMapResult, MapTopology) _gameServiceGenerateTileMapOldWorld(
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
    onLog: _mapGenPassLog.d,
  );
}

(TileMapResult, MapTopology) _gameServiceGenerateTileMapNewWorld(
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
    onLog: _mapGenPassLog.d,
  );
}

List<WarpLink> _gameServiceGenerateWarpLinks({
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

void _gameServicePersistNewGame(
  GameService service, {
  required String gameId,
  required GameSetupResult result,
}) {
  service._mapCache[gameId] = _GameMapCache(
    combinedTopology: result.combinedTopology,
    tileMapByRegion: result.tileMapByRegion,
    topologyByRegion: result.topologyByRegion,
    warpLinks: result.warpLinks,
  );
  service._adapter.saveMapData(
    service._box,
    gameId,
    tileMapByRegion: result.tileMapByRegion,
    topologyByRegion: result.topologyByRegion,
    combinedTopology: result.combinedTopology,
    warpLinks: result.warpLinks,
  );
  service.saveGame(result.game);
  service._mirrorAutoSave(result.game);
  service.eventBus?.emit(NewGameCreatedEvent(gameId: result.game.id));
}
