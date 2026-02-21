// Game factory - creates games for scenarios.
// Reuses ctdev init logic via init_game_orchestrator.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:hive/hive.dart';

/// Result of creating a game for a scenario.
/// Includes the game and supporting data for turn resolution.
class GameInitResult {
  const GameInitResult({
    required this.game,
    this.topology,
    this.tileMapByRegion,
  });

  final Game game;
  final MapTopology? topology;
  final Map<String, TileMapResult>? tileMapByRegion;
}

/// Factory for creating game instances for scenarios.
/// Supports both fresh initialization and loading saved games.
class GameFactory {
  GameFactory({this.saveAdapter, Box<dynamic>? box}) : _box = box;

  final GameSaveAdapter? saveAdapter;
  final Box<dynamic>? _box;

  /// Creates a fresh game from configuration.
  /// Reuses ctdev's runInitGame() logic.
  /// Returns InitGameResult with game and topology for turn resolution.
  Future<GameInitResult> createFreshGame(GameSetupConfig config) async {
    final result = runInitGame(
      config: config,
      options: const InitGameOptions(renderPng: false),
    );
    return GameInitResult(
      game: result.game,
      topology: result.combinedTopology,
      tileMapByRegion: result.tileMapByRegion,
    );
  }

  /// Creates a fresh game from a JSON config map.
  Future<GameInitResult> createFreshGameFromJson(Map<String, dynamic> json) async {
    final config = _parseGameSetupConfig(json);
    return createFreshGame(config);
  }

  /// Loads a saved game by ID.
  Future<Game?> loadSavedGame(String gameId) async {
    if (saveAdapter == null) {
      throw StateError('No saveAdapter configured. Cannot load saved games.');
    }
    final box = _box ?? Hive.box<dynamic>('games');
    return saveAdapter!.load(box, gameId);
  }

  /// Parses a JSON map into GameSetupConfig.
  GameSetupConfig _parseGameSetupConfig(Map<String, dynamic> json) {
    return GameSetupConfig(
      selectedGreatPowerIds: (json['greatPowers'] as List<dynamic>?)
              ?.cast<String>() ??
          GameSetupConfig.defaultConfig.selectedGreatPowerIds,
      continentCount: json['continentCount'] as int? ?? 4,
      minorNationCount: json['minorNationCount'] as int? ?? 6,
      tribeCount: json['tribeCount'] as int? ?? 10,
      numProvincesOldWorld: json['numProvincesOldWorld'] as int? ?? 60,
      numProvincesNewWorld: json['numProvincesNewWorld'] as int? ?? 80,
      minProvincesPerMinor: json['minProvincesPerMinor'] as int? ?? 3,
      seed: json['seed'] as int? ?? 42,
    );
  }
}
