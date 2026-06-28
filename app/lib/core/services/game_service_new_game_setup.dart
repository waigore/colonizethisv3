part of 'game_service.dart';

Game _gameServiceCreateNewGame(
  GameService service, {
  String? id,
  GameSetupConfig? config,
}) {
  final gameId = id ?? 'game_${DateTime.now().millisecondsSinceEpoch}';
  final cfg = config ?? GameSetupConfig.defaultConfig;
  final effectiveSeed = resolveEffectiveSetupSeed(cfg.seed);
  late final GameSetupResult setupResult;
  if (cfg.isLockedFullInitProfile) {
    setupResult = _gameServiceLockedFullInitMapsWarpSetupWithRetry(
      cfg: cfg,
      gameId: gameId,
      effectiveSeed: effectiveSeed,
    );
  } else {
    setupResult = _gameServiceFreeformMapsWarpSetupWithRetry(
      cfg: cfg,
      gameId: gameId,
      effectiveSeed: effectiveSeed,
    );
  }
  final result = _gameServiceSetupResultWithFinalizedGame(
    setupResult,
    effectiveSeed,
    aiProfileByGpId: cfg.aiProfileByGpId,
  );
  _gameServicePersistNewGame(service, gameId: gameId, result: result);
  return result.game;
}

Future<Game> _gameServiceCreateNewGameAsync(
  GameService service, {
  String? id,
  GameSetupConfig? config,
  void Function(int stepIndex, int totalSteps)? onProgress,
}) async {
  final gameId = id ?? 'game_${DateTime.now().millisecondsSinceEpoch}';
  final cfg = config ?? GameSetupConfig.defaultConfig;
  final effectiveSeed = resolveEffectiveSetupSeed(cfg.seed);
  const total = GameService.newGameSetupProgressStepCount;
  final log = packageLogger();
  Future<void> yieldUi() => Future<void>.delayed(Duration.zero);

  await yieldUi();

  void reportPhase(int stepIndex) {
    ctAppPerfInstant('newGameAsync.phase_$stepIndex');
    log.i('newGameAsync phase step=$stepIndex total=$total gameId=$gameId');
    onProgress?.call(stepIndex, total);
  }

  ctAppPerfInstant('newGameAsync.begin');
  log.i('newGameAsync begin gameId=$gameId');

  reportPhase(0);
  await yieldUi();
  late final GameSetupResult setupResult;
  if (cfg.isLockedFullInitProfile) {
    setupResult = _gameServiceLockedFullInitMapsWarpSetupWithRetry(
      cfg: cfg,
      gameId: gameId,
      effectiveSeed: effectiveSeed,
    );
    reportPhase(1);
    await yieldUi();
    reportPhase(2);
    await yieldUi();
    reportPhase(3);
    await yieldUi();
  } else {
    setupResult = _gameServiceFreeformMapsWarpSetupWithRetry(
      cfg: cfg,
      gameId: gameId,
      effectiveSeed: effectiveSeed,
    );
    reportPhase(1);
    await yieldUi();
    reportPhase(2);
    await yieldUi();
    reportPhase(3);
    await yieldUi();
  }
  final result = _gameServiceSetupResultWithFinalizedGame(
    setupResult,
    effectiveSeed,
    aiProfileByGpId: cfg.aiProfileByGpId,
  );

  reportPhase(4);
  await yieldUi();
  _gameServicePersistNewGame(service, gameId: gameId, result: result);
  ctAppPerfInstant('newGameAsync.complete');
  log.i('newGameAsync complete gameId=$gameId');
  return result.game;
}

GameSetupResult _gameServiceSetupResultWithFinalizedGame(
  GameSetupResult setup,
  int effectiveSeed, {
  Map<String, String?> aiProfileByGpId = const {},
}) {
  var game = setup.game.copyWith(
    globalGameSeed: effectiveSeed,
    aiSeedByGpId: {
      for (final p in setup.game.players) p.id: effectiveSeed + p.id.hashCode,
    },
    aiProfileByGpId: Map<String, String?>.from(aiProfileByGpId),
  );
  game = assignHiddenAgendasForGame(game);
  return GameSetupResult(
    game: game,
    tileMapByRegion: setup.tileMapByRegion,
    topologyByRegion: setup.topologyByRegion,
    combinedTopology: setup.combinedTopology,
    warpLinks: setup.warpLinks,
  );
}

const int _kLockedFullInitPipelineMaxAttempts = 64;
const int _kFreeformPipelineMaxAttempts = 64;

GameSetupResult _gameServiceFreeformMapsWarpSetupWithRetry({
  required GameSetupConfig cfg,
  required String gameId,
  required int effectiveSeed,
}) {
  final log = packageLogger();
  for (var attempt = 0; attempt < _kFreeformPipelineMaxAttempts; attempt++) {
    final mapSeed = effectiveSeed + attempt * 100003;
    try {
      final ow = _gameServiceGenerateTileMapOldWorld(cfg, mapSeed);
      final nw = _gameServiceGenerateTileMapNewWorld(cfg, mapSeed);
      final warpLinks = _gameServiceGenerateWarpLinks(
        effectiveSeed: mapSeed,
        tileMapOW: ow.$1,
        topoOW: ow.$2,
        tileMapNW: nw.$1,
        topoNW: nw.$2,
      );
      return createGameFromGeneratedMaps(
        config: cfg,
        tileMapOldWorld: ow.$1,
        topologyOldWorld: ow.$2,
        tileMapNewWorld: nw.$1,
        topologyNewWorld: nw.$2,
        gameId: gameId,
        namingSeed: effectiveSeed,
        warpLinks: warpLinks,
      );
    } on SetupTopologyDataException catch (e, st) {
      final retriableTopology =
          e.code == 'assigner_exhausted' ||
          e.code == 'faction_component_bin_pack_failed' ||
          e.code == 'assignment_remainder_not_connected';
      if (retriableTopology && attempt < _kFreeformPipelineMaxAttempts - 1) {
        log.w(
          'app: freeform init topology retry at attempt=$attempt '
          '(code=${e.code}; mapSeed=$mapSeed): $e',
        );
        continue;
      }
      log.e('app: freeform init setup failed: $e', error: e, stackTrace: st);
      rethrow;
    }
  }
  throw SetupTopologyDataException(
    code: 'assigner_exhausted',
    details:
        'Freeform init pipeline exhausted after '
        '$_kFreeformPipelineMaxAttempts attempts',
  );
}

GameSetupResult _gameServiceLockedFullInitMapsWarpSetupWithRetry({
  required GameSetupConfig cfg,
  required String gameId,
  required int effectiveSeed,
}) {
  final log = packageLogger();
  for (
    var attempt = 0;
    attempt < _kLockedFullInitPipelineMaxAttempts;
    attempt++
  ) {
    final mapSeed = effectiveSeed + attempt * 100003;
    try {
      final r = generateLockedFullInitTileMapPair(
        config: cfg,
        effectiveSeed: mapSeed,
        onLog: _mapGenPassLog.d,
      );
      final warpLinks = _gameServiceGenerateWarpLinks(
        effectiveSeed: mapSeed,
        tileMapOW: r.tileOw,
        topoOW: r.topoOw,
        tileMapNW: r.tileNw,
        topoNW: r.topoNw,
      );
      return createGameFromGeneratedMaps(
        config: cfg,
        tileMapOldWorld: r.tileOw,
        topologyOldWorld: r.topoOw,
        tileMapNewWorld: r.tileNw,
        topologyNewWorld: r.topoNw,
        gameId: gameId,
        namingSeed: effectiveSeed,
        warpLinks: warpLinks,
      );
    } on MapPartitionGatesExhaustedException catch (e) {
      if (attempt < _kLockedFullInitPipelineMaxAttempts - 1) {
        log.w(
          'app: locked full-init partition gates exhausted; retrying '
          '(attempt=$attempt mapSeed=$mapSeed): $e',
        );
        continue;
      }
      throw SetupTopologyDataException(
        code: MapPartitionGatesExhaustedException.codeValue,
        details: e.toString(),
      );
    } on SetupTopologyDataException catch (e, st) {
      final retriableTopology =
          e.code == 'assigner_exhausted' ||
          e.code == 'faction_component_bin_pack_failed' ||
          e.code == 'assignment_remainder_not_connected';
      if (retriableTopology &&
          attempt < _kLockedFullInitPipelineMaxAttempts - 1) {
        log.w(
          'app: locked full-init setup topology retry '
          '(attempt=$attempt mapSeed=$mapSeed code=${e.code}): $e',
        );
        continue;
      }
      log.e(
        'app: locked full-init setup failed: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
  throw SetupTopologyDataException(
    code: 'assigner_exhausted',
    details:
        'Locked full-init pipeline exhausted after '
        '$_kLockedFullInitPipelineMaxAttempts attempts',
  );
}

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
