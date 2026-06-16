import 'package:colonizethis_data/colonizethis_data.dart';

import '../setup/ga_setup_profile.dart';

/// Weights for combining 2-player and 7-GP stage fitness. Refs #3488.
class StageFitnessWeights {
  const StageFitnessWeights({
    required this.twoPlayer,
    required this.sevenGp,
  });

  final double twoPlayer;
  final double sevenGp;

  static StageFitnessWeights fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      return const StageFitnessWeights(twoPlayer: 0.5, sevenGp: 0.5);
    }
    final w2p = (json['two_player'] as num?)?.toDouble() ?? 0.5;
    final w7 = (json['seven_gp'] as num?)?.toDouble() ?? 0.5;
    _validateWeight(w2p, 'stage_fitness_weights.two_player');
    _validateWeight(w7, 'stage_fitness_weights.seven_gp');
    return StageFitnessWeights(twoPlayer: w2p, sevenGp: w7);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'two_player': twoPlayer,
    'seven_gp': sevenGp,
  };
}

void _validateWeight(double value, String field) {
  if (!value.isFinite || value <= 0) {
    throw FormatException('$field must be a finite number > 0 (got $value)');
  }
}

/// Parsed `ga-config.json`. SPEC/program/ga-runner.md. Refs #3439.
class GaConfig {
  const GaConfig({
    required this.populationSize,
    required this.gamesPerProfile,
    required this.maxGenerations,
    required this.gamePlayerCount,
    required this.maxTurns,
    required this.seedProfilesDir,
    required this.gameSetupConfig,
    required this.sevenGpGameSetupConfig,
    required this.outputDir,
    required this.seed,
    required this.sevenGpGamesPerProfile,
    required this.stageFitnessWeights,
    required this.sevenGpOpponentSelection,
    required this.sevenGpFallbackDefaultAiSeats,
    required this.sevenGpFallbackRandomizedAiSeats,
    required this.sevenGpUseBlessedProfiles,
  });

  final int populationSize;
  final int gamesPerProfile;
  final int maxGenerations;
  final int gamePlayerCount;
  final int maxTurns;
  final String seedProfilesDir;
  final GameSetupConfig gameSetupConfig;
  final GameSetupConfig sevenGpGameSetupConfig;
  final String outputDir;
  final int seed;
  final int sevenGpGamesPerProfile;
  final StageFitnessWeights stageFitnessWeights;
  final String sevenGpOpponentSelection;
  final int sevenGpFallbackDefaultAiSeats;
  final int sevenGpFallbackRandomizedAiSeats;
  final bool sevenGpUseBlessedProfiles;

  /// Builds from decoded JSON. Throws [FormatException] on invalid input.
  factory GaConfig.fromJson(Map<String, dynamic> json) {
    final setupJson = json['game_setup_config'];
    if (setupJson is! Map<String, dynamic>) {
      throw const FormatException('game_setup_config must be a JSON object');
    }
    final parsed = _gameSetupFromJson(setupJson);
    // GA observer games require realistic minor/tribe presence (Refs #3447).
    validateGaFactionMinimums(
      minorNationCount: parsed.minorNationCount,
      tribeCount: parsed.tribeCount,
    );
    final profile = buildGaSetupProfile(
      selectedGreatPowerIds: parsed.selectedGreatPowerIds,
      minorNationCount: parsed.minorNationCount,
      tribeCount: parsed.tribeCount,
      continentCount: parsed.continentCount,
      minProvincesPerMinor: parsed.minProvincesPerMinor,
      numProvincesNewWorld: parsed.numProvincesNewWorld,
      seed: parsed.seed,
    );
    final setup = _mergeGaSetupExtras(profile.setupConfig, parsed);
    final sevenGpProfile = buildGaSetupProfile(
      selectedGreatPowerIds: allGreatPowerIds,
      minorNationCount: parsed.minorNationCount,
      tribeCount: parsed.tribeCount,
      continentCount: parsed.continentCount,
      minProvincesPerMinor: parsed.minProvincesPerMinor,
      numProvincesNewWorld: parsed.numProvincesNewWorld,
      seed: parsed.seed,
    );
    final sevenGpSetup = _mergeGaSetupExtras(
      sevenGpProfile.setupConfig,
      parsed,
    );
    if (sevenGpSetup.greatPowerCount != 7) {
      throw FormatException(
        'seven_gp setup requires 7 GPs (got ${sevenGpSetup.greatPowerCount})',
      );
    }
    final playerCount =
        (json['game_player_count'] as num?)?.toInt() ?? setup.greatPowerCount;
    if (playerCount != setup.greatPowerCount) {
      throw FormatException(
        'game_player_count ($playerCount) must match '
        'selectedGreatPowerIds.length (${setup.greatPowerCount})',
      );
    }
    if (playerCount != 2) {
      throw FormatException(
        'game_player_count must be 2 in v1 (got $playerCount)',
      );
    }
    final seedProfilesDir = json['seed_profiles_dir'];
    if (seedProfilesDir is! String || seedProfilesDir.isEmpty) {
      throw const FormatException('seed_profiles_dir must be a non-empty string');
    }
    final outputDir = json['output_dir'] as String? ?? 'output/';
    final seed = json['seed'];
    if (seed is! int) {
      throw const FormatException('seed must be an integer');
    }
    final sevenGpGamesPerProfile =
        (json['seven_gp_games_per_profile'] as num?)?.toInt() ?? 1;
    if (sevenGpGamesPerProfile < 0) {
      throw FormatException(
        'seven_gp_games_per_profile must be >= 0 (got $sevenGpGamesPerProfile)',
      );
    }
    final stageFitnessWeights = StageFitnessWeights.fromJson(
      json['stage_fitness_weights'],
    );
    final sevenGpOpponentSelection =
        json['seven_gp_opponent_selection'] as String? ?? 'top_fitness';
    if (sevenGpOpponentSelection != 'top_fitness') {
      throw FormatException(
        'seven_gp_opponent_selection must be top_fitness '
        '(got $sevenGpOpponentSelection)',
      );
    }
    final sevenGpFallbackDefaultAiSeats =
        (json['seven_gp_fallback_default_ai_seats'] as num?)?.toInt() ?? 3;
    final sevenGpFallbackRandomizedAiSeats =
        (json['seven_gp_fallback_randomized_ai_seats'] as num?)?.toInt() ?? 3;
    if (sevenGpFallbackDefaultAiSeats < 0 ||
        sevenGpFallbackRandomizedAiSeats < 0) {
      throw const FormatException(
        'seven_gp fallback seat counts must be non-negative',
      );
    }
    if (sevenGpFallbackDefaultAiSeats + sevenGpFallbackRandomizedAiSeats != 6) {
      throw FormatException(
        'seven_gp_fallback_default_ai_seats + '
        'seven_gp_fallback_randomized_ai_seats must equal 6 '
        '(got $sevenGpFallbackDefaultAiSeats + '
        '$sevenGpFallbackRandomizedAiSeats)',
      );
    }
    final sevenGpUseBlessedProfiles =
        json['seven_gp_use_blessed_profiles'] as bool? ?? false;
    return GaConfig(
      populationSize: (json['population_size'] as num?)?.toInt() ?? 20,
      gamesPerProfile: (json['games_per_profile'] as num?)?.toInt() ?? 5,
      maxGenerations: (json['max_generations'] as num?)?.toInt() ?? 100,
      gamePlayerCount: playerCount,
      maxTurns: (json['max_turns'] as num?)?.toInt() ?? 200,
      seedProfilesDir: seedProfilesDir,
      gameSetupConfig: setup,
      sevenGpGameSetupConfig: sevenGpSetup,
      outputDir: outputDir,
      seed: seed,
      sevenGpGamesPerProfile: sevenGpGamesPerProfile,
      stageFitnessWeights: stageFitnessWeights,
      sevenGpOpponentSelection: sevenGpOpponentSelection,
      sevenGpFallbackDefaultAiSeats: sevenGpFallbackDefaultAiSeats,
      sevenGpFallbackRandomizedAiSeats: sevenGpFallbackRandomizedAiSeats,
      sevenGpUseBlessedProfiles: sevenGpUseBlessedProfiles,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'population_size': populationSize,
    'games_per_profile': gamesPerProfile,
    'max_generations': maxGenerations,
    'game_player_count': gamePlayerCount,
    'max_turns': maxTurns,
    'seed_profiles_dir': seedProfilesDir,
    'game_setup_config': gameSetupConfigToJson(gameSetupConfig),
    'output_dir': outputDir,
    'seed': seed,
    'seven_gp_games_per_profile': sevenGpGamesPerProfile,
    'stage_fitness_weights': stageFitnessWeights.toJson(),
    'seven_gp_opponent_selection': sevenGpOpponentSelection,
    'seven_gp_fallback_default_ai_seats': sevenGpFallbackDefaultAiSeats,
    'seven_gp_fallback_randomized_ai_seats': sevenGpFallbackRandomizedAiSeats,
    'seven_gp_use_blessed_profiles': sevenGpUseBlessedProfiles,
  };
}

/// Observer-compatible setup JSON (fully-AI).
Map<String, dynamic> gameSetupConfigToJson(GameSetupConfig config) =>
    <String, dynamic>{
      'selectedGreatPowerIds': config.selectedGreatPowerIds,
      if (config.leaderVariantByGpId.isNotEmpty)
        'leaderVariantByGpId': config.leaderVariantByGpId,
      'continentCount': config.continentCount,
      'minorNationCount': config.minorNationCount,
      'tribeCount': config.tribeCount,
      'numProvincesOldWorld': config.numProvincesOldWorld,
      'numProvincesNewWorld': config.numProvincesNewWorld,
      'minProvincesPerMinor': config.minProvincesPerMinor,
      'seed': config.seed,
      'humanGreatPowerSlotIndices': <int>[],
      if (config.initTownRoadWiringRegionIds.isNotEmpty)
        'initTownRoadWiringRegionIds':
            config.initTownRoadWiringRegionIds.toList(),
    };

GameSetupConfig _gameSetupFromJson(Map<String, dynamic> json) {
  final base = GameSetupConfig.defaultConfig;
  List<String> selectedIds = base.selectedGreatPowerIds;
  final jsonSelected = json['selectedGreatPowerIds'];
  if (jsonSelected is List<dynamic>) {
    selectedIds = jsonSelected.map((e) => e.toString()).toList();
  }
  Map<String, String> leaderVariantByGpId = base.leaderVariantByGpId;
  final jsonLeader = json['leaderVariantByGpId'];
  if (jsonLeader is Map<String, dynamic>) {
    leaderVariantByGpId = Map<String, String>.from(
      jsonLeader.map((String k, dynamic v) => MapEntry(k, v.toString())),
    );
  }
  return GameSetupConfig(
    selectedGreatPowerIds: selectedIds,
    leaderVariantByGpId: leaderVariantByGpId,
    continentCount:
        (json['continentCount'] as num?)?.toInt() ?? base.continentCount,
    minorNationCount:
        (json['minorNationCount'] as num?)?.toInt() ?? base.minorNationCount,
    tribeCount: (json['tribeCount'] as num?)?.toInt() ?? base.tribeCount,
    numProvincesOldWorld:
        (json['numProvincesOldWorld'] as num?)?.toInt() ??
        base.numProvincesOldWorld,
    numProvincesNewWorld:
        (json['numProvincesNewWorld'] as num?)?.toInt() ??
        base.numProvincesNewWorld,
    minProvincesPerMinor:
        (json['minProvincesPerMinor'] as num?)?.toInt() ??
        base.minProvincesPerMinor,
    seed: (json['seed'] as num?)?.toInt() ?? base.seed,
    humanGreatPowerSlotIndices: const <int>{},
    initTownRoadWiringRegionIds:
        json['initTownRoadWiringRegionIds'] is List<dynamic>
        ? (json['initTownRoadWiringRegionIds'] as List<dynamic>)
              .map((e) => e.toString())
              .toSet()
        : base.initTownRoadWiringRegionIds,
  );
}

/// Rebuilds [GameSetupConfig] with an overridden per-game seed.
GameSetupConfig withGameSeed(GameSetupConfig config, int seed) =>
    GameSetupConfig(
      selectedGreatPowerIds: config.selectedGreatPowerIds,
      leaderVariantByGpId: config.leaderVariantByGpId,
      continentCount: config.continentCount,
      minorNationCount: config.minorNationCount,
      tribeCount: config.tribeCount,
      numProvincesOldWorld: config.numProvincesOldWorld,
      numProvincesNewWorld: config.numProvincesNewWorld,
      minProvincesPerMinor: config.minProvincesPerMinor,
      seed: seed,
      preferredInitialMapZoomMultiplier:
          config.preferredInitialMapZoomMultiplier,
      startingResources: config.startingResources,
      humanGreatPowerSlotIndices: const <int>{},
      initTownRoadWiringRegionIds: config.initTownRoadWiringRegionIds,
    );

/// Merges GA profile-builder output with optional fields parsed from JSON.
GameSetupConfig _mergeGaSetupExtras(
  GameSetupConfig derived,
  GameSetupConfig parsed,
) =>
    GameSetupConfig(
      selectedGreatPowerIds: derived.selectedGreatPowerIds,
      leaderVariantByGpId: parsed.leaderVariantByGpId,
      continentCount: derived.continentCount,
      minorNationCount: derived.minorNationCount,
      tribeCount: derived.tribeCount,
      numProvincesOldWorld: derived.numProvincesOldWorld,
      numProvincesNewWorld: derived.numProvincesNewWorld,
      minProvincesPerMinor: derived.minProvincesPerMinor,
      seed: derived.seed,
      infiniteMode: parsed.infiniteMode,
      terrainVariation: parsed.terrainVariation,
      startingResources: parsed.startingResources,
      preferredInitialMapZoomMultiplier:
          parsed.preferredInitialMapZoomMultiplier,
      humanGreatPowerSlotIndices: const <int>{},
      initTownRoadWiringRegionIds: parsed.initTownRoadWiringRegionIds,
      aiProfileByGpId: parsed.aiProfileByGpId,
    );
