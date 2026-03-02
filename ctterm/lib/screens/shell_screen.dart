// Navigation shell: switches on route and shows Main Menu or stub. SPEC/tui/ctterm.md.

import 'package:logger/logger.dart' as log_pkg;
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:ctterm/ctterm_routes.dart';
import 'package:ctterm/screens/defeat_screen.dart';
import 'package:ctterm/screens/game_setup_screen.dart';
import 'package:ctterm/screens/generating_world_screen.dart';
import 'package:ctterm/screens/in_game_shell_screen.dart';
import 'package:ctterm/screens/load_game_screen.dart';
import 'package:ctterm/screens/main_menu_screen.dart';
import 'package:ctterm/screens/map_context_screen.dart';
import 'package:ctterm/screens/settings_screen.dart';
import 'package:ctterm/screens/victory_progress_screen.dart';
import 'package:ctterm/screens/units_screen.dart';
import 'package:ctterm/screens/development_screen.dart';
import 'package:ctterm/screens/production_screen.dart';
import 'package:ctterm/screens/academy_screen.dart';
import 'package:ctterm/screens/shipyard_screen.dart';
import 'package:ctterm/screens/victory_screen.dart';
import 'package:ctterm/screens/diplomacy_screen.dart';
import 'package:ctterm/screens/technology_screen.dart';
import 'package:ctterm/screens/pause_options_screen.dart';
import 'package:ctterm/save_service.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

final log_pkg.Logger _log = log_pkg.Logger();

/// Displays the current route (Main Menu or a stub) and handles back/exit.
class ShellScreen extends StatefulComponent {
  const ShellScreen({
    super.key,
    required this.route,
    required this.onNavigate,
    required this.onExit,
    this.dataDirOverride,
    this.game,
    this.orders,
    this.gameEvents,
    this.combinedTopology,
    this.tileMapByRegion,
    this.onPrepareNewGame,
    this.runGeneration,
    this.onTurnProcessed,
    this.onOrdersChanged,
    this.onGameEvent,
    this.onGameUpdated,
    this.onClearGame,
    this.onLoadGame,
    this.initialTheme,
    this.onThemeChanged,
  });

  final CttermRoute route;
  final String? dataDirOverride;
  /// Current game state. Set when loading or starting a game.
  final Game? game;
  /// Current orders for the human player.
  final Orders? orders;
  /// Topology and tile maps for turn resolution (set after new game creation).
  final MapTopology? combinedTopology;
  final Map<String, TileMapResult>? tileMapByRegion;
  final void Function(CttermRoute) onNavigate;
  final void Function() onExit;
  /// Called with setup data before navigating to Generating World. When set, Game Setup uses it.
  final void Function(List<String> orderedGpIdsForSlots, Map<String, String> leaderVariantByGpId)? onPrepareNewGame;
  /// When set, Generating World screen runs this instead of simulated progress (runs real init then navigates).
  final void Function()? runGeneration;
  /// Callback when turn is processed, receives updated game state.
  final void Function(Game)? onTurnProcessed;
  /// Callback when orders are changed in a panel.
  final void Function(Orders)? onOrdersChanged;
  /// Game events to display to the user (from turn processing).
  final List<GameEvent>? gameEvents;
  /// Callback to receive game events (combat, diplomacy, research, victory, etc.).
  final void Function(GameEvent)? onGameEvent;
  /// Callback when game state is updated (e.g., orders changed in a panel).
  final void Function(Game)? onGameUpdated;
  /// Callback to clear game state (e.g., when returning to main menu).
  final void Function()? onClearGame;
  /// Callback to load a game by ID.
  final Future<void> Function(String gameId)? onLoadGame;
  /// Initial terminal theme for settings screen.
  final TerminalTheme? initialTheme;
  /// Callback when theme is changed in settings.
  final void Function(TerminalTheme)? onThemeChanged;

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  /// Triggered when victory condition is met (human wins).
  /// Uses game.victory data if available, otherwise falls back to defaults.
  void _triggerVictory() {
    final game = component.game;
    final turn = game?.victory?.turnNumber ?? 1;
    _log.d('tui:game: victory triggered, turn $turn');
    component.onNavigate(CttermRoute.victory);
  }

  /// Triggered when another player wins (human loses).
  /// Uses game.victory data if available, otherwise falls back to defaults.
  void _triggerDefeat() {
    final game = component.game;
    final turn = game?.victory?.turnNumber ?? 1;
    final winnerId = game?.victory?.winnerPlayerId;
    _log.d('tui:game: defeat triggered, turn $turn, winner=$winnerId');
    component.onNavigate(CttermRoute.defeat);
  }

  @override
  Component build(BuildContext context) {
    return KeyboardListener(
      onKeyEvent: (LogicalKey key) {
        if (key == LogicalKey.escape) {
          // Let in-game routes handle their own escape (pause menu, etc.)
          // Only handle escape at shell level for routes outside game flow
          if (component.route == CttermRoute.mainMenu ||
              component.route == CttermRoute.gameSetup ||
              component.route == CttermRoute.loadGame ||
              component.route == CttermRoute.settings ||
              component.route == CttermRoute.generatingWorld) {
            _log.d('tui:nav: Esc -> main menu');
            component.onNavigate(CttermRoute.mainMenu);
            return true;
          }
          // For in-game routes, let them handle escape themselves
          return false;
        }
        return false;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildScreenIdBar(),
          Expanded(child: _buildScreen()),
        ],
      ),
    );
  }

  /// Top bar showing unique 6-digit screen ID for easy identification. SPEC/tui/ctterm.md § Screen IDs.
  Component _buildScreenIdBar() {
    final id = component.route.screenId;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      color: Colors.grey,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Screen $id',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.cyan,
            ),
          ),
        ],
      ),
    );
  }

  Component _buildScreen() {
    switch (component.route) {
      case CttermRoute.mainMenu:
        return MainMenuScreen(
          dataDirOverride: component.dataDirOverride,
          onNewGame: () => component.onNavigate(CttermRoute.gameSetup),
          onLoadGame: () => component.onNavigate(CttermRoute.loadGame),
          onSettings: () => component.onNavigate(CttermRoute.settings),
          onQuit: component.onExit,
        );
      case CttermRoute.gameSetup:
        return GameSetupScreen(
          onStartGame: (orderedGpIdsForSlots, leaderVariantByGpId) {
            _log.d('tui:nav: Game Setup complete -> generating world');
            component.onPrepareNewGame?.call(orderedGpIdsForSlots, leaderVariantByGpId);
            // App's onPrepareNewGame sets route to generatingWorld; no separate navigate needed.
          },
          onBack: () => component.onNavigate(CttermRoute.mainMenu),
        );
      case CttermRoute.loadGame:
        return LoadGameScreen(
          dataDirOverride: component.dataDirOverride,
          onLoad: (gameId) async {
            _log.d('tui:nav: Load gameId=$gameId');
            // Use the app's loadGame callback to load and navigate
            await component.onLoadGame?.call(gameId);
          },
          onDelete: (gameId) async {
            _log.i('tui:save: deleting gameId=$gameId');
            // Import is already at top, just use deleteSave
            await deleteSave(gameId, component.dataDirOverride);
          },
          onBack: () => component.onNavigate(CttermRoute.mainMenu),
        );
      case CttermRoute.generatingWorld:
        return GeneratingWorldScreen(
          onComplete: () => component.onNavigate(CttermRoute.inGameShell),
          onCancel: () => component.onNavigate(CttermRoute.mainMenu),
          runGeneration: component.runGeneration,
        );
      case CttermRoute.settings:
        return SettingsScreen(
          onBack: () => component.onNavigate(CttermRoute.mainMenu),
          initialTheme: component.initialTheme,
          onThemeChanged: component.onThemeChanged,
        );
      case CttermRoute.inGameShell:
        return InGameShellScreen(
          game: component.game,
          gameEvents: component.gameEvents,
          onNavigate: component.onNavigate,
          onEndTurn: () async {
            final game = component.game;
            if (game == null) {
              _log.w('tui:game: no game to process turn');
              return;
            }
            _log.d('tui:game: processing turn ${game.worldState.turnState.turnNumber}');
            
            // Process turn with current orders and minimal topology
            // Full implementation would load map data and use real topology
            final currentOrders = component.orders ?? const Orders();
            final topology = component.combinedTopology ?? const MapTopology();
            final tileMapByRegion = component.tileMapByRegion;
            final nextGame = resolveTurnForGame(
              game: game,
              topology: topology,
              orders: currentOrders,
              tileMapByRegion: tileMapByRegion,
              onGameEvent: component.onGameEvent,
            );
            
            // Notify parent of updated game state
            component.onTurnProcessed?.call(nextGame);
            _log.i('tui:game: turn processed, now turn ${nextGame.worldState.turnState.turnNumber}');
          },
          onVictory: _triggerVictory,
          onDefeat: _triggerDefeat,
          onExitToMainMenu: () {
            _log.d('tui:nav: exit to main menu');
            component.onClearGame?.call();
            component.onNavigate(CttermRoute.mainMenu);
          },
        );
      case CttermRoute.mapContext:
        return MapContextScreen(
          game: component.game!,
          onNavigate: component.onNavigate,
        );
      case CttermRoute.units:
        return UnitsScreen(
          game: component.game!,
          orders: component.orders ?? const Orders(),
          onNavigate: component.onNavigate,
          onOrdersChanged: (Orders orders) {
            component.onOrdersChanged?.call(orders);
          },
        );
      case CttermRoute.development:
        return DevelopmentScreen(
          game: component.game!,
          orders: component.orders ?? const Orders(),
          onNavigate: component.onNavigate,
          onOrdersChanged: (Orders orders) {
            component.onOrdersChanged?.call(orders);
          },
        );
      case CttermRoute.production:
        return ProductionScreen(
          game: component.game!,
          onNavigate: component.onNavigate,
        );
      case CttermRoute.academy:
        return AcademyScreen(
          game: component.game!,
          orders: component.orders ?? const Orders(),
          onNavigate: component.onNavigate,
          onOrdersChanged: (Orders orders) {
            component.onOrdersChanged?.call(orders);
          },
        );
      case CttermRoute.shipyard:
        return ShipyardScreen(
          game: component.game!,
          orders: component.orders ?? const Orders(),
          onNavigate: component.onNavigate,
          onOrdersChanged: (Orders orders) {
            component.onOrdersChanged?.call(orders);
          },
        );
      case CttermRoute.diplomacy:
        return DiplomacyScreen(
          game: component.game!,
          orders: component.orders ?? const Orders(),
          onNavigate: component.onNavigate,
          onOrdersChanged: (Orders orders) {
            component.onOrdersChanged?.call(orders);
          },
        );
      case CttermRoute.technology:
        return TechnologyScreen(
          game: component.game!,
          orders: component.orders ?? const Orders(),
          onNavigate: component.onNavigate,
          onOrdersChanged: (Orders orders) {
            component.onOrdersChanged?.call(orders);
          },
        );
      case CttermRoute.victoryProgress:
        return VictoryProgressScreen(
          onNavigate: component.onNavigate,
          onVictory: _triggerVictory,
          onDefeat: _triggerDefeat,
        );
      case CttermRoute.victory:
        // Use game data if available, otherwise fallbacks
        final victory = component.game?.victory;
        return VictoryScreen(
          onNavigate: component.onNavigate,
          onExitToMainMenu: () {
            _log.d('tui:nav: Victory -> main menu');
            component.onNavigate(CttermRoute.mainMenu);
          },
          victoryType: victory?.type.name ?? 'Military',
          turnNumber: victory?.turnNumber ?? 1,
          winnerName: 'You',
        );
      case CttermRoute.defeat:
        // Use game data if available, otherwise fallbacks
        final victory = component.game?.victory;
        // Build standings from game state
        final standings = component.game != null
            ? _buildStandings(component.game!)
            : <MapEntry<String, int>>[];
        return DefeatScreen(
          onNavigate: component.onNavigate,
          onExitToMainMenu: () {
            _log.d('tui:nav: Defeat -> main menu');
            component.onNavigate(CttermRoute.mainMenu);
          },
          winnerName: victory?.winnerPlayerId ?? 'AI Player',
          victoryType: victory?.type.name ?? 'Military',
          turnNumber: victory?.turnNumber ?? 1,
          finalStandings: standings,
        );
      case CttermRoute.pauseOptions:
        return PauseOptionsScreen(
          onNavigate: component.onNavigate,
          onExitToMainMenu: () {
            _log.d('tui:nav: exit to main menu from pause');
            component.onClearGame?.call();
            component.onNavigate(CttermRoute.mainMenu);
          },
        );
    }
  }
}

  /// Builds standings from game state for defeat screen.
  /// Returns list of GP name -> province count, sorted by count descending.
  List<MapEntry<String, int>> _buildStandings(Game game) {
    final countsByOwner = <String, int>{};
    
    // Count Old World provinces per player
    for (final province in game.worldState.oldWorld.provinces) {
      final ownerId = province.ownerId;
      if (ownerId == null || ownerId.isEmpty) continue;
      countsByOwner.update(ownerId, (v) => v + 1, ifAbsent: () => 1);
    }
    
    // Get player names
    final playerNames = <String, String>{};
    for (final player in game.players) {
      playerNames[player.id] = player.displayName;
    }
    
    // Build standings list
    final standings = <MapEntry<String, int>>[];
    for (final entry in countsByOwner.entries) {
      final name = playerNames[entry.key] ?? entry.key;
      standings.add(MapEntry(name, entry.value));
    }
    
    // Sort by province count descending
    standings.sort((a, b) => b.value.compareTo(a.value));
    
    return standings;
  }
