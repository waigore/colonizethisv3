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
import 'package:ctterm/screens/stub_screen.dart';
import 'package:ctterm/screens/victory_progress_screen.dart';
import 'package:ctterm/screens/units_screen.dart';
import 'package:ctterm/screens/victory_screen.dart';
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
    this.onTurnProcessed,
    this.onOrdersChanged,
    this.onGameUpdated,
    this.onClearGame,
    this.onLoadGame,
  });

  final CttermRoute route;
  final String? dataDirOverride;
  /// Current game state. Set when loading or starting a game.
  final Game? game;
  /// Current orders for the human player.
  final Orders? orders;
  final void Function(CttermRoute) onNavigate;
  final void Function() onExit;
  /// Callback when turn is processed, receives updated game state.
  final void Function(Game)? onTurnProcessed;
  /// Callback when orders are changed in a panel.
  final void Function(Orders)? onOrdersChanged;
  /// Callback when game state is updated (e.g., orders changed in a panel).
  final void Function(Game)? onGameUpdated;
  /// Callback to clear game state (e.g., when returning to main menu).
  final void Function()? onClearGame;
  /// Callback to load a game by ID.
  final Future<void> Function(String gameId)? onLoadGame;

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
          if (component.route != CttermRoute.mainMenu) {
            _log.d('tui:nav: Esc -> main menu');
            component.onNavigate(CttermRoute.mainMenu);
          }
          return true;
        }
        return false;
      },
      child: _buildScreen(),
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
            // TODO: Create game with config and navigate to in-game shell
            // For now, navigate to generating world (stub will be replaced)
            component.onNavigate(CttermRoute.generatingWorld);
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
        );
      case CttermRoute.settings:
        return SettingsScreen(
          onBack: () => component.onNavigate(CttermRoute.mainMenu),
        );
      case CttermRoute.inGameShell:
        return InGameShellScreen(
          game: component.game,
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
            const emptyTopology = MapTopology();
            final nextGame = resolveTurnForGame(
              game: game,
              topology: emptyTopology,
              orders: currentOrders,
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
          onNavigate: component.onNavigate,
        );
      case CttermRoute.units:
        return UnitsScreen(
          game: component.game!,
          orders: component.orders ?? const Orders(),
          onNavigate: component.onNavigate,
          onOrdersChanged: (Orders orders) {
            // Propagate orders change to parent
            component.onOrdersChanged?.call(orders);
          },
        );
      case CttermRoute.development:
        return const StubScreen(title: 'Development');
      case CttermRoute.production:
        return const StubScreen(title: 'Production');
      case CttermRoute.academy:
        return const StubScreen(title: 'Academy');
      case CttermRoute.shipyard:
        return const StubScreen(title: 'Shipyard');
      case CttermRoute.diplomacy:
        return const StubScreen(title: 'Diplomacy');
      case CttermRoute.technology:
        return const StubScreen(title: 'Technology');
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
        return const StubScreen(title: 'Pause / Options');
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
