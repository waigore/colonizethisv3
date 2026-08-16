import 'package:colonizethis_app_fixtures/config/ct_debug_console.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_turn/colonizethis_turn.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:hive/hive.dart';

import 'game_service_map_cache.dart';
import 'game_service_new_game_setup.dart';
import 'game_service_turn_resume.dart';
import 'game_service_turn_trace.dart';

export 'game_service_types.dart'
    show GameMapCache, GameMapData, TurnTraceSession;
export 'try_get_game_map_data.dart';

/// Loads/saves games and advances turn. SPEC/project/phase-1: app invokes TurnResolver and persists via colonizethis_save.
/// Phase 2: createNewGame uses full game-setup pipeline; nextTurn requires cached/persisted map data.
class GameService {
  /// Number of coarse progress steps reported by [createNewGameAsync]. SPEC/ui/game-initializing.md.
  static const int newGameSetupProgressStepCount = 5;
  GameService(
    Box<dynamic> box,
    GameSaveAdapter adapter, {
    bool? turnTraceEnabled,
    String? turnTraceRootDirectory,
  }) : state = GameServiceState(
         box: box,
         adapter: adapter,
         turnTraceEnabled: turnTraceEnabled ?? kCtDebugConsoleEnabled,
         turnTraceRootDirectory:
             turnTraceRootDirectory ?? kCtTurnTraceDirectory,
       );

  /// Session fields shared by de-parted implementation libraries (Refs #4117).
  final GameServiceState state;

  /// Whether merged JSON turn traces are emitted (app debug console gate).
  bool get isTurnTraceEnabled => state.turnTraceEnabled;

  /// Root directory for merged turn-trace JSON exports.
  String get turnTraceRootDirectory => state.turnTraceRootDirectory;

  /// Optional app-level bus for [GameToUIEvent] (turn complete, new game, overtures, etc.).
  /// When set, those events are emitted from turn resolution and [createNewGame].
  /// Logic-layer [GameEvent] still uses [runTurnResolution] / [resumeOvertureDecisions]
  /// `onGameEvent` when provided. SPEC/program/app-event-bus.md.
  AppEventBus? eventBus;

  /// Optional logic-level event bus for GameEvent forwarding to AppEventBus via GameEventBridge.
  /// When set, runTurnResolution passes it to resolveTurnForGame.
  GameEventBus? logicEventBus;

  /// Optional strip for session-only observe control overrides before persist.
  Game Function(Game)? prepareGameForPersistence;

  /// Clears map cache and turn-trace sessions. SPEC/program/save-load-session-clear.md.
  void clearSessionCaches() {
    state.mapCache.clear();
    state.turnTraceSessionsByGameId.clear();
  }

  /// Whether [gameId] is present in the in-memory map cache (tests / diagnostics).
  bool hasMapCacheEntry(String gameId) => state.mapCache.containsKey(gameId);

  /// Count of in-memory map-cache entries (tests / diagnostics).
  int get mapCacheEntryCount => state.mapCache.length;

  /// Count of turn-trace sessions (tests / diagnostics).
  int get turnTraceSessionCount => state.turnTraceSessionsByGameId.length;

  /// Cache-only map fingerprint for session-clear isolation tests.
  String? cachedMapContentFingerprint(String gameId) =>
      gameServiceCachedMapContentFingerprint(state.mapCache, gameId);

  /// Seeds a turn-trace session for tests (no export / resolution).
  void debugSeedTurnTraceSession(String gameId) =>
      state.turnTraceSessionsByGameId.putIfAbsent(
        gameId,
        () => TurnTraceSession(startedAtUtc: DateTime.now().toUtc()),
      );

  /// Loads game by id. Returns null if not found or required map data is missing/invalid.
  Game? loadGame(String gameId) => gameServiceLoadGame(this, gameId);

  /// Loads game plus mid-turn draft envelope fields.
  GameSaveSession? loadGameSession(String gameId) =>
      gameServiceLoadGameSession(this, gameId);

  /// Returns map data for [gameId] from cache or storage.
  GameMapData? getMapData(String gameId) => gameServiceGetMapData(this, gameId);

  /// Saves game to storage (empty mid-turn drafts unless [saveGameSession] is used).
  void saveGame(Game game) => gameServiceSaveGame(this, game);

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
  }) => gameServiceSaveGameSession(
    this,
    sessionGame: sessionGame,
    saveGameId: saveGameId,
    draftOrders: draftOrders,
    productionDesiredOutputByRecipe: productionDesiredOutputByRecipe,
    displayName: displayName,
    mirrorAutoSave: mirrorAutoSave,
  );

  /// Lists all saved game ids.
  List<String> listGameIds() => gameServiceListGameIds(this);

  /// Manual saves plus optional auto-save row for the load dialog.
  List<LoadableSaveEntry> listLoadableSaves() =>
      gameServiceListLoadableSaves(this);

  /// Count of manual named saves (auto-save excluded).
  int manualSaveCount() => state.adapter.manualSaveCount(state.box);

  /// Whether a new sanitized manual id may be created (count < [kMaxManualSaves]).
  bool canCreateNewManualSave() =>
      state.adapter.canCreateNewManualSave(state.box);

  /// Deletes a manual save or the auto-save slot (game + map keys).
  void deleteSave(String storageId) {
    state.adapter.delete(state.box, storageId);
    if (storageId != kAutoSaveSlotId) {
      state.mapCache.remove(storageId);
    }
  }

  /// Whether the Hive auto-save slot is playable.
  bool hasValidAutoSave() => gameServiceHasValidAutoSave(this);

  /// Loads the auto-save slot into memory cache under [Game.id].
  Game? loadAutoSaveGame() => gameServiceLoadAutoSaveGame(this);

  /// Loads auto-save with mid-turn draft fields.
  GameSaveSession? loadAutoSaveSession() =>
      gameServiceLoadAutoSaveSession(this);

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
  }) => gameServiceRunTurnResolution(
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
  }) => gameServiceResumeTurnFromDiplomacy(
    this,
    game,
    orders,
    onGameEvent: onGameEvent,
    callToArmsDecisions: decisions,
  );

  /// Resumes after overture accept/reject; may complete or pending. SPEC/program/dialogue-system.md.
  TurnResolutionResult resumeOvertureDecisions(
    Game game,
    List<OvertureOffer> pendingOvertures,
    List<OvertureDecision> decisions,
    Orders orders, {
    void Function(GameEvent)? onGameEvent,
  }) => gameServiceResumeTurnFromDiplomacy(
    this,
    game,
    orders,
    onGameEvent: onGameEvent,
    overtureDecisions: decisions,
  );

  /// Resumes turn resolution after FTP accept/reject decisions (Diplomacy phase).
  TurnResolutionResult resumeFtpDecisions(
    Game game,
    List<FtpOffer> pendingFtpOffers,
    List<FtpDecision> decisions,
    Orders orders, {
    void Function(GameEvent)? onGameEvent,
  }) => gameServiceResumeTurnFromDiplomacy(
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
  }) => gameServiceResumeTurnFromDiplomacy(
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
      gameServiceEmitTurnResolutionEvents(this, result);

  /// Creates a new game via the full game-setup pipeline (map gen, province assignment, capital auto-choice).
  Game createNewGame({String? id, GameSetupConfig? config}) =>
      gameServiceCreateNewGame(this, id: id, config: config);

  /// Same pipeline as [createNewGame], but yields between coarse steps so the UI isolate can paint.
  Future<Game> createNewGameAsync({
    String? id,
    GameSetupConfig? config,
    void Function(int stepIndex, int totalSteps)? onProgress,
  }) => gameServiceCreateNewGameAsync(
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
    if (!state.turnTraceEnabled) {
      return;
    }
    gameServiceExportTurnTrace(
      this,
      gameAtResolutionStart: gameAtResolutionStart,
      turnEndState: turnEndState,
      phases: phases,
      turnStartAt: turnStartAtUtc,
      ai: ai,
    );
  }
}
