import 'package:colonizethis_data/colonizethis_data.dart';

import '../setup/ga_setup_profile.dart';

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
    required this.outputDir,
    required this.seed,
  });

  final int populationSize;
  final int gamesPerProfile;
  final int maxGenerations;
  final int gamePlayerCount;
  final int maxTurns;
  final String seedProfilesDir;
  final GameSetupConfig gameSetupConfig;
  final String outputDir;
  final int seed;

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
    return GaConfig(
      populationSize: (json['population_size'] as num?)?.toInt() ?? 20,
      gamesPerProfile: (json['games_per_profile'] as num?)?.toInt() ?? 5,
      maxGenerations: (json['max_generations'] as num?)?.toInt() ?? 100,
      gamePlayerCount: playerCount,
      maxTurns: (json['max_turns'] as num?)?.toInt() ?? 200,
      seedProfilesDir: seedProfilesDir,
      gameSetupConfig: setup,
      outputDir: outputDir,
      seed: seed,
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
