// Root ctterm app: navigation shell and main menu. SPEC/tui/ctterm.md.

import 'package:logger/logger.dart' as log_pkg;
import 'package:nocterm/nocterm.dart';

import 'package:ctterm/ctterm_routes.dart';
import 'package:ctterm/screens/shell_screen.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

final log_pkg.Logger _log = log_pkg.Logger();

/// Root component. Holds current screen and shows Main Menu or a stub.
class CttermApp extends StatefulComponent {
  const CttermApp({super.key, this.dataDirOverride});

  final String? dataDirOverride;

  @override
  State<CttermApp> createState() => _CttermAppState();
}

class _CttermAppState extends State<CttermApp> {
  CttermRoute _route = CttermRoute.mainMenu;
  Game? _currentGame;

  void _navigateTo(CttermRoute route) {
    setState(() => _route = route);
  }

  /// Loads a game by ID and navigates to in-game shell.
  Future<void> _loadGame(String gameId) async {
    // TODO: Actually load the game using save_service
    // For now, this is a placeholder - full implementation would:
    // 1. Call loadGame(gameId, dataDirOverride) from save_service
    // 2. Store the loaded game in _currentGame
    // 3. Navigate to inGameShell
    _log.d('tui:app: load game $gameId (stub)');
    setState(() => _route = CttermRoute.inGameShell);
  }

  void _exit() {
    shutdownApp(0);
  }

  @override
  Component build(BuildContext context) {
    return NoctermApp(
      title: 'ColonizeThis',
      child: ShellScreen(
        route: _route,
        dataDirOverride: component.dataDirOverride,
        game: _currentGame,
        onNavigate: _navigateTo,
        onExit: _exit,
      ),
    );
  }
}
