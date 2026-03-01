// Navigation shell: switches on route and shows Main Menu or stub. SPEC/tui/ctterm.md.

import 'package:logger/logger.dart' as log_pkg;
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:ctterm/ctterm_routes.dart';
import 'package:ctterm/screens/game_setup_screen.dart';
import 'package:ctterm/screens/load_game_screen.dart';
import 'package:ctterm/screens/main_menu_screen.dart';
import 'package:ctterm/screens/settings_screen.dart';
import 'package:ctterm/screens/stub_screen.dart';
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
        return const StubScreen(title: 'Generating World');
      case CttermRoute.settings:
        return SettingsScreen(
          onBack: () => component.onNavigate(CttermRoute.mainMenu),
        );
      case CttermRoute.inGameShell:
        return const StubScreen(title: 'In-game shell');
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
        return const StubScreen(title: 'Victory / Progress');
      case CttermRoute.defeat:
        return const StubScreen(title: 'Defeat');
      case CttermRoute.pauseOptions:
        return const StubScreen(title: 'Pause / Options');
    }
  }
}
