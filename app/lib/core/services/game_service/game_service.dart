import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app_fixtures/config/ct_debug_console.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_app_fixtures/runtime/app_perf_trace.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart'
    show applyAdvancedStartBootstrap, assignHiddenAgendasForGame;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:hive/hive.dart';

part 'game_service_map_cache.dart';
part 'game_service_new_game_setup.dart';
part 'game_service_new_game_setup_pipeline.dart';
part 'game_service_new_game_setup_maps.dart';
part 'game_service_turn_resume.dart';
part 'game_service_turn_trace.dart';
part 'game_service_turn_trace_ai_sections.dart';

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

  /// Optional strip for session-only observe control overrides before persist.
  Game Function(Game)? prepareGameForPersistence;

  /// Clears map cache and turn-trace sessions. SPEC/program/save-load-session-clear.md.
  void clearSessionCaches() {
    _mapCache.clear();
    _turnTraceSessionsByGameId.clear();
  }

  /// Whether [gameId] is present in the in-memory map cache (tests / diagnostics).
  bool hasMapCacheEntry(String gameId) => _mapCache.containsKey(gameId);

  /// Count of in-memory map-cache entries (tests / diagnostics).
  int get mapCacheEntryCount => _mapCache.length;

  /// Count of turn-trace sessions (tests / diagnostics).
  int get turnTraceSessionCount => _turnTraceSessionsByGameId.length;

  /// Loads game by id. Returns null if not found or required map data is missing/invalid.
  Game? loadGame(String gameId) => _gameServiceLoadGame(this, gameId);

  /// Loads game plus mid-turn draft envelope fields.
  GameSaveSession? loadGameSession(String gameId) =>
      _gameServiceLoadGameSession(this, gameId);

  /// Returns map data for [gameId] from cache or storage.
  GameMapData? getMapData(String gameId) => _gameServiceGetMapData(this, gameId);

  /// Saves game to storage (empty mid-turn drafts unless [saveGameSession] is used).
  void saveGame(Game game) => _gameServiceSaveGame(this, game);

  /// Saves a named (or same-id) slot from the live [sessionGame], writing Hive
  /// key / embedded [Game.id] as [saveGameId], including mid-turn drafts.
  /// When [mirrorAutoSave] is true, also mirrors drafts into the auto-save slot
  /// using the live session id inside the auto-save JSON.
  void saveGameSession({
    required Game sessionGame,
    required String saveGameId,
    Orders draftOrders = const Orders(),
    Map<String, int> productionDesiredOutputByRecipe = const <String, int>{},
    String? displayName,
    bool mirrorAutoSave = true,
  }) =>
      _gameServiceSaveGameSession(
        this,
        sessionGame: sessionGame,
        saveGameId: saveGameId,
        draftOrders: draftOrders,
        productionDesiredOutputByRecipe: productionDesiredOutputByRecipe,
        displayName: displayName,
        mirrorAutoSave: mirrorAutoSave,
      );

  /// Lists all saved game ids.
  List<String> listGameIds() => _gameServiceListGameIds(this);

  /// Manual saves plus optional auto-save row for the load dialog.
  List<LoadableSaveEntry> listLoadableSaves() =>
      _gameServiceListLoadableSaves(this);

  /// Whether the Hive auto-save slot is playable.
  bool hasValidAutoSave() => _gameServiceHasValidAutoSave(this);

  /// Loads the auto-save slot into memory cache under [Game.id].
  Game? loadAutoSaveGame() => _gameServiceLoadAutoSaveGame(this);

  /// Loads auto-save with mid-turn draft fields.
  GameSaveSession? loadAutoSaveSession() =>
      _gameServiceLoadAutoSaveSession(this);

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
  }) =>
      _gameServiceRunTurnResolution(
        this,
        current,
        orders: orders,
        aiOrders: aiOrders,
        aiTraceSections: aiTraceSections,
        topology: topology,
        tileMapByRegion: tileMapByRegion,
        onGameEvent: onGameEvent,
      );

  /// Resumes turn resolution after the user has submitted call to arms decisions.
  TurnResolutionResult resumeCallToArmsDecisions(
    Game game,
    List<CallToArmsDecision> decisions,
    Orders orders, {
    void Function(GameEvent)? onGameEvent,
  }) =>
      _gameServiceResumeTurnFromDiplomacy(
        this,
        game,
        orders,
        onGameEvent: onGameEvent,
        callToArmsDecisions: decisions,
      );

  /// Resumes turn resolution after the user has submitted overture accept/reject decisions.
  /// Returns [TurnResolutionComplete] or again [TurnResolutionPendingOvertures].
  /// When [TurnResolutionComplete], saves the game. SPEC/program/dialogue-system.md.
  TurnResolutionResult resumeOvertureDecisions(
    Game game,
    List<OvertureOffer> _pendingOvertures,
    List<OvertureDecision> decisions,
    Orders orders, {
    void Function(GameEvent)? onGameEvent,
  }) =>
      _gameServiceResumeTurnFromDiplomacy(
        this,
        game,
        orders,
        onGameEvent: onGameEvent,
        overtureDecisions: decisions,
      );

  /// Resumes turn resolution after FTP accept/reject decisions (Diplomacy phase).
  TurnResolutionResult resumeFtpDecisions(
    Game game,
    List<FtpOffer> _pendingFtpOffers,
    List<FtpDecision> decisions,
    Orders orders, {
    void Function(GameEvent)? onGameEvent,
  }) =>
      _gameServiceResumeTurnFromDiplomacy(
        this,
        game,
        orders,
        onGameEvent: onGameEvent,
        ftpDecisions: decisions,
      );

  /// Resumes after human intervention choices (GP declared war on Minor/Tribe).
  TurnResolutionResult resumeInterventionDecisions(
    Game game,
    List<InterventionDecision> decisions,
    Orders orders, {
    void Function(GameEvent)? onGameEvent,
  }) =>
      _gameServiceResumeTurnFromDiplomacy(
        this,
        game,
        orders,
        onGameEvent: onGameEvent,
        interventionDecisions: decisions,
      );

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

  /// Emits app-level events and persistence side effects for externally resolved turns.
  void handleExternallyResolvedTurnResult(TurnResolutionResult result) =>
      _gameServiceEmitTurnResolutionEvents(this, result);

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
