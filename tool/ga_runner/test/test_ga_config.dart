import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:ga_runner/config/ga_config.dart';
import 'package:ga_runner/setup/ga_setup_profile.dart';

/// Minimal [GaConfig] for unit/integration tests.
///
/// [sevenGpGamesPerProfile] defaults to `0` so legacy tests exercise only the
/// 2-player stage unless they opt in. Refs #3488.
GaConfig testGaConfig({
  int populationSize = 2,
  int gamesPerProfile = 1,
  int maxGenerations = 1,
  int gamePlayerCount = 2,
  int maxTurns = 3,
  required String seedProfilesDir,
  required GameSetupConfig gameSetupConfig,
  String outputDir = 'output/',
  int seed = 11,
  int sevenGpGamesPerProfile = 0,
  StageFitnessWeights stageFitnessWeights = const StageFitnessWeights(
    twoPlayer: 0.5,
    sevenGp: 0.5,
  ),
}) {
  final sevenGpProfile = buildGaSetupProfile(
    selectedGreatPowerIds: allGreatPowerIds,
    minorNationCount: gameSetupConfig.minorNationCount,
    tribeCount: gameSetupConfig.tribeCount,
    continentCount: gameSetupConfig.continentCount,
    minProvincesPerMinor: gameSetupConfig.minProvincesPerMinor,
    numProvincesNewWorld: gameSetupConfig.numProvincesNewWorld,
    seed: gameSetupConfig.seed,
  );
  return GaConfig(
    populationSize: populationSize,
    gamesPerProfile: gamesPerProfile,
    maxGenerations: maxGenerations,
    gamePlayerCount: gamePlayerCount,
    maxTurns: maxTurns,
    seedProfilesDir: seedProfilesDir,
    gameSetupConfig: gameSetupConfig,
    sevenGpGameSetupConfig: sevenGpProfile.setupConfig,
    outputDir: outputDir,
    seed: seed,
    sevenGpGamesPerProfile: sevenGpGamesPerProfile,
    stageFitnessWeights: stageFitnessWeights,
    sevenGpOpponentSelection: 'top_fitness',
    sevenGpFallbackDefaultAiSeats: 3,
    sevenGpFallbackRandomizedAiSeats: 3,
    sevenGpUseBlessedProfiles: false,
  );
}

GameSetupConfig testTwoPlayerSetup({
  int seed = 99,
}) =>
    GameSetupConfig(
      selectedGreatPowerIds: const ['england', 'france'],
      minorNationCount: 3,
      tribeCount: 3,
      numProvincesOldWorld: 23,
      numProvincesNewWorld: 12,
      seed: seed,
    );
