import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart'
    show
        applyAdvancedStartBootstrap,
        assignHiddenAgendasForGame,
        GameSetupResult,
        resolveEffectiveSetupSeed;
import 'package:colonizethis_world/colonizethis_world.dart';

import 'game_service.dart';
import 'game_service_new_game_setup_maps.dart';
import 'game_service_new_game_setup_pipeline.dart';

Game gameServiceCreateNewGame(
  GameService service, {
  String? id,
  GameSetupConfig? config,
}) {
  final gameId = id ?? 'game_${DateTime.now().millisecondsSinceEpoch}';
  final cfg = config ?? GameSetupConfig.defaultConfig;
  final effectiveSeed = resolveEffectiveSetupSeed(cfg.seed);
  late final GameSetupResult setupResult;
  if (cfg.isLockedFullInitProfile) {
    setupResult = gameServiceLockedFullInitMapsWarpSetupWithRetry(
      cfg: cfg,
      gameId: gameId,
      effectiveSeed: effectiveSeed,
    );
  } else {
    setupResult = gameServiceFreeformMapsWarpSetupWithRetry(
      cfg: cfg,
      gameId: gameId,
      effectiveSeed: effectiveSeed,
    );
  }
  final bootstrappedSetup = gameServiceSetupResultAfterAdvancedStartBootstrap(
    setupResult,
    cfg,
  );
  final result = gameServiceSetupResultWithFinalizedGame(
    bootstrappedSetup,
    effectiveSeed,
    aiProfileByGpId: cfg.aiProfileByGpId,
  );
  gameServicePersistNewGame(service, gameId: gameId, result: result);
  return result.game;
}

Future<Game> gameServiceCreateNewGameAsync(
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
    setupResult = gameServiceLockedFullInitMapsWarpSetupWithRetry(
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
    setupResult = gameServiceFreeformMapsWarpSetupWithRetry(
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
  final bootstrappedSetup = gameServiceSetupResultAfterAdvancedStartBootstrap(
    setupResult,
    cfg,
  );
  final result = gameServiceSetupResultWithFinalizedGame(
    bootstrappedSetup,
    effectiveSeed,
    aiProfileByGpId: cfg.aiProfileByGpId,
  );

  reportPhase(4);
  await yieldUi();
  gameServicePersistNewGame(service, gameId: gameId, result: result);
  ctAppPerfInstant('newGameAsync.complete');
  log.i('newGameAsync complete gameId=$gameId');
  return result.game;
}

GameSetupResult gameServiceSetupResultAfterAdvancedStartBootstrap(
  GameSetupResult setup,
  GameSetupConfig cfg,
) {
  final bootstrappedGame = applyAdvancedStartBootstrap(
    game: setup.game,
    config: cfg,
    topologyOldWorld: setup.topologyByRegion[kRegionOldWorld],
    topologyNewWorld: setup.topologyByRegion[kRegionNewWorld],
    warpLinks: setup.warpLinks ?? const [],
    tileMapByRegion: setup.tileMapByRegion,
    topologyByRegion: setup.topologyByRegion,
  );
  return GameSetupResult(
    game: bootstrappedGame,
    tileMapByRegion: setup.tileMapByRegion,
    topologyByRegion: setup.topologyByRegion,
    combinedTopology: setup.combinedTopology,
    warpLinks: setup.warpLinks,
  );
}

GameSetupResult gameServiceSetupResultWithFinalizedGame(
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
