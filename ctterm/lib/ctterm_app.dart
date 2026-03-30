// Root ctterm app: navigation shell and main menu. SPEC/tui/ctterm.md. /// CTTerm application entry point

import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:nocterm/nocterm.dart';

import 'package:ctterm/ctterm_routes.dart';
import 'package:ctterm/screens/lock_prompt_screen.dart';
import 'package:ctterm/screens/shell_screen.dart';
import 'package:ctterm/screens/settings_screen.dart';
import 'package:ctterm/save_service.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

final _log = tuiLogger();

/// Pending setup data when user has completed Game Setup and we are about to generate the world.
class _PendingNewGameConfig {
  const _PendingNewGameConfig({
    required this.orderedGpIdsForSlots,
    required this.leaderVariantByGpId,
    required this.enforceFairGpOldWorldAssignment,
  });
  final List<String> orderedGpIdsForSlots;
  final Map<String, String> leaderVariantByGpId;
  final bool enforceFairGpOldWorldAssignment;
}

/// Map data cached after new game creation for turn resolution (extraction, movement).
class _MapCache {
  const _MapCache({
    required this.combinedTopology,
    required this.tileMapByRegion,
  });
  final MapTopology combinedTopology;
  final Map<String, TileMapResult> tileMapByRegion;
}

/// Root component. Holds current screen and shows Main Menu or a stub.
/// When [initialLockDetected] is true, shows lock-prompt screen first; only deletes lock if user agrees.
class CttermApp extends StatefulComponent {
  const CttermApp({
    super.key,
    this.dataDirOverride,
    this.initialLockDetected = false,
  });

  final String? dataDirOverride;
  final bool initialLockDetected;

  @override
  State<CttermApp> createState() => _CttermAppState();
}

class _CttermAppState extends State<CttermApp> {
  /// True until user resolves the lock prompt (remove+continue or quit).
  bool _showLockPrompt = false;
  CttermRoute _route = CttermRoute.mainMenu;
  /// Previous route (used so Settings Back returns to Pause when opened from Pause). SPEC/tui/screens/pause-options.md §7.
  CttermRoute? _previousRoute;
  Game? _currentGame;
  Orders _currentOrders = const Orders();
  _PendingNewGameConfig? _pendingNewGameConfig;
  _MapCache? _mapCache;
  /// When non-null, turn resolution is suspended; user must accept/reject overtures. SPEC/program/turn-resolution-phases.md.
  List<OvertureOffer>? _pendingOvertures;
  List<CallToArmsPending>? _pendingCallToArms;
  List<InterventionPrompt>? _pendingInterventions;
  /// Game events received during turn processing (displayed to user).
  final List<GameEvent> _gameEvents = [];
  /// Current terminal theme.
  TerminalTheme _terminalTheme = TerminalTheme.dark;
  /// Game ids for which the game-start intro has been shown. SPEC/ai/dialogue-management.md § First dialogue emission point.
  final Set<String> _gameIdsWithIntroShown = {};

  @override
  void initState() {
    super.initState();
    _showLockPrompt = component.initialLockDetected;
  }

  Future<void> _handleLockRemoveAndContinue() async {
    removeStaleLock(component.dataDirOverride);
    await ensureSaveServiceReady(component.dataDirOverride);
    if (mounted) setState(() => _showLockPrompt = false);
  }

  void _navigateTo(CttermRoute route) {
    setState(() {
      _previousRoute = _route;
      _route = route;
    });
  }

  /// Stores setup data and navigates to Generating World. Called from Game Setup when user presses Start.
  void _onPrepareNewGame(
    List<String> orderedGpIdsForSlots,
    Map<String, String> leaderVariantByGpId,
    bool enforceFairGpOldWorldAssignment,
  ) {
    _log.d('prepare new game with ${orderedGpIdsForSlots.length} players');
    setState(() {
      _pendingNewGameConfig = _PendingNewGameConfig(
        orderedGpIdsForSlots: orderedGpIdsForSlots,
        leaderVariantByGpId: leaderVariantByGpId,
        enforceFairGpOldWorldAssignment: enforceFairGpOldWorldAssignment,
      );
      _route = CttermRoute.generatingWorld;
    });
  }

  /// Runs world generation (runInitGame) with pending config, then sets game and navigates to in-game shell.
  /// Called by GeneratingWorldScreen when it mounts. Game is never null after this for a new-game flow.
  void _runGeneration() {
    final pending = _pendingNewGameConfig;
    if (pending == null) {
      _log.w('runGeneration called with no pending config');
      return;
    }
    final config = GameSetupConfig(
      selectedGreatPowerIds: List<String>.from(pending.orderedGpIdsForSlots),
      leaderVariantByGpId: Map<String, String>.from(pending.leaderVariantByGpId),
      seed: GameSetupConfig.defaultConfig.seed,
      continentCount: GameSetupConfig.defaultConfig.continentCount,
      minorNationCount: GameSetupConfig.defaultConfig.minorNationCount,
      tribeCount: GameSetupConfig.defaultConfig.tribeCount,
      numProvincesOldWorld: GameSetupConfig.defaultConfig.numProvincesOldWorld,
      numProvincesNewWorld: GameSetupConfig.defaultConfig.numProvincesNewWorld,
      minProvincesPerMinor: GameSetupConfig.defaultConfig.minProvincesPerMinor,
      enforceFairGpOldWorldAssignment: pending.enforceFairGpOldWorldAssignment,
    );
    try {
      _log.i('running init game');
      final result = runInitGame(
        config: config,
        options: const InitGameOptions(renderPng: false),
      );
      _log.i('init game complete, turn ${result.game.worldState.turnState.turnNumber}');
      // Set game and route in one setState so no rebuild can see inGameShell with null game.
      setState(() {
        _currentGame = result.game;
        _mapCache = _MapCache(
          combinedTopology: result.combinedTopology,
          tileMapByRegion: result.tileMapByRegion,
        );
        _pendingNewGameConfig = null;
        _route = CttermRoute.inGameShell;
      });
    } catch (e, st) {
      _log.e('init game failed', error: e, stackTrace: st);
      setState(() => _pendingNewGameConfig = null);
      _navigateTo(CttermRoute.mainMenu);
    }
  }

  /// Loads a game by ID and navigates to in-game shell.
  Future<void> _loadGame(String gameId) async {
    _log.d('loading game $gameId');
    final game = await loadGame(gameId, component.dataDirOverride);
    if (game == null) {
      _log.e('failed to load game $gameId');
      return;
    }
    _log.i('loaded game $gameId, turn ${game.worldState.turnState.turnNumber}');
    setState(() {
      _currentGame = game;
      _route = CttermRoute.inGameShell;
    });
  }

  /// Callback when turn is processed, updates game state and clears orders.
  void _onTurnProcessed(Game updatedGame) {
    _log.d('turn processed, now turn ${updatedGame.worldState.turnState.turnNumber}');
    setState(() {
      _currentGame = updatedGame;
      _currentOrders = const Orders(); // Clear orders after turn is processed
      // Keep game events for display; clear when returning to main menu
    });
  }

  /// Callback to receive game events (combat, diplomacy, research, victory, etc.).
  void _onGameEvent(GameEvent event) {
    _log.d('received ${event.runtimeType}');
    setState(() => _gameEvents.add(event));
  }

  /// Clears game state (e.g., when returning to main menu).
  void _clearGame() {
    _log.d('clearing game state');
    setState(() {
      _currentGame = null;
      _currentOrders = const Orders();
      _mapCache = null;
      _pendingNewGameConfig = null;
      _pendingOvertures = null;
      _pendingCallToArms = null;
      _pendingInterventions = null;
      _gameEvents.clear();
    });
  }

  /// Called when turn resolution returns pending overtures; navigate to pending overtures screen.
  void _onTurnResolutionPending(Game game, List<OvertureOffer> pending) {
    _log.d('turn resolution pending ${pending.length} overture(s)');
    setState(() {
      _currentGame = game;
      _pendingOvertures = pending;
      _pendingCallToArms = null;
      _pendingInterventions = null;
      _route = CttermRoute.pendingOvertures;
    });
  }

  void _onTurnResolutionPendingIntervention(
    Game game,
    List<InterventionPrompt> pending,
  ) {
    _log.d('turn resolution pending ${pending.length} intervention(s)');
    setState(() {
      _currentGame = game;
      _pendingInterventions = pending;
      _pendingOvertures = null;
      _pendingCallToArms = null;
      _route = CttermRoute.pendingIntervention;
    });
  }

  void _onTurnResolutionPendingCallToArms(
    Game game,
    List<CallToArmsPending> pending,
  ) {
    _log.d('turn resolution pending ${pending.length} call(s) to arms');
    setState(() {
      _currentGame = game;
      _pendingCallToArms = pending;
      _pendingOvertures = null;
      _pendingInterventions = null;
      _route = CttermRoute.pendingCallToArms;
    });
  }

  /// Called when user submits accept/reject decisions; resume turn resolution.
  void _onOvertureDecisions(List<OvertureDecision> decisions) {
    final game = _currentGame;
    final pending = _pendingOvertures;
    final mapCache = _mapCache;
    if (game == null || pending == null || mapCache == null) {
      _log.w('onOvertureDecisions with null game/pending/mapCache');
      return;
    }
    final result = resumeTurnResolutionWithOvertureDecisions(
      game: game,
      pendingOvertures: pending,
      decisions: decisions,
      topology: mapCache.combinedTopology,
      orders: _currentOrders,
      tileMapByRegion: mapCache.tileMapByRegion,
      onGameEvent: _onGameEvent,
    );
    if (result is TurnResolutionComplete) {
      _log.d('turn resolution complete after overture decisions');
      setState(() {
        _currentGame = result.game;
        _pendingOvertures = null;
        _pendingCallToArms = null;
        _pendingInterventions = null;
        _route = CttermRoute.inGameShell;
      });
      _onTurnProcessed(result.game);
    } else if (result is TurnResolutionPendingOvertures) {
      _log.d('turn resolution still pending ${result.pendingOvertures.length} overture(s)');
      setState(() {
        _currentGame = result.game;
        _pendingOvertures = result.pendingOvertures;
        _pendingCallToArms = null;
        _pendingInterventions = null;
      });
    } else if (result is TurnResolutionPendingIntervention) {
      _log.d(
        'after overtures, pending ${result.pendingInterventions.length} intervention(s)',
      );
      setState(() {
        _currentGame = result.game;
        _pendingOvertures = null;
        _pendingCallToArms = null;
        _pendingInterventions = result.pendingInterventions;
        _route = CttermRoute.pendingIntervention;
      });
    } else if (result is TurnResolutionPendingCallToArms) {
      _log.d(
        'after overtures, pending ${result.pendingCallToArms.length} call(s) to arms',
      );
      setState(() {
        _currentGame = result.game;
        _pendingOvertures = null;
        _pendingInterventions = null;
        _pendingCallToArms = result.pendingCallToArms;
        _route = CttermRoute.pendingCallToArms;
      });
    }
  }

  void _onInterventionDecisions(List<InterventionDecision> decisions) {
    final game = _currentGame;
    final mapCache = _mapCache;
    if (game == null || mapCache == null) {
      _log.w('onInterventionDecisions with null game/mapCache');
      return;
    }
    final result = resumeTurnResolutionWithInterventionDecisions(
      game: game,
      decisions: decisions,
      topology: mapCache.combinedTopology,
      orders: _currentOrders,
      tileMapByRegion: mapCache.tileMapByRegion,
      onGameEvent: _onGameEvent,
    );
    if (result is TurnResolutionComplete) {
      _log.d('turn resolution complete after intervention');
      setState(() {
        _currentGame = result.game;
        _pendingInterventions = null;
        _pendingOvertures = null;
        _pendingCallToArms = null;
        _route = CttermRoute.inGameShell;
      });
      _onTurnProcessed(result.game);
    } else if (result is TurnResolutionPendingOvertures) {
      setState(() {
        _currentGame = result.game;
        _pendingInterventions = null;
        _pendingCallToArms = null;
        _pendingOvertures = result.pendingOvertures;
        _route = CttermRoute.pendingOvertures;
      });
    } else if (result is TurnResolutionPendingIntervention) {
      setState(() {
        _currentGame = result.game;
        _pendingOvertures = null;
        _pendingCallToArms = null;
        _pendingInterventions = result.pendingInterventions;
      });
    } else if (result is TurnResolutionPendingCallToArms) {
      setState(() {
        _currentGame = result.game;
        _pendingInterventions = null;
        _pendingOvertures = null;
        _pendingCallToArms = result.pendingCallToArms;
        _route = CttermRoute.pendingCallToArms;
      });
    }
  }

  void _onCallToArmsDecisions(List<CallToArmsDecision> decisions) {
    final game = _currentGame;
    final mapCache = _mapCache;
    if (game == null || mapCache == null) {
      _log.w('onCallToArmsDecisions with null game/mapCache');
      return;
    }
    final result = resumeTurnResolutionWithCallToArmsDecisions(
      game: game,
      decisions: decisions,
      topology: mapCache.combinedTopology,
      orders: _currentOrders,
      tileMapByRegion: mapCache.tileMapByRegion,
      onGameEvent: _onGameEvent,
    );
    if (result is TurnResolutionComplete) {
      _log.d('turn resolution complete after call to arms');
      setState(() {
        _currentGame = result.game;
        _pendingCallToArms = null;
        _pendingOvertures = null;
        _pendingInterventions = null;
        _route = CttermRoute.inGameShell;
      });
      _onTurnProcessed(result.game);
    } else if (result is TurnResolutionPendingOvertures) {
      setState(() {
        _currentGame = result.game;
        _pendingCallToArms = null;
        _pendingInterventions = null;
        _pendingOvertures = result.pendingOvertures;
        _route = CttermRoute.pendingOvertures;
      });
    } else if (result is TurnResolutionPendingIntervention) {
      setState(() {
        _currentGame = result.game;
        _pendingCallToArms = null;
        _pendingOvertures = null;
        _pendingInterventions = result.pendingInterventions;
        _route = CttermRoute.pendingIntervention;
      });
    } else if (result is TurnResolutionPendingCallToArms) {
      setState(() {
        _currentGame = result.game;
        _pendingInterventions = null;
        _pendingOvertures = null;
        _pendingCallToArms = result.pendingCallToArms;
      });
    }
  }

  /// Updates current orders (e.g., from Units panel).
  void _updateOrders(Orders orders) {
    _log.d('orders updated');
    setState(() => _currentOrders = orders);
  }

  /// Clears in-progress work for a unit (Development screen cancel). SPEC/tui/screens/development.md § Cancel Work Order.
  void _cancelUnitWork(String unitId) {
    final game = _currentGame;
    if (game == null) return;
    final ws = game.worldState;
    Unit? found;
    String? region;
    for (final u in ws.oldWorld.units) {
      if (u.id == unitId) {
        found = u;
        region = 'oldWorld';
        break;
      }
    }
    if (found == null) {
      for (final u in ws.newWorld.units) {
        if (u.id == unitId) {
          found = u;
          region = 'newWorld';
          break;
        }
      }
    }
    if (found == null || found.currentWork == null) return;
    final updated = found.copyWith(
      clearCurrentWork: true,
      status: UnitStatus.idle,
    );
    final newUnits = region == 'oldWorld'
        ? ws.oldWorld.units
            .map((u) => u.id == unitId ? updated : u)
            .toList()
        : ws.oldWorld.units;
    final newWorldUnits = region == 'newWorld'
        ? ws.newWorld.units
            .map((u) => u.id == unitId ? updated : u)
            .toList()
        : ws.newWorld.units;
    final newRegion = region == 'oldWorld'
        ? RegionData(provinces: ws.oldWorld.provinces, units: newUnits)
        : ws.oldWorld;
    final newNwRegion = region == 'newWorld'
        ? RegionData(provinces: ws.newWorld.provinces, units: newWorldUnits)
        : ws.newWorld;
    final newGame = game.copyWith(
      worldState: ws.copyWith(oldWorld: newRegion, newWorld: newNwRegion),
    );
    _log.d('cancelled in-progress work for unit $unitId');
    setState(() => _currentGame = newGame);
  }

  void _exit() {
    shutdownApp(0);
  }

  /// Handles theme change from Settings screen.
  void _onThemeChanged(TerminalTheme theme) {
    _log.d('theme changed to ${theme.name}');
    setState(() => _terminalTheme = theme);
  }

  /// Converts TerminalTheme to Nocterm TuiThemeData.
  TuiThemeData get _themeData {
    switch (_terminalTheme) {
      case TerminalTheme.light:
        return TuiThemeData.light;
      case TerminalTheme.dark:
        return TuiThemeData.dark;
    }
  }

  @override
  Component build(BuildContext context) {
    if (_showLockPrompt) {
      return NoctermApp(
        title: 'ColonizeThis',
        theme: _themeData,
        child: LockPromptScreen(
          onRemoveAndContinue: _handleLockRemoveAndContinue,
          onQuit: _exit,
        ),
      );
    }
    return NoctermApp(
      title: 'ColonizeThis',
      theme: _themeData,
      child: ShellScreen(
        route: _route,
        dataDirOverride: component.dataDirOverride,
        game: _currentGame,
        orders: _currentOrders,
        gameEvents: _gameEvents,
        combinedTopology: _mapCache?.combinedTopology,
        tileMapByRegion: _mapCache?.tileMapByRegion,
        onNavigate: _navigateTo,
        onExit: _exit,
        onPrepareNewGame: _onPrepareNewGame,
        runGeneration: _route == CttermRoute.generatingWorld ? _runGeneration : null,
        onTurnProcessed: _onTurnProcessed,
        onOrdersChanged: _updateOrders,
        onCancelUnitWork: _cancelUnitWork,
        onGameEvent: _onGameEvent,
        onGameUpdated: (game) {
          _log.d('game updated from panel');
          setState(() => _currentGame = game);
        },
        onClearGame: _clearGame,
        onLoadGame: _loadGame,
        pendingOvertures: _pendingOvertures,
        pendingCallToArms: _pendingCallToArms,
        pendingInterventions: _pendingInterventions,
        onTurnResolutionPending: _onTurnResolutionPending,
        onTurnResolutionPendingCallToArms: _onTurnResolutionPendingCallToArms,
        onTurnResolutionPendingIntervention: _onTurnResolutionPendingIntervention,
        onOvertureDecisions: _onOvertureDecisions,
        onCallToArmsDecisions: _onCallToArmsDecisions,
        onInterventionDecisions: _onInterventionDecisions,
        initialTheme: _terminalTheme,
        onThemeChanged: _onThemeChanged,
        /// When in Settings, Back goes to Pause if we came from Pause. SPEC/tui/screens/pause-options.md §7.
        settingsReturnRoute: _route == CttermRoute.settings && _previousRoute == CttermRoute.pauseOptions
            ? CttermRoute.pauseOptions
            : null,
        /// When in Debug log viewer, Back goes to Pause or Main Menu. SPEC/program/debug-log-viewer.md.
        debugLogViewerReturnRoute: _route == CttermRoute.debugLogViewer
            ? _previousRoute
            : null,
        showGameStartIntro: _currentGame != null &&
            _route == CttermRoute.inGameShell &&
            !_gameIdsWithIntroShown.contains(_currentGame!.id),
        onIntroDismissed: () {
          if (_currentGame != null) {
            setState(() => _gameIdsWithIntroShown.add(_currentGame!.id));
          }
        },
      ),
    );
  }
}
