// Locked / freeform init pipeline phases. SPEC/program/init-game-tool.md,
// game-setup-pipeline.md (Refs #4086 Slice C).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

import 'game_setup.dart';
import 'gp_starting_grain.dart';
import 'init_game_orchestrator_types.dart';
import 'init_pipeline_retry.dart';
import 'setup_constants.dart';
import 'setup_exceptions.dart';
import 'setup_logging.dart';
import 'warp_zone_generator.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

({List<WarpLink> warpLinks, GameSetupResult setupResult})
runLockedFullInitPipeline({
  required GameSetupConfig config,
  required InitGameOptions options,
  required int effectiveSeed,
}) {
  setupLog.d(
    'init game generating OW+NW maps (locked partition + setup retries)',
  );
  return runInitPipelineWithRetries(
    effectiveSeed: effectiveSeed,
    modeLabel: 'locked full-init',
    onAttemptError: (error, stackTrace, attempt, isLastAttempt) {
      // A generated layout can leave a Great Power capital province with fewer
      // than four eligible grain-bootstrap tiles (see
      // SPEC/game/tile-map-and-generation.md § Great Power starting grain). Like
      // partition-gate exhaustion, treat this as an infeasible layout and
      // regenerate with a bumped map seed; the bootstrap's own fatal error still
      // propagates once attempts are exhausted.
      if (error is GreatPowerGrainBootstrapError) {
        if (!isLastAttempt) {
          setupLog.w(
            'logic: locked full-init grain bootstrap infeasible at '
            'attempt=$attempt; bumping mapSeed (details=$error)',
          );
          return InitPipelineErrorAction.retry;
        }
        return InitPipelineErrorAction.unhandled;
      }
      if (error is! MapPartitionGatesExhaustedException) {
        return InitPipelineErrorAction.unhandled;
      }
      if (!isLastAttempt) {
        setupLog.w(
          'logic: locked full-init partition gates exhausted at '
          'attempt=$attempt; bumping mapSeed (details=$error)',
        );
        return InitPipelineErrorAction.retry;
      }
      throw SetupTopologyDataException(
        code: MapPartitionGatesExhaustedException.codeValue,
        details: error.toString(),
      );
    },
    generateAndCreate: (mapSeed) {
      final locked = generateLockedFullInitTileMapPair(
        config: config,
        effectiveSeed: mapSeed,
        skipFillLakes: options.skipFillLakes,
        onLog: setupLog.d,
      );
      final warpLinks = generateWarpZones(
        tileMapOldWorld: locked.tileOw,
        topologyOldWorld: locked.topoOw,
        tileMapNewWorld: locked.tileNw,
        topologyNewWorld: locked.topoNw,
        regionIdOld: kRegionOldWorld,
        regionIdNew: kRegionNewWorld,
        seed: mapSeed,
      );
      final setupResult = createGameFromGeneratedMaps(
        config: config,
        tileMapOldWorld: locked.tileOw,
        topologyOldWorld: locked.topoOw,
        tileMapNewWorld: locked.tileNw,
        topologyNewWorld: locked.topoNw,
        gameId: 'game_${DateTime.now().millisecondsSinceEpoch}',
        namingSeed: effectiveSeed,
        warpLinks: warpLinks,
      );
      return (warpLinks: warpLinks, setupResult: setupResult);
    },
  );
}

({List<WarpLink> warpLinks, GameSetupResult setupResult})
runFreeformInitPipeline({
  required GameSetupConfig config,
  required InitGameOptions options,
  required int effectiveSeed,
  required TileMapRegionGenerator generateRegion,
}) {
  return runInitPipelineWithRetries(
    effectiveSeed: effectiveSeed,
    modeLabel: 'freeform init',
    onAttemptError: (error, stackTrace, attempt, isLastAttempt) {
      // Regenerate with a bumped seed when a layout cannot host the Great Power
      // grain bootstrap (see locked pipeline note); the fatal error still
      // propagates on the final attempt.
      if (error is GreatPowerGrainBootstrapError && !isLastAttempt) {
        setupLog.w(
          'logic: freeform init grain bootstrap infeasible at '
          'attempt=$attempt; bumping mapSeed (details=$error)',
        );
        return InitPipelineErrorAction.retry;
      }
      return InitPipelineErrorAction.unhandled;
    },
    generateAndCreate: (mapSeed) {
      final mapGenParams = MapGenerationParams(
        numContinents: config.continentCount,
        seed: mapSeed,
        seaFraction: kDefaultSeaFraction,
      );
      final sizeOW = computeGridSizeFromParams(
        config.numProvincesOldWorld,
        mapGenParams,
      );
      final paramsOW = TileMapParams(
        width: sizeOW.width,
        height: sizeOW.height,
        seed: mapSeed,
        seaFraction: kDefaultSeaFraction,
        skipFillLakes: options.skipFillLakes,
      );
      setupLog.d('init game generating OW map (freeform mapSeed=$mapSeed)');
      final ow = generateRegion(
        params: paramsOW,
        numProvinces: config.numProvincesOldWorld,
        numContinents: config.continentCount,
        regionId: kRegionOldWorld,
        resourceRules: ResourceRules.defaultRules,
      );

      setupLog.d('init game generating NW map');
      final sizeNW = computeGridSizeFromParams(
        config.numProvincesNewWorld,
        mapGenParams,
      );
      final paramsNW = TileMapParams(
        width: sizeNW.width,
        height: sizeNW.height,
        seed: mapSeed + 1,
        seaFraction: kDefaultSeaFraction,
        skipFillLakes: options.skipFillLakes,
      );
      final nw = generateRegion(
        params: paramsNW,
        numProvinces: config.numProvincesNewWorld,
        numContinents: config.continentCount.clamp(
          1,
          config.numProvincesNewWorld,
        ),
        regionId: kRegionNewWorld,
        resourceRules: ResourceRules.defaultRules,
      );
      final warpLinks = generateWarpZones(
        tileMapOldWorld: ow.$1,
        topologyOldWorld: ow.$2,
        tileMapNewWorld: nw.$1,
        topologyNewWorld: nw.$2,
        regionIdOld: kRegionOldWorld,
        regionIdNew: kRegionNewWorld,
        seed: mapSeed,
      );
      final setupResult = createGameFromGeneratedMaps(
        config: config,
        tileMapOldWorld: ow.$1,
        topologyOldWorld: ow.$2,
        tileMapNewWorld: nw.$1,
        topologyNewWorld: nw.$2,
        gameId: 'game_${DateTime.now().millisecondsSinceEpoch}',
        namingSeed: effectiveSeed,
        warpLinks: warpLinks,
      );
      return (warpLinks: warpLinks, setupResult: setupResult);
    },
  );
}
