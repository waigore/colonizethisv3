// Root ctterm app: navigation shell and main menu. SPEC/tui/ctterm.md.

import 'package:logger/logger.dart' as log_pkg;
import 'package:nocterm/nocterm.dart';

import 'package:ctterm/ctterm_routes.dart';
import 'package:ctterm/screens/lock_prompt_screen.dart';
import 'package:ctterm/screens/shell_screen.dart';
import 'package:ctterm/screens/settings_screen.dart';
import 'package:ctterm/save_service.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

final log_pkg.Logger _log = log_pkg.Logger();

/// Pending setup data when user has completed Game Setup and we are about to generate the world.
class _PendingNewGameConfig {
  const _PendingNewGameConfig({
    required this.orderedGpIdsForSlots,
    required this.leaderVariantByGpId,
  });
  final List<String> orderedGpIdsForSlots;
  final Map<String, String> leaderVariantByGpId;
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
  /// Game events received during turn processing (displayed to user).
  final List<GameEvent> _gameEvents = [];
  /// Current terminal theme.
  TerminalTheme _terminalTheme = TerminalTheme.dark;

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
  void _onPrepareNewGame(List<String> orderedGpIdsForSlots, Map<String, String> leaderVariantByGpId) {
    _log.d('tui:app: prepare new game with ${orderedGpIdsForSlots.length} players');
    setState(() {
      _pendingNewGameConfig = _PendingNewGameConfig(
        orderedGpIdsForSlots: orderedGpIdsForSlots,
        leaderVariantByGpId: leaderVariantByGpId,
      );
      _route = CttermRoute.generatingWorld;
    });
  }

  /// Runs world generation (runInitGame) with pending config, then sets game and navigates to in-game shell.
  /// Called by GeneratingWorldScreen when it mounts. Game is never null after this for a new-game flow.
  void _runGeneration() {
    final pending = _pendingNewGameConfig;
    if (pending == null) {
      _log.w('tui:app: runGeneration called with no pending config');
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
    );
    try {
      _log.i('tui:app: running init game');
      final result = runInitGame(
        config: config,
        options: const InitGameOptions(renderPng: false),
      );
      _log.i('tui:app: init game complete, turn ${result.game.worldState.turnState.turnNumber}');
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
      _log.e('tui:app: init game failed', error: e, stackTrace: st);
      setState(() => _pendingNewGameConfig = null);
      _navigateTo(CttermRoute.mainMenu);
    }
  }

  /// Loads a game by ID and navigates to in-game shell.
  Future<void> _loadGame(String gameId) async {
    _log.d('tui:app: loading game $gameId');
    final game = await loadGame(gameId, component.dataDirOverride);
    if (game == null) {
      _log.e('tui:app: failed to load game $gameId');
      return;
    }
    _log.i('tui:app: loaded game $gameId, turn ${game.worldState.turnState.turnNumber}');
    setState(() {
      _currentGame = game;
      _route = CttermRoute.inGameShell;
    });
  }

  /// Callback when turn is processed, updates game state and clears orders.
  void _onTurnProcessed(Game updatedGame) {
    _log.d('tui:app: turn processed, now turn ${updatedGame.worldState.turnState.turnNumber}');
    setState(() {
      _currentGame = updatedGame;
      _currentOrders = const Orders(); // Clear orders after turn is processed
      // Keep game events for display; clear when returning to main menu
    });
  }

  /// Callback to receive game events (combat, diplomacy, research, victory, etc.).
  void _onGameEvent(GameEvent event) {
    _log.d('tui:event: received ${event.runtimeType}');
    setState(() => _gameEvents.add(event));
  }

  /// Clears game state (e.g., when returning to main menu).
  void _clearGame() {
    _log.d('tui:app: clearing game state');
    setState(() {
      _currentGame = null;
      _currentOrders = const Orders();
      _mapCache = null;
      _pendingNewGameConfig = null;
      _gameEvents.clear();
    });
  }

  /// Updates current orders (e.g., from Units panel).
  void _updateOrders(Orders orders) {
    _log.d('tui:app: orders updated');
    setState(() => _currentOrders = orders);
  }

  void _exit() {
    shutdownApp(0);
  }

  /// Handles theme change from Settings screen.
  void _onThemeChanged(TerminalTheme theme) {
    _log.d('tui:app: theme changed to ${theme.name}');
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
        onGameEvent: _onGameEvent,
        onGameUpdated: (game) {
          _log.d('tui:app: game updated from panel');
          setState(() => _currentGame = game);
        },
        onClearGame: _clearGame,
        onLoadGame: _loadGame,
        initialTheme: _terminalTheme,
        onThemeChanged: _onThemeChanged,
        /// When in Settings, Back goes to Pause if we came from Pause. SPEC/tui/screens/pause-options.md §7.
        settingsReturnRoute: _route == CttermRoute.settings && _previousRoute == CttermRoute.pauseOptions
            ? CttermRoute.pauseOptions
            : null,
      ),
    );
  }
}
