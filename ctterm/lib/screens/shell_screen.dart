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
import 'package:ctterm/screens/settings_screen.dart';
import 'package:ctterm/screens/stub_screen.dart';
import 'package:ctterm/screens/victory_progress_screen.dart';
import 'package:ctterm/screens/victory_screen.dart';
import 'package:ctterm/save_service.dart';

final log_pkg.Logger _log = log_pkg.Logger();

/// Displays the current route (Main Menu or a stub) and handles back/exit.
class ShellScreen extends StatefulComponent {
  const ShellScreen({
    super.key,
    required this.route,
    required this.onNavigate,
    required this.onExit,
    this.dataDirOverride,
  });

  final CttermRoute route;
  final String? dataDirOverride;
  final void Function(CttermRoute) onNavigate;
  final void Function() onExit;

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  // Game state for victory/defeat screens
  int _currentTurn = 1;
  
  void _triggerVictory() {
    _log.d('tui:game: victory triggered, turn $_currentTurn');
    component.onNavigate(CttermRoute.victory);
  }
  
  void _triggerDefeat() {
    _log.d('tui:game: defeat triggered, turn $_currentTurn');
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
          onLoad: (gameId) {
            _log.d('tui:nav: Load gameId=$gameId -> in-game shell');
            component.onNavigate(CttermRoute.inGameShell);
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
          onNavigate: component.onNavigate,
          onEndTurn: () async {
            // TODO: Actually process turn when game logic is wired up
            _log.d('tui:game: end turn (stub)');
          },
          onExitToMainMenu: () {
            _log.d('tui:nav: exit to main menu');
            component.onNavigate(CttermRoute.mainMenu);
          },
        );
      case CttermRoute.units:
        return const StubScreen(title: 'Units');
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
        return VictoryScreen(
          onNavigate: component.onNavigate,
          onExitToMainMenu: () {
            _log.d('tui:nav: Victory -> main menu');
            component.onNavigate(CttermRoute.mainMenu);
          },
          victoryType: 'Military',
          turnNumber: _currentTurn,
          winnerName: 'You',
        );
      case CttermRoute.defeat:
        return DefeatScreen(
          onNavigate: component.onNavigate,
          onExitToMainMenu: () {
            _log.d('tui:nav: Defeat -> main menu');
            component.onNavigate(CttermRoute.mainMenu);
          },
          winnerName: 'British Empire',
          victoryType: 'Military',
          turnNumber: _currentTurn,
        );
      case CttermRoute.pauseOptions:
        return const StubScreen(title: 'Pause / Options');
    }
  }
}
