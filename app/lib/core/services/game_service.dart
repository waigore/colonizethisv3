import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app/package_logger.dart';
import 'package:colonizethis_app/perf/app_perf_trace.dart';
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

/// Pass milestones for in-app tile map generation (SPEC/program/logging/map-generation.md).
final _mapGenPassLog = packageLogger('tile_map');
const int _kLockedGreatPowerCount = 6;
const int _kLockedMinorNationCount = 6;
const int _kLockedOldWorldProvinceCount = 60;
const int _kLockedOldWorldContinentCount = 3;
const int _kLockedOldWorldRetryCount = 5;
const List<int> _kLockedOldWorldPartition = [18, 21, 21];

/// Loads/saves games and advances turn. SPEC/project/phase-1: app invokes TurnResolver and persists via colonizethis_save.
/// Phase 2: createNewGame uses full game-setup pipeline; nextTurn requires cached/persisted map data.
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

  /// Saves game to storage.
  void saveGame(Game game) => _adapter.save(_box, game);

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
    final result = resolveTurnForGame(
      game: current,
      topology: topo,
      orders: resolvedOrders,
      tileMapByRegion: tileMaps,
      eventBus: logicEventBus,
      onGameEvent: onGameEvent,
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
    final result = resumeTurnResolutionWithCallToArmsDecisions(
      game: game,
      decisions: decisions,
      topology: topo,
      orders: orders,
      tileMapByRegion: tileMaps,
      eventBus: logicEventBus,
      onGameEvent: onGameEvent,
    );
    _emitTurnResolutionEvents(result);
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
    final mapData = _requiredMapDataView(game.id);
    final topo = mapData.combinedTopology;
    final tileMaps = mapData.tileMapByRegion;
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
    final result = resumeTurnResolutionWithInterventionDecisions(
      game: game,
      decisions: decisions,
      topology: topo,
      orders: orders,
      tileMapByRegion: tileMaps,
      eventBus: logicEventBus,
      onGameEvent: onGameEvent,
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

  /// Number of coarse progress steps reported by [createNewGameAsync]. SPEC/ui/game-initializing.md.
  static const int newGameSetupProgressStepCount = 5;

  /// Creates a new game via the full game-setup pipeline (map gen, province assignment, capital auto-choice).
  /// Uses [config] (defaults to GameSetupConfig.defaultConfig) and saves the game; map data is cached for nextTurn.
  Game createNewGame({String? id, GameSetupConfig? config}) {
    final gameId = id ?? 'game_${DateTime.now().millisecondsSinceEpoch}';
    final cfg = _withLockedOldWorldConfig(
      config ?? GameSetupConfig.defaultConfig,
    );
    final effectiveSeed = resolveEffectiveSetupSeed(cfg.seed);
    final (tileMapOW, topoOW) = _generateTileMapOldWorld(cfg, effectiveSeed);
    final (tileMapNW, topoNW) = _generateTileMapNewWorld(cfg, effectiveSeed);
    final warpLinks = _generateWarpLinks(
      effectiveSeed: effectiveSeed,
      tileMapOW: tileMapOW,
      topoOW: topoOW,
      tileMapNW: tileMapNW,
      topoNW: topoNW,
    );
    final setupResult = createGameFromGeneratedMaps(
      config: cfg,
      tileMapOldWorld: tileMapOW,
      topologyOldWorld: topoOW,
      tileMapNewWorld: tileMapNW,
      topologyNewWorld: topoNW,
      gameId: gameId,
      namingSeed: effectiveSeed,
      assignmentPerturbationBase: effectiveSeed,
      warpLinks: warpLinks,
    );
    final result = _setupResultWithFinalizedGame(setupResult, effectiveSeed);
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
    final cfg = _withLockedOldWorldConfig(
      config ?? GameSetupConfig.defaultConfig,
    );
    final effectiveSeed = resolveEffectiveSetupSeed(cfg.seed);
    const total = newGameSetupProgressStepCount;
    final log = packageLogger();
    Future<void> yieldUi() => Future<void>.delayed(Duration.zero);

    // Let any pending frame (e.g. progress modal paint) run before step 0 work.
    await yieldUi();

    void reportPhase(int stepIndex) {
      ctAppPerfInstant('newGameAsync.phase_$stepIndex');
      log.i('newGameAsync phase step=$stepIndex total=$total gameId=$gameId');
      onProgress?.call(stepIndex, total);
    }

    ctAppPerfInstant('newGameAsync.begin');
    log.i('newGameAsync begin gameId=$gameId');

    reportPhase(0);
    await yieldUi();
    final (tileMapOW, topoOW) = _generateTileMapOldWorld(cfg, effectiveSeed);

    reportPhase(1);
    await yieldUi();
    final (tileMapNW, topoNW) = _generateTileMapNewWorld(cfg, effectiveSeed);

    reportPhase(2);
    await yieldUi();
    final warpLinks = _generateWarpLinks(
      effectiveSeed: effectiveSeed,
      tileMapOW: tileMapOW,
      topoOW: topoOW,
      tileMapNW: tileMapNW,
      topoNW: topoNW,
    );

    reportPhase(3);
    await yieldUi();
    final setupResult = createGameFromGeneratedMaps(
      config: cfg,
      tileMapOldWorld: tileMapOW,
      topologyOldWorld: topoOW,
      tileMapNewWorld: tileMapNW,
      topologyNewWorld: topoNW,
      gameId: gameId,
      namingSeed: effectiveSeed,
      assignmentPerturbationBase: effectiveSeed,
      warpLinks: warpLinks,
    );
    final result = _setupResultWithFinalizedGame(setupResult, effectiveSeed);

    reportPhase(4);
    await yieldUi();
    _persistNewGame(gameId: gameId, result: result);
    ctAppPerfInstant('newGameAsync.complete');
    log.i('newGameAsync complete gameId=$gameId');
    return result.game;
  }

  GameSetupResult _setupResultWithFinalizedGame(
    GameSetupResult setup,
    int effectiveSeed,
  ) {
    var game = setup.game.copyWith(
      globalGameSeed: effectiveSeed,
      aiSeedByGpId: {
        for (final p in setup.game.players) p.id: effectiveSeed + p.id.hashCode,
      },
    );
    game = assignHiddenAgendasForGame(game);
    return GameSetupResult(
      game: game,
      tileMapByRegion: setup.tileMapByRegion,
      topologyByRegion: setup.topologyByRegion,
      combinedTopology: setup.combinedTopology,
      warpLinks: setup.warpLinks,
    );
  }

  (TileMapResult, MapTopology) _generateTileMapOldWorld(
    GameSetupConfig cfg,
    int effectiveSeed,
  ) {
    for (var attempt = 0; attempt <= _kLockedOldWorldRetryCount; attempt++) {
      final attemptSeed = effectiveSeed + attempt;
      final mapGenParams = MapGenerationParams(
        numContinents: _kLockedOldWorldContinentCount,
        seed: attemptSeed,
        seaFraction: kDefaultSeaFraction,
      );
      final sizeOW = computeGridSizeFromParams(
        _kLockedOldWorldProvinceCount,
        mapGenParams,
      );
      final paramsOW = TileMapParams(
        width: sizeOW.width,
        height: sizeOW.height,
        seed: attemptSeed,
        seaFraction: kDefaultSeaFraction,
      );
      final generated = TileMapGenerator(params: paramsOW).generate(
        numProvinces: _kLockedOldWorldProvinceCount,
        numContinents: _kLockedOldWorldContinentCount,
        regionId: 'oldWorld',
        resourceRules: ResourceRules.defaultRules,
        onLog: _mapGenPassLog.d,
      );
      if (_matchesLockedOldWorldPartition(generated.$2)) {
        return generated;
      }
    }
    throw SetupTopologyDataException(
      code: 'old_world_partition_retry_exhausted',
      details:
          'Old World generation could not satisfy continent partition 21/21/18 in ${_kLockedOldWorldRetryCount + 1} deterministic attempt(s).',
    );
  }

  (TileMapResult, MapTopology) _generateTileMapNewWorld(
    GameSetupConfig cfg,
    int effectiveSeed,
  ) {
    final mapGenParams = MapGenerationParams(
      numContinents: cfg.continentCount,
      seed: effectiveSeed,
      seaFraction: kDefaultSeaFraction,
    );
    final sizeNW = computeGridSizeFromParams(
      cfg.numProvincesNewWorld,
      mapGenParams,
    );
    final paramsNW = TileMapParams(
      width: sizeNW.width,
      height: sizeNW.height,
      seed: effectiveSeed + 1,
      seaFraction: kDefaultSeaFraction,
    );
    return TileMapGenerator(params: paramsNW).generate(
      numProvinces: cfg.numProvincesNewWorld,
      numContinents: cfg.continentCount.clamp(1, cfg.numProvincesNewWorld),
      regionId: 'newWorld',
      resourceRules: ResourceRules.defaultRules,
      onLog: _mapGenPassLog.d,
    );
  }

  List<WarpLink> _generateWarpLinks({
    required int effectiveSeed,
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
      seed: effectiveSeed,
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
    _mirrorAutoSave(result.game);
    eventBus?.emit(NewGameCreatedEvent(gameId: result.game.id));
  }

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
    } else if (result is TurnResolutionPendingOvertures) {
      eventBus?.emit(OvertureRequiredEvent(overtures: result.pendingOvertures));
    } else if (result is TurnResolutionPendingIntervention) {
      eventBus?.emit(
        InterventionRequiredEvent(prompts: result.pendingInterventions),
      );
    } else if (result is TurnResolutionPendingCallToArms) {
      eventBus?.emit(
        CallToArmsRequiredEvent(pending: result.pendingCallToArms),
      );
    }
  }
}

GameSetupConfig _withLockedOldWorldConfig(GameSetupConfig config) {
  final selectedIds =
      config.selectedGreatPowerIds.length == _kLockedGreatPowerCount
      ? config.selectedGreatPowerIds
      : GameSetupConfig.defaultConfig.selectedGreatPowerIds
            .take(_kLockedGreatPowerCount)
            .toList();
  return GameSetupConfig(
    selectedGreatPowerIds: selectedIds,
    leaderVariantByGpId: config.leaderVariantByGpId,
    continentCount: _kLockedOldWorldContinentCount,
    minorNationCount: _kLockedMinorNationCount,
    tribeCount: config.tribeCount,
    numProvincesOldWorld: _kLockedOldWorldProvinceCount,
    numProvincesNewWorld: config.numProvincesNewWorld,
    minProvincesPerMinor: 3,
    seed: config.seed,
    startingResources: config.startingResources,
    enforceFairGpOldWorldAssignment: config.enforceFairGpOldWorldAssignment,
    preferredInitialMapZoomMultiplier: config.preferredInitialMapZoomMultiplier,
    initTownRoadWiringRegionIds: config.initTownRoadWiringRegionIds,
  );
}

bool _matchesLockedOldWorldPartition(MapTopology topology) {
  final provinceIds = <String>{
    for (final node in topology.nodes)
      if (node.type == TopologyNodeType.province) node.id,
  };
  final neighbours = <String, Set<String>>{
    for (final id in provinceIds) id: <String>{},
  };
  for (final edge in topology.edges) {
    if (!provinceIds.contains(edge.id1) || !provinceIds.contains(edge.id2)) {
      continue;
    }
    neighbours[edge.id1]!.add(edge.id2);
    neighbours[edge.id2]!.add(edge.id1);
  }
  final sizes = <int>[];
  final seen = <String>{};
  final idsSorted = provinceIds.toList()..sort();
  for (final id in idsSorted) {
    if (!seen.add(id)) continue;
    sizes.add(
      _lockedOwConnectedComponentSize(
        startId: id,
        neighbours: neighbours,
        seen: seen,
      ),
    );
  }
  sizes.sort();
  return sizes.length == _kLockedOldWorldPartition.length &&
      sizes[0] == _kLockedOldWorldPartition[0] &&
      sizes[1] == _kLockedOldWorldPartition[1] &&
      sizes[2] == _kLockedOldWorldPartition[2];
}

int _lockedOwConnectedComponentSize({
  required String startId,
  required Map<String, Set<String>> neighbours,
  required Set<String> seen,
}) {
  var size = 0;
  final stack = <String>[startId];
  while (stack.isNotEmpty) {
    final current = stack.removeLast();
    size++;
    for (final neighbour in neighbours[current] ?? const <String>{}) {
      if (!seen.add(neighbour)) continue;
      stack.add(neighbour);
    }
  }
  return size;
}
