// Root ctterm app: navigation shell and main menu. SPEC/tui/ctterm.md.

import 'package:logger/logger.dart' as log_pkg;
import 'package:nocterm/nocterm.dart';

import 'package:ctterm/ctterm_routes.dart';
import 'package:ctterm/screens/shell_screen.dart';
import 'package:ctterm/save_service.dart';
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

  /// Callback when turn is processed, updates game state.
  void _onTurnProcessed(Game updatedGame) {
    _log.d('tui:app: turn processed, now turn ${updatedGame.worldState.turnState.turnNumber}');
    setState(() => _currentGame = updatedGame);
  }

  /// Clears game state (e.g., when returning to main menu).
  void _clearGame() {
    _log.d('tui:app: clearing game state');
    setState(() => _currentGame = null);
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
        onTurnProcessed: _onTurnProcessed,
        onClearGame: _clearGame,
        onLoadGame: _loadGame,
      ),
    );
  }
}
