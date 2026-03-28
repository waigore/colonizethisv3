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
    this.warpLinks,
  });
  final MapTopology combinedTopology;
  final Map<String, TileMapResult> tileMapByRegion;
  final Map<String, MapTopology> topologyByRegion;
  final List<WarpLink>? warpLinks;
}

/// Loads/saves games and advances turn. SPEC/project/phase-1: app invokes TurnResolver and persists via colonizethis_save.
/// Phase 2: createNewGame uses full game-setup pipeline; nextTurn uses cached map data when available.
class GameService {
  GameService(this._box, this._adapter);

  final Box<dynamic> _box;
  final GameSaveAdapter _adapter;

  /// Optional app-level bus for [GameToUIEvent] (turn complete, new game, overtures, etc.).
  /// When set, those events are emitted from turn resolution and [createNewGame].
  /// Logic-layer [GameEvent] still uses [runTurnResolution] / [resumeOvertureDecisions]
  /// `onGameEvent` when provided. SPEC/program/app-event-bus.md.
  AppEventBus? eventBus;

  /// Optional logic-level event bus for GameEvent forwarding to AppEventBus via GameEventBridge.
  /// When set, runTurnResolution passes it to resolveTurnForGame.
  GameEventBus? logicEventBus;

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
        warpLinks: mapData.warpLinks,
      );
    }
    return game;
  }

  /// Returns map data for [gameId] from cache or storage. Null if not available (legacy save).
  ({
    MapTopology combinedTopology,
    Map<String, TileMapResult> tileMapByRegion,
    Map<String, MapTopology> topologyByRegion,
    List<WarpLink>? warpLinks,
  })?
  getMapData(String gameId) {
    final cached = _mapCache[gameId];
    if (cached != null) {
      return (
        combinedTopology: cached.combinedTopology,
        tileMapByRegion: cached.tileMapByRegion,
        topologyByRegion: cached.topologyByRegion,
        warpLinks: cached.warpLinks,
      );
    }
    final mapData = _adapter.loadMapData(_box, gameId);
    if (mapData == null) return null;
    _mapCache[gameId] = _GameMapCache(
      combinedTopology: mapData.combinedTopology,
      tileMapByRegion: mapData.tileMapByRegion,
      topologyByRegion: mapData.topologyByRegion,
      warpLinks: mapData.warpLinks,
    );
    return (
      combinedTopology: mapData.combinedTopology,
      tileMapByRegion: mapData.tileMapByRegion,
      topologyByRegion: mapData.topologyByRegion,
      warpLinks: mapData.warpLinks,
    );
  }

  /// Saves game to storage.
  void saveGame(Game game) => _adapter.save(_box, game);

  /// Lists all saved game ids.
  List<String> listGameIds() => _adapter.listGameIds(_box);

  /// Resolves one turn. Returns [TurnResolutionComplete] with new game (and persists),
  /// [TurnResolutionPendingOvertures], or [TurnResolutionPendingIntervention].
  /// SPEC/program/dialogue-system.md, SPEC/ai/dialogue-management.md.
  ///
  /// When result is [TurnResolutionComplete], saves and returns. When pending human input,
  /// does not save; caller must present dialogue and call the matching resume API, then persist.
  TurnResolutionResult runTurnResolution(
    Game current, {
    Orders? orders,
    Orders? aiOrders,
    MapTopology? topology,
    Map<String, TileMapResult>? tileMapByRegion,
    void Function(GameEvent)? onGameEvent,
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
      eventBus: logicEventBus,
      onGameEvent: onGameEvent,
    );
    if (result is TurnResolutionComplete) {
      final complete = result;
      saveGame(complete.game);
      eventBus?.emit(
        TurnResolutionCompleteEvent(
          gameId: complete.game.id,
          turnNumber: complete.game.worldState.turnState.turnNumber,
        ),
      );
    } else if (result is TurnResolutionPendingOvertures) {
      eventBus?.emit(OvertureRequiredEvent(overtures: result.pendingOvertures));
    } else if (result is TurnResolutionPendingIntervention) {
      eventBus?.emit(
        InterventionRequiredEvent(prompts: result.pendingInterventions),
      );
    }
    return result;
  }

  /// Resumes turn resolution after the user has submitted overture accept/reject decisions.
  /// Returns [TurnResolutionComplete] or again [TurnResolutionPendingOvertures].
  /// When [TurnResolutionComplete], saves the game. SPEC/program/dialogue-system.md.
  TurnResolutionResult resumeOvertureDecisions(
    Game game,
    List<OvertureOffer> pendingOvertures,
    List<OvertureDecision> decisions,
    Orders orders, {
    void Function(GameEvent)? onGameEvent,
  }) {
    final cache = _mapCache[game.id];
    final topo = cache?.combinedTopology ?? const MapTopology();
    final tileMaps = cache?.tileMapByRegion;
    final result = resumeTurnResolutionWithOvertureDecisions(
      game: game,
      pendingOvertures: pendingOvertures,
      decisions: decisions,
      topology: topo,
      orders: orders,
      tileMapByRegion: tileMaps,
      eventBus: logicEventBus,
      onGameEvent: onGameEvent,
    );
    if (result is TurnResolutionComplete) {
      final complete = result;
      saveGame(complete.game);
      eventBus?.emit(
        TurnResolutionCompleteEvent(
          gameId: complete.game.id,
          turnNumber: complete.game.worldState.turnState.turnNumber,
        ),
      );
    } else if (result is TurnResolutionPendingOvertures) {
      eventBus?.emit(OvertureRequiredEvent(overtures: result.pendingOvertures));
    } else if (result is TurnResolutionPendingIntervention) {
      eventBus?.emit(
        InterventionRequiredEvent(prompts: result.pendingInterventions),
      );
    }
    return result;
  }

  /// Resumes after human intervention choices (GP declared war on Minor/Tribe).
  TurnResolutionResult resumeInterventionDecisions(
    Game game,
    List<InterventionDecision> decisions,
    Orders orders, {
    void Function(GameEvent)? onGameEvent,
  }) {
    final cache = _mapCache[game.id];
    final topo = cache?.combinedTopology ?? const MapTopology();
    final tileMaps = cache?.tileMapByRegion;
    final result = resumeTurnResolutionWithInterventionDecisions(
      game: game,
      decisions: decisions,
      topology: topo,
      orders: orders,
      tileMapByRegion: tileMaps,
      eventBus: logicEventBus,
      onGameEvent: onGameEvent,
    );
    if (result is TurnResolutionComplete) {
      final complete = result;
      saveGame(complete.game);
      eventBus?.emit(
        TurnResolutionCompleteEvent(
          gameId: complete.game.id,
          turnNumber: complete.game.worldState.turnState.turnNumber,
        ),
      );
    } else if (result is TurnResolutionPendingOvertures) {
      eventBus?.emit(OvertureRequiredEvent(overtures: result.pendingOvertures));
    } else if (result is TurnResolutionPendingIntervention) {
      eventBus?.emit(
        InterventionRequiredEvent(prompts: result.pendingInterventions),
      );
    }
    return result;
  }

  /// Resolves one turn and returns the updated game; throws if resolution is pending overtures.
  /// Prefer [runTurnResolution] when the UI can show the overture dialogue.
  Game nextTurn(
    Game current, {
    Orders? orders,
    Orders? aiOrders,
    MapTopology? topology,
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    final result = runTurnResolution(
      current,
      orders: orders,
      aiOrders: aiOrders,
      topology: topology,
      tileMapByRegion: tileMapByRegion,
    );
    return requireTurnResolutionComplete(result);
  }

  /// Number of coarse progress steps reported by [createNewGameAsync]. SPEC/ui/game-initializing.md.
  static const int newGameSetupProgressStepCount = 5;

  /// Creates a new game via the full game-setup pipeline (map gen, province assignment, capital auto-choice).
  /// Uses [config] (defaults to GameSetupConfig.defaultConfig) and saves the game; map data is cached for nextTurn.
  Game createNewGame({String? id, GameSetupConfig? config}) {
    final gameId = id ?? 'game_${DateTime.now().millisecondsSinceEpoch}';
    final cfg = config ?? GameSetupConfig.defaultConfig;
    final (tileMapOW, topoOW) = _generateTileMapOldWorld(cfg);
    final (tileMapNW, topoNW) = _generateTileMapNewWorld(cfg);
    final warpLinks = _generateWarpLinks(
      cfg: cfg,
      tileMapOW: tileMapOW,
      topoOW: topoOW,
      tileMapNW: tileMapNW,
      topoNW: topoNW,
    );
    final result = createGameFromGeneratedMaps(
      config: cfg,
      tileMapOldWorld: tileMapOW,
      topologyOldWorld: topoOW,
      tileMapNewWorld: tileMapNW,
      topologyNewWorld: topoNW,
      gameId: gameId,
      warpLinks: warpLinks,
    );
    _persistNewGame(gameId: gameId, result: result);
    return result.game;
  }

  /// Same pipeline as [createNewGame], but yields between coarse steps so the UI isolate can paint.
  /// [onProgress] is invoked with `(stepIndex, newGameSetupProgressStepCount)` before each major phase
  /// (0 = Old World map … 4 = saving). SPEC/ui/game-initializing.md.
  Future<Game> createNewGameAsync({
    String? id,
    GameSetupConfig? config,
    void Function(int stepIndex, int totalSteps)? onProgress,
  }) async {
    final gameId = id ?? 'game_${DateTime.now().millisecondsSinceEpoch}';
    final cfg = config ?? GameSetupConfig.defaultConfig;
    const total = newGameSetupProgressStepCount;
    Future<void> yieldUi() => Future<void>.delayed(Duration.zero);

    // Let any pending frame (e.g. progress modal paint) run before step 0 work.
    await yieldUi();

    onProgress?.call(0, total);
    await yieldUi();
    final (tileMapOW, topoOW) = _generateTileMapOldWorld(cfg);

    onProgress?.call(1, total);
    await yieldUi();
    final (tileMapNW, topoNW) = _generateTileMapNewWorld(cfg);

    onProgress?.call(2, total);
    await yieldUi();
    final warpLinks = _generateWarpLinks(
      cfg: cfg,
      tileMapOW: tileMapOW,
      topoOW: topoOW,
      tileMapNW: tileMapNW,
      topoNW: topoNW,
    );

    onProgress?.call(3, total);
    await yieldUi();
    final result = createGameFromGeneratedMaps(
      config: cfg,
      tileMapOldWorld: tileMapOW,
      topologyOldWorld: topoOW,
      tileMapNewWorld: tileMapNW,
      topologyNewWorld: topoNW,
      gameId: gameId,
      warpLinks: warpLinks,
    );

    onProgress?.call(4, total);
    await yieldUi();
    _persistNewGame(gameId: gameId, result: result);
    return result.game;
  }

  (TileMapResult, MapTopology) _generateTileMapOldWorld(GameSetupConfig cfg) {
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
    return TileMapGenerator(params: paramsOW).generate(
      numProvinces: cfg.numProvincesOldWorld,
      numContinents: cfg.continentCount,
      regionId: 'oldWorld',
      resourceRules: ResourceRules.defaultRules,
    );
  }

  (TileMapResult, MapTopology) _generateTileMapNewWorld(GameSetupConfig cfg) {
    final mapGenParams = MapGenerationParams(
      numContinents: cfg.continentCount,
      seed: cfg.seed,
      seaFraction: 0.6,
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
    return TileMapGenerator(params: paramsNW).generate(
      numProvinces: cfg.numProvincesNewWorld,
      numContinents: cfg.continentCount.clamp(1, cfg.numProvincesNewWorld),
      regionId: 'newWorld',
      resourceRules: ResourceRules.defaultRules,
    );
  }

  List<WarpLink> _generateWarpLinks({
    required GameSetupConfig cfg,
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
      regionIdOld: 'oldWorld',
      regionIdNew: 'newWorld',
      seed: cfg.seed,
    );
  }

  void _persistNewGame({
    required String gameId,
    required GameSetupResult result,
  }) {
    _mapCache[gameId] = _GameMapCache(
      combinedTopology: result.combinedTopology,
      tileMapByRegion: result.tileMapByRegion,
      topologyByRegion: result.topologyByRegion,
      warpLinks: result.warpLinks,
    );
    _adapter.saveMapData(
      _box,
      gameId,
      tileMapByRegion: result.tileMapByRegion,
      topologyByRegion: result.topologyByRegion,
      combinedTopology: result.combinedTopology,
      warpLinks: result.warpLinks,
    );
    saveGame(result.game);
    eventBus?.emit(NewGameCreatedEvent(gameId: result.game.id));
  }
}
