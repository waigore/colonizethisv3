import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';

import 'init_game_orchestrator_test_support.dart';

GameSetupResult minorTribeStartingDevelopmentIntegrationSetup(int seed) {
  final config = configWithOverrides(
    selectedGreatPowerIds: const ['england', 'france'],
    continentCount: 2,
    minorNationCount: 4,
    tribeCount: 3,
    numProvincesOldWorld: 16,
    numProvincesNewWorld: 10,
    minProvincesPerMinor: 1,
    seed: seed,
  );
  final owParams = TileMapParams(
    width: 44,
    height: 34,
    seed: seed,
    seaFraction: 0.55,
  );
  final (owMap, owTopo) = defaultTileMapRegionGenerator(
    params: owParams,
    numProvinces: config.numProvincesOldWorld,
    numContinents: config.continentCount,
    regionId: kRegionOldWorld,
    resourceRules: ResourceRules.defaultRules,
  );
  final nwParams = TileMapParams(
    width: 30,
    height: 26,
    seed: seed + 1,
    seaFraction: 0.55,
  );
  final (nwMap, nwTopo) = defaultTileMapRegionGenerator(
    params: nwParams,
    numProvinces: config.numProvincesNewWorld,
    numContinents: 1,
    regionId: kRegionNewWorld,
    resourceRules: ResourceRules.defaultRules,
  );
  return createGameFromGeneratedMaps(
    config: config,
    tileMapOldWorld: owMap,
    topologyOldWorld: owTopo,
    tileMapNewWorld: nwMap,
    topologyNewWorld: nwTopo,
    gameId: 'minor-tribe-dev-$seed',
    namingSeed: seed,
  );
}
