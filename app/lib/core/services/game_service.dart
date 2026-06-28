import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app/config/ct_debug_console.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_app/perf/app_perf_trace.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart'
    show assignHiddenAgendasForGame;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:hive/hive.dart';

part 'game_service_new_game_setup.dart';
part 'game_service_turn_trace.dart';

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

/// Public record type for [GameService.getMapData] (Refs #2575 Phase 4).
/// Lets callers replace `dynamic` with an explicit type while still using
/// record-style access (`mapData.combinedTopology`, etc.).
typedef GameMapData = ({
  MapTopology combinedTopology,
  Map<String, TileMapResult> tileMapByRegion,
  Map<String, MapTopology> topologyByRegion,
  List<WarpLink>? warpLinks,
});

/// Pass milestones for in-app tile map generation (SPEC/program/logging/map-generation.md).
final _mapGenPassLog = packageLogger('tile_map');

/// Loads/saves games and advances turn. SPEC/project/phase-1: app invokes TurnResolver and persists via colonizethis_save.
/// Phase 2: createNewGame uses full game-setup pipeline; nextTurn requires cached/persisted map data.
class GameService {
  /// Number of coarse progress steps reported by [createNewGameAsync]. SPEC/ui/game-initializing.md.
  static const int newGameSetupProgressStepCount = 5;
  GameService(
    this._box,
    this._adapter, {
    bool? turnTraceEnabled,
    String? turnTraceRootDirectory,
  }) : _turnTraceEnabled = turnTraceEnabled ?? kCtDebugConsoleEnabled,
       turnTraceRootDirectory =
           turnTraceRootDirectory ?? kCtTurnTraceDirectory;

  final Box<dynamic> _box;
  final GameSaveAdapter _adapter;
  final bool _turnTraceEnabled;
  final String turnTraceRootDirectory;
  final Map<String, _TurnTraceSession> _turnTraceSessionsByGameId = {};

  /// Whether merged JSON turn traces are emitted (app debug console gate).
  bool get isTurnTraceEnabled => _turnTraceEnabled;

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

  _GameMapCache _requireMapData(String gameId) {
    final cached = _mapCache[gameId];
    if (cached != null) return cached;
    final mapData = _adapter.loadMapData(_box, gameId);
    final loaded = _GameMapCache(
      combinedTopology: mapData.combinedTopology,
      tileMapByRegion: mapData.tileMapByRegion,
      topologyByRegion: mapData.topologyByRegion,
      warpLinks: mapData.warpLinks,
    );
    _mapCache[gameId] = loaded;
    return loaded;
  }

  /// Loads game by id. Returns null if not found or required map data is missing/invalid.
  /// Populates _mapCache on successful load so map rendering and turn resolution work.
  Game? loadGame(String gameId) {
    final game = _adapter.load(_box, gameId);
    if (game == null) return null;
    try {
      _requireMapData(gameId);
      return game;
    } catch (e, st) {
      packageLogger().e(
        'required map data missing/invalid for gameId=$gameId',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Returns map data for [gameId] from cache or storage.
  ///
  /// When [_mapCache] already holds [gameId], returns immediately without reading game
  /// JSON from Hive (avoids redundant adapter load on UI hot paths). Otherwise loads
  /// game JSON to verify existence, then ensures map data is loaded.
  ///
  /// Returns null only when no game exists for [gameId]. For existing games, map data
  /// is required and missing/invalid map data raises [StateError].
  GameMapData? getMapData(String gameId) {
    final cached = _mapCache[gameId];
    if (cached != null) {
      return (
        combinedTopology: cached.combinedTopology,
        tileMapByRegion: cached.tileMapByRegion,
        topologyByRegion: cached.topologyByRegion,
        warpLinks: cached.warpLinks,
      );
    }
    final gameExists = _adapter.load(_box, gameId) != null;
    if (!gameExists) return null;
    final cache = _requireMapData(gameId);
    return (
      combinedTopology: cache.combinedTopology,
      tileMapByRegion: cache.tileMapByRegion,
      topologyByRegion: cache.topologyByRegion,
      warpLinks: cache.warpLinks,
    );
  }

  ({
    MapTopology combinedTopology,
    Map<String, TileMapResult> tileMapByRegion,
    Map<String, MapTopology> topologyByRegion,
    List<WarpLink>? warpLinks,
  })
  _requiredMapDataView(String gameId) {
    final cache = _requireMapData(gameId);
    return (
      combinedTopology: cache.combinedTopology,
      tileMapByRegion: cache.tileMapByRegion,
      topologyByRegion: cache.topologyByRegion,
      warpLinks: cache.warpLinks,
    );
  }

  /// Optional strip for session-only observe control overrides before persist.
  Game Function(Game)? prepareGameForPersistence;

  /// Saves game to storage.
  void saveGame(Game game) {
    final toSave = prepareGameForPersistence?.call(game) ?? game;
    _adapter.save(_box, toSave);
  }

  /// Lists all saved game ids.
  List<String> listGameIds() => _adapter.listGameIds(_box);

  /// Whether the Hive auto-save slot is playable. Clears invalid slots. SPEC/program/save-load.md.
  bool hasValidAutoSave() => _adapter.hasValidAutoSave(_box);

  /// Loads the auto-save slot into memory cache under [Game.id]. Returns null if missing/invalid.
  Game? loadAutoSaveGame() {
    if (!_adapter.hasValidAutoSave(_box)) {
      return null;
    }
    final game = _adapter.load(_box, kAutoSaveSlotId);
    if (game == null) {
      return null;
    }
    try {
      final mapData = _adapter.loadMapData(_box, kAutoSaveSlotId);
      _mapCache[game.id] = _GameMapCache(
        combinedTopology: mapData.combinedTopology,
        tileMapByRegion: mapData.tileMapByRegion,
        topologyByRegion: mapData.topologyByRegion,
        warpLinks: mapData.warpLinks,
      );
      return game;
    } catch (e, st) {
      packageLogger().e(
        'save: loadAutoSaveGame failed',
        error: e,
        stackTrace: st,
      );
      _adapter.delete(_box, kAutoSaveSlotId);
      return null;
    }
  }

  void _mirrorAutoSave(Game game) {
    try {
      final md = _requiredMapDataView(game.id);
      _adapter.saveAutoSave(
        _box,
        game,
        tileMapByRegion: md.tileMapByRegion,
        topologyByRegion: md.topologyByRegion,
        combinedTopology: md.combinedTopology,
        warpLinks: md.warpLinks,
      );
    } catch (e, st) {
      packageLogger().e(
        'save: auto-save mirror failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// Resolves one turn. Returns [TurnResolutionComplete] with new game (and persists),
  /// or a pending result: [TurnResolutionPendingOvertures], [TurnResolutionPendingIntervention],
  /// or [TurnResolutionPendingCallToArms].
  /// SPEC/program/dialogue-system.md, SPEC/ai/dialogue-management.md.
  ///
  /// When result is [TurnResolutionComplete], saves and returns. When pending human input,
  /// does not save; caller must present dialogue and call the matching resume API, then persist.
  TurnResolutionResult runTurnResolution(
    Game current, {
    Orders? orders,
    Orders? aiOrders,
    List<TurnTraceAiSection>? aiTraceSections,
    MapTopology? topology,
    Map<String, TileMapResult>? tileMapByRegion,
    void Function(GameEvent)? onGameEvent,
  }) {
    final mapData = _requiredMapDataView(current.id);
    final topo = topology ?? mapData.combinedTopology;
    final tileMaps = tileMapByRegion ?? mapData.tileMapByRegion;
    final humanOrders = orders ?? const Orders();
    final resolvedOrders = aiOrders != null
        ? mergeOrderLists(humanOrders: humanOrders, aiOrders: aiOrders)
        : humanOrders;
    final result = _gameServiceResolveTurnWithTrace(
      this,
      game: current,
      aiTraceSections: aiTraceSections,
      config: TurnResolverConfig(
        topology: topo,
        orders: resolvedOrders,
        tileMapByRegion: tileMaps,
        eventSink: TurnEventSink(
          eventBus: logicEventBus,
          onGameEvent: onGameEvent,
        ),
      ),
    );
    _emitTurnResolutionEvents(result);
    return result;
  }

  /// Resumes turn resolution after the user has submitted call to arms decisions.
  TurnResolutionResult resumeCallToArmsDecisions(
    Game game,
    List<CallToArmsDecision> decisions,
    Orders orders, {
    void Function(GameEvent)? onGameEvent,
  }) {
    final mapData = _requiredMapDataView(game.id);
    final topo = mapData.combinedTopology;
    final tileMaps = mapData.tileMapByRegion;
    final result = _gameServiceResolveTurnWithTrace(
      this,
      game: game,
      config: TurnResolverConfig(
        topology: topo,
        orders: orders,
        tileMapByRegion: tileMaps,
        eventSink: TurnEventSink(
          eventBus: logicEventBus,
          onGameEvent: onGameEvent,
        ),
        startFromPhase: TurnPhase.diplomacy,
        callToArmsDecisions: decisions,
      ),
    );
    _emitTurnResolutionEvents(result);
    return result;
  }

  /// Resumes turn resolution after the user has submitted overture accept/reject decisions.
  /// Returns [TurnResolutionComplete] or again [TurnResolutionPendingOvertures].
  /// When [TurnResolutionComplete], saves the game. SPEC/program/dialogue-system.md.
  TurnResolutionResult resumeOvertureDecisions(
    Game game,
    List<OvertureOffer> _pendingOvertures,
    List<OvertureDecision> decisions,
    Orders orders, {
    void Function(GameEvent)? onGameEvent,
  }) {
    final mapData = _requiredMapDataView(game.id);
    final topo = mapData.combinedTopology;
    final tileMaps = mapData.tileMapByRegion;
    final result = _gameServiceResolveTurnWithTrace(
      this,
      game: game,
      config: TurnResolverConfig(
        topology: topo,
        orders: orders,
        tileMapByRegion: tileMaps,
        eventSink: TurnEventSink(
          eventBus: logicEventBus,
          onGameEvent: onGameEvent,
        ),
        startFromPhase: TurnPhase.diplomacy,
        overtureDecisions: decisions,
      ),
    );
    _emitTurnResolutionEvents(result);
    return result;
  }

  /// Resumes turn resolution after FTP accept/reject decisions (Diplomacy phase).
  TurnResolutionResult resumeFtpDecisions(
    Game game,
    List<FtpOffer> _pendingFtpOffers,
    List<FtpDecision> decisions,
    Orders orders, {
    void Function(GameEvent)? onGameEvent,
  }) {
    final mapData = _requiredMapDataView(game.id);
    final topo = mapData.combinedTopology;
    final tileMaps = mapData.tileMapByRegion;
    final result = _gameServiceResolveTurnWithTrace(
      this,
      game: game,
      config: TurnResolverConfig(
        topology: topo,
        orders: orders,
        tileMapByRegion: tileMaps,
        eventSink: TurnEventSink(
          eventBus: logicEventBus,
          onGameEvent: onGameEvent,
        ),
        startFromPhase: TurnPhase.diplomacy,
        ftpDecisions: decisions,
      ),
    );
    _emitTurnResolutionEvents(result);
    return result;
  }

  /// Resumes after human intervention choices (GP declared war on Minor/Tribe).
  TurnResolutionResult resumeInterventionDecisions(
    Game game,
    List<InterventionDecision> decisions,
    Orders orders, {
    void Function(GameEvent)? onGameEvent,
  }) {
    final mapData = _requiredMapDataView(game.id);
    final topo = mapData.combinedTopology;
    final tileMaps = mapData.tileMapByRegion;
    final result = _gameServiceResolveTurnWithTrace(
      this,
      game: game,
      config: TurnResolverConfig(
        topology: topo,
        orders: orders,
        tileMapByRegion: tileMaps,
        eventSink: TurnEventSink(
          eventBus: logicEventBus,
          onGameEvent: onGameEvent,
        ),
        startFromPhase: TurnPhase.diplomacy,
        interventionDecisions: decisions,
      ),
    );
    _emitTurnResolutionEvents(result);
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

  /// Creates a new game via the full game-setup pipeline (map gen, province assignment, capital auto-choice).
  Game createNewGame({String? id, GameSetupConfig? config}) =>
      _gameServiceCreateNewGame(this, id: id, config: config);

  /// Same pipeline as [createNewGame], but yields between coarse steps so the UI isolate can paint.
  Future<Game> createNewGameAsync({
    String? id,
    GameSetupConfig? config,
    void Function(int stepIndex, int totalSteps)? onProgress,
  }) =>
      _gameServiceCreateNewGameAsync(
        this,
        id: id,
        config: config,
        onProgress: onProgress,
      );

  /// Maps [TurnResolutionResult] to app-level bus events and persists when complete.
  /// SPEC/program/app-event-bus.md.
  void _emitTurnResolutionEvents(TurnResolutionResult result) {
    if (result is TurnResolutionComplete) {
      final complete = result;
      saveGame(complete.game);
      _mirrorAutoSave(complete.game);
      eventBus?.emit(
        TurnResolutionCompleteEvent(
          gameId: complete.game.id,
          turnNumber: complete.game.worldState.turnState.turnNumber,
          turnNewsDigest: complete.turnNewsDigest,
        ),
      );
      return;
    }
    if (result is TurnResolutionPendingOvertures) {
      eventBus?.emit(OvertureRequiredEvent(overtures: result.pendingOvertures));
      return;
    }
    if (result is TurnResolutionPendingFtp) {
      // FTP accept/reject UI is follow-up work; pending state is set via
      // [applyTurnResolutionResult] / [pendingDiplomacyProvider].
      return;
    }
    if (result is TurnResolutionPendingIntervention) {
      eventBus?.emit(
        InterventionRequiredEvent(prompts: result.pendingInterventions),
      );
      return;
    }
    if (result is TurnResolutionPendingCallToArms) {
      eventBus?.emit(
        CallToArmsRequiredEvent(pending: result.pendingCallToArms),
      );
    }
  }

  /// Emits app-level events and persistence side effects for externally resolved turns.
  void handleExternallyResolvedTurnResult(TurnResolutionResult result) {
    _emitTurnResolutionEvents(result);
  }

  /// Writes merged turn trace after resolution ran outside [runTurnResolution]
  /// (e.g. worker isolate). No-op when [isTurnTraceEnabled] is false.
  void exportTurnTraceForExternallyResolvedTurn({
    required Game gameAtResolutionStart,
    required Game turnEndState,
    required List<TurnTracePhaseTrace> phases,
    required List<TurnTraceAiSection> ai,
    required DateTime turnStartAtUtc,
  }) {
    if (!_turnTraceEnabled) {
      return;
    }
    _gameServiceExportTurnTrace(
      this,
      gameAtResolutionStart: gameAtResolutionStart,
      turnEndState: turnEndState,
      phases: phases,
      turnStartAt: turnStartAtUtc,
      ai: ai,
    );
  }
}
