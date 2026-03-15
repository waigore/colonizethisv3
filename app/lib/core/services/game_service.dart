import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:hive/hive.dart';

/// Cached map data for a game (topology and tile maps for turn resolution).
class _GameMapCache {
  _GameMapCache({
    required this.combinedTopology,
    required this.tileMapByRegion,
    required this.topologyByRegion,
  });
  final MapTopology combinedTopology;
  final Map<String, TileMapResult> tileMapByRegion;
  final Map<String, MapTopology> topologyByRegion;
}

/// Loads/saves games and advances turn. SPEC/project/phase-1: app invokes TurnResolver and persists via colonizethis_save.
/// Phase 2: createNewGame uses full game-setup pipeline; nextTurn uses cached map data when available.
class GameService {
  GameService(this._box, this._adapter);

  final Box<dynamic> _box;
  final GameSaveAdapter _adapter;

  /// In-memory cache: game id -> map data for resolveTurnForGame and map rendering.
  /// Populated when creating a new game or when loading a game with persisted map data.
  final Map<String, _GameMapCache> _mapCache = {};

  /// Loads game by id. Returns null if not found.
  /// When map data exists in storage, populates _mapCache so map rendering works.
  Game? loadGame(String gameId) {
    final game = _adapter.load(_box, gameId);
    if (game == null) return null;
    final cached = _mapCache[gameId];
    if (cached != null) return game;
    final mapData = _adapter.loadMapData(_box, gameId);
    if (mapData != null) {
      _mapCache[gameId] = _GameMapCache(
        combinedTopology: mapData.combinedTopology,
        tileMapByRegion: mapData.tileMapByRegion,
        topologyByRegion: mapData.topologyByRegion,
      );
    }
    return game;
  }

  /// Returns map data for [gameId] from cache or storage. Null if not available (legacy save).
  ({
    MapTopology combinedTopology,
    Map<String, TileMapResult> tileMapByRegion,
    Map<String, MapTopology> topologyByRegion,
  })?
  getMapData(String gameId) {
    final cached = _mapCache[gameId];
    if (cached != null) {
      return (
        combinedTopology: cached.combinedTopology,
        tileMapByRegion: cached.tileMapByRegion,
        topologyByRegion: cached.topologyByRegion,
      );
    }
    final mapData = _adapter.loadMapData(_box, gameId);
    if (mapData == null) return null;
    _mapCache[gameId] = _GameMapCache(
      combinedTopology: mapData.combinedTopology,
      tileMapByRegion: mapData.tileMapByRegion,
      topologyByRegion: mapData.topologyByRegion,
    );
    return (
      combinedTopology: mapData.combinedTopology,
      tileMapByRegion: mapData.tileMapByRegion,
      topologyByRegion: mapData.topologyByRegion,
    );
  }

  /// Saves game to storage.
  void saveGame(Game game) => _adapter.save(_box, game);

  /// Lists all saved game ids.
  List<String> listGameIds() => _adapter.listGameIds(_box);

  /// Resolves one turn, persists the new state, and returns the updated game.
  ///
  /// When [topology] and [tileMapByRegion] are not provided, uses cached map data for [current.id] if present
  /// (so extraction runs from connectivity + resource extractor). Otherwise extraction phase leaves stockpiles unchanged.
  /// When [aiOrders] is provided, merges with [orders] (human over AI) before resolution.
  Game nextTurn(
    Game current, {
    Orders? orders,
    Orders? aiOrders,
    MapTopology? topology,
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    final cache = _mapCache[current.id];
    final topo = topology ?? cache?.combinedTopology ?? const MapTopology();
    final tileMaps = tileMapByRegion ?? cache?.tileMapByRegion;
    final humanOrders = orders ?? const Orders();
    final resolvedOrders = aiOrders != null
        ? mergeOrderLists(humanOrders: humanOrders, aiOrders: aiOrders)
        : humanOrders;
    final result = resolveTurnForGame(
      game: current,
      topology: topo,
      orders: resolvedOrders,
      tileMapByRegion: tileMaps,
    );
    final newGame = requireTurnResolutionComplete(result);
    saveGame(newGame);
    return newGame;
  }

  /// Creates a new game via the full game-setup pipeline (map gen, province assignment, capital auto-choice).
  /// Uses [config] (defaults to GameSetupConfig.defaultConfig) and saves the game; map data is cached for nextTurn.
  Game createNewGame({String? id, GameSetupConfig? config}) {
    final gameId = id ?? 'game_${DateTime.now().millisecondsSinceEpoch}';
    final cfg = config ?? GameSetupConfig.defaultConfig;

    final mapGenParams = MapGenerationParams(
      numContinents: cfg.continentCount,
      seed: cfg.seed,
      seaFraction: 0.6,
    );
    final sizeOW = computeGridSizeFromParams(
      cfg.numProvincesOldWorld,
      mapGenParams,
    );
    final paramsOW = TileMapParams(
      width: sizeOW.width,
      height: sizeOW.height,
      seed: cfg.seed,
      seaFraction: 0.6,
    );
    final (tileMapOW, topoOW) = TileMapGenerator(params: paramsOW).generate(
      numProvinces: cfg.numProvincesOldWorld,
      numContinents: cfg.continentCount,
      regionId: 'oldWorld',
      resourceRules: ResourceRules.defaultRules,
    );

    final sizeNW = computeGridSizeFromParams(
      cfg.numProvincesNewWorld,
      mapGenParams,
    );
    final paramsNW = TileMapParams(
      width: sizeNW.width,
      height: sizeNW.height,
      seed: cfg.seed + 1,
      seaFraction: 0.6,
    );
    final (tileMapNW, topoNW) = TileMapGenerator(params: paramsNW).generate(
      numProvinces: cfg.numProvincesNewWorld,
      numContinents: cfg.continentCount.clamp(1, cfg.numProvincesNewWorld),
      regionId: 'newWorld',
      resourceRules: ResourceRules.defaultRules,
    );

    final result = createGameFromGeneratedMaps(
      config: cfg,
      tileMapOldWorld: tileMapOW,
      topologyOldWorld: topoOW,
      tileMapNewWorld: tileMapNW,
      topologyNewWorld: topoNW,
      gameId: gameId,
    );

    _mapCache[gameId] = _GameMapCache(
      combinedTopology: result.combinedTopology,
      tileMapByRegion: result.tileMapByRegion,
      topologyByRegion: result.topologyByRegion,
    );
    _adapter.saveMapData(
      _box,
      gameId,
      tileMapByRegion: result.tileMapByRegion,
      topologyByRegion: result.topologyByRegion,
      combinedTopology: result.combinedTopology,
    );
    saveGame(result.game);
    return result.game;
  }
}
