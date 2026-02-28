// Game factory - creates games for scenarios.
// Reuses ctdev init logic via init_game_orchestrator.
// fromTopology: build game from fixed topology + grid for connectivity scenarios.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:hive/hive.dart';

import 'scenario.dart';

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

  /// Creates a game from fixed topology + grid (for connectivity scenarios).
  /// [init] must have type 'fromTopology', config (greatPowers, optional seed),
  /// oldWorld: { grid: List<List<String>>, nodes: [...], edges: [...] }, and optional newWorld.
  Future<GameInitResult> createFromTopology(ScenarioInit init) async {
    if (init.type != 'fromTopology' || init.oldWorld == null) {
      throw ArgumentError('createFromTopology requires init.type==fromTopology and init.oldWorld');
    }
    final ow = init.oldWorld!;
    final tileMapOW = _tileMapFromTopologyJson(ow);
    final topologyOW = MapTopology.fromJson(Map<String, dynamic>.from(ow));

    TileMapResult tileMapNW;
    MapTopology topologyNW;
    if (init.newWorld != null &&
        init.newWorld!.isNotEmpty &&
        (init.newWorld!['grid'] as List<dynamic>?)?.isNotEmpty == true) {
      final nw = init.newWorld!;
      tileMapNW = _tileMapFromTopologyJson(nw);
      topologyNW = MapTopology.fromJson(Map<String, dynamic>.from(nw));
    } else {
      // Minimal NW (config requires numProvincesNewWorld >= 1): one province for tribes.
      tileMapNW = TileMapResult(width: 1, height: 1, grid: [['nw1']]);
      topologyNW = MapTopology(
        nodes: const [
          TopologyNode(id: 'nw1', regionId: 'newWorld', type: TopologyNodeType.province),
        ],
        edges: const [],
      );
    }

    final numOW = topologyOW.nodes
        .where((n) => n.type == TopologyNodeType.province)
        .length;
    final numNW = topologyNW.nodes
        .where((n) => n.type == TopologyNodeType.province)
        .length;
    // SPEC/game/game-setup.md: config from scenario. fromTopology = minimal map for connectivity tests; no minors.
    final baseConfig = init.config != null
        ? _parseGameSetupConfig(init.config!)
        : GameSetupConfig(
            selectedGreatPowerIds: ['england'],
            continentCount: 1,
            minorNationCount: 0,
            tribeCount: 1,
            numProvincesOldWorld: 60,
            numProvincesNewWorld: 1,
            minProvincesPerMinor: 0,
            seed: 42,
          );
    final config = GameSetupConfig(
      selectedGreatPowerIds: baseConfig.selectedGreatPowerIds,
      continentCount: baseConfig.continentCount,
      minorNationCount: 0, // fromTopology: fixed topology, no minor nations (SPEC/program/sim-scenarios.md)
      tribeCount: numNW > 0 ? baseConfig.tribeCount : 0,
      numProvincesOldWorld: numOW,
      numProvincesNewWorld: numNW >= 1 ? numNW : 1,
      minProvincesPerMinor: 0, // fromTopology: no reservation for minors
      seed: baseConfig.seed,
    );

    final warpLinks = generateWarpZones(
      tileMapOldWorld: tileMapOW,
      topologyOldWorld: topologyOW,
      tileMapNewWorld: tileMapNW,
      topologyNewWorld: topologyNW,
      regionIdOld: 'oldWorld',
      regionIdNew: 'newWorld',
      seed: config.seed,
    );

    final setupResult = createGameFromGeneratedMaps(
      config: config,
      tileMapOldWorld: tileMapOW,
      topologyOldWorld: topologyOW,
      tileMapNewWorld: tileMapNW,
      topologyNewWorld: topologyNW,
      gameId: 'scenario_${DateTime.now().millisecondsSinceEpoch}',
      namingSeed: config.seed,
      warpLinks: warpLinks,
    );

    return GameInitResult(
      game: setupResult.game,
      topology: setupResult.combinedTopology,
      tileMapByRegion: setupResult.tileMapByRegion,
    );
  }

  static TileMapResult _tileMapFromTopologyJson(Map<String, dynamic> json) {
    final gridRaw = json['grid'] as List<dynamic>?;
    if (gridRaw == null || gridRaw.isEmpty) {
      return TileMapResult(width: 0, height: 0, grid: []);
    }
    final grid = gridRaw
        .map((row) => (row as List<dynamic>).map((e) => e as String).toList())
        .toList();
    final height = grid.length;
    final width = height > 0 ? grid[0].length : 0;

    List<List<Resource?>>? resourceGrid;
    final rg = json['resourceGrid'] as List<dynamic>?;
    if (rg != null && rg.length == height) {
      resourceGrid = rg
          .map((row) => (row as List<dynamic>)
              .map((e) => e == null || e == ''
                  ? null
                  : Resource.values.byName(e as String))
              .toList())
          .toList();
      if (resourceGrid.any((row) => row.length != width)) {
        resourceGrid = null;
      }
    }

    return TileMapResult(
      width: width,
      height: height,
      grid: grid,
      resourceGrid: resourceGrid,
    );
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
