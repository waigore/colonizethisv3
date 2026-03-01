// In-Game Shell: map + HUD + panel navigation. SPEC/tui/ctterm.md, SPEC/tui/screens/in-game-shell.md.

import 'package:logger/logger.dart' as log_pkg;
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:ctterm/ctterm_routes.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

final log_pkg.Logger _log = log_pkg.Logger();

/// In-game shell: main game view with ASCII map, HUD, and navigation to panels.
/// 
/// Features:
/// - ASCII map display (simplified for MVP)
/// - HUD with turn/year, treasury
/// - Keyboard navigation to panels (U, D, P, A, S, I, T, V)
/// - Map context (M)
/// - End turn (E or Enter)
/// - Pause/Options (O or Escape)
class InGameShellScreen extends StatefulComponent {
  const InGameShellScreen({
    super.key,
    this.game,
    required this.onNavigate,
    required this.onEndTurn,
    required this.onVictory,
    required this.onDefeat,
    required this.onExitToMainMenu,
  });

  /// Current game state for victory checking.
  final Game? game;
  final void Function(CttermRoute) onNavigate;
  final Future<void> Function() onEndTurn;
  /// Callback when human player wins.
  final void Function() onVictory;
  /// Callback when AI player wins (human defeated).
  final void Function() onDefeat;
  final void Function() onExitToMainMenu;

  @override
  State<InGameShellScreen> createState() => _InGameShellScreenState();
}

class _InGameShellScreenState extends State<InGameShellScreen> {
  // Game state (MVP: static values)
  int _turn = 1;
  int _year = 1850;
  int _treasury = 5000;
  final String _selectedProvince = 'None';
  bool _isEndingTurn = false;

  static const List<String> _mapGrid = [
    '  ~~~  ~~~  ',
    ' ~~~  ~~~  ',
    '~~~~  ~~~~ ',
    ' +++  +++  ',
    ' +A+  +B+  ',
    ' +++  +++  ',
    ' ~~~  ~~~  ',
    ' ~~~  ~~~  ',
  ];

  Future<void> _handleEndTurn() async {
    if (_isEndingTurn) return;
    setState(() => _isEndingTurn = true);
    _log.d('tui:game: ending turn $_turn');
    
    await component.onEndTurn();
    
    // Check for victory/defeat after turn processing
    final game = component.game;
    if (game?.victory != null) {
      final winnerId = game!.victory!.winnerPlayerId;
      final isHumanWinner = _isHumanPlayer(winnerId, game);
      _log.i('tui:game: victory detected winner=$winnerId isHuman=$isHumanWinner');
      setState(() => _isEndingTurn = false);
      if (isHumanWinner) {
        component.onVictory();
      } else {
        component.onDefeat();
      }
      return;
    }
    
    setState(() {
      _turn++;
      _year += 5; // Each turn = 5 years
      _treasury += 100; // Simplified income
      _isEndingTurn = false;
    });
    _log.d('tui:game: now turn $_turn, year $_year');
  }

  /// Checks if the given playerId is the human player.
  bool _isHumanPlayer(String playerId, Game game) {
    // Human player is one where aiControlByGpId is false or not set
    return !(game.aiControlByGpId[playerId] ?? false);
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        final key = event.logicalKey;
        final c = event.character?.toLowerCase();
        
        // Navigation keys
        if (c == 'u') {
          component.onNavigate(CttermRoute.units);
          return true;
        }
        if (c == 'd') {
          component.onNavigate(CttermRoute.development);
          return true;
        }
        if (c == 'p') {
          component.onNavigate(CttermRoute.production);
          return true;
        }
        if (c == 'a') {
          component.onNavigate(CttermRoute.academy);
          return true;
        }
        if (c == 's') {
          component.onNavigate(CttermRoute.shipyard);
          return true;
        }
        if (c == 'i') {
          component.onNavigate(CttermRoute.diplomacy);
          return true;
        }
        if (c == 't') {
          component.onNavigate(CttermRoute.technology);
          return true;
        }
        if (c == 'v') {
          component.onNavigate(CttermRoute.victoryProgress);
          return true;
        }
        
        // Map context (M key)
        if (c == 'm') {
          _log.d('tui:nav: in-game shell -> map context');
          component.onNavigate(CttermRoute.mapContext);
          return true;
        }
        
        // End turn
        if (c == 'e' || key == LogicalKey.enter) {
          _handleEndTurn();
          return true;
        }
        
        // Pause/Options
        if (c == 'o' || key == LogicalKey.escape) {
          component.onNavigate(CttermRoute.pauseOptions);
          return true;
        }
        
        return false;
      },
      child: Column(
        children: [
          // HUD
          _buildHUD(),
          const SizedBox(height: 1),
          // Map
          Expanded(child: _buildMap()),
          // Command bar
          _buildCommandBar(),
        ],
      ),
    );
  }

  Component _buildHUD() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Turn: $_turn | Year: $_year | Treasury: \$$_treasury '),
          Text('[$_selectedProvince]', style: TextStyle(color: Colors.gray)),
        ],
      ),
    );
  }

  Component _buildMap() {
    return Container(
      padding: const EdgeInsets.all(1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('--- Map ---', style: TextStyle(color: Colors.gray)),
          const SizedBox(height: 1),
          ..._mapGrid.map((row) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 0),
            child: Text(row),
          )),
          const SizedBox(height: 1),
          Text('Legend: ~ sea  + land  A/B prov owner', style: TextStyle(color: Colors.gray)),
        ],
      ),
    );
  }

  Component _buildCommandBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: _isEndingTurn
          ? Text('Processing turn...', style: TextStyle(color: Colors.yellow))
          : Row(
              children: [
                const Text('['),
                Text('M', style: TextStyle(color: Colors.cyan)),
                const Text(']ap Context '),
                const Text('['),
                Text('U', style: TextStyle(color: Colors.cyan)),
                const Text(']nits '),
                const Text('['),
                Text('D', style: TextStyle(color: Colors.cyan)),
                const Text(']ev '),
                const Text('['),
                Text('P', style: TextStyle(color: Colors.cyan)),
                const Text(']rod '),
                const Text('['),
                Text('A', style: TextStyle(color: Colors.cyan)),
                const Text(']cademy '),
                const Text('['),
                Text('S', style: TextStyle(color: Colors.cyan)),
                const Text(']hipyard '),
                const Text('['),
                Text('I', style: TextStyle(color: Colors.cyan)),
                const Text(']ntl '),
                const Text('['),
                Text('T', style: TextStyle(color: Colors.cyan)),
                const Text(']ech '),
                const Text('['),
                Text('V', style: TextStyle(color: Colors.cyan)),
                const Text(']ictory '),
                const Text('['),
                Text('E', style: TextStyle(color: Colors.cyan)),
                const Text(']nd Turn '),
                const Text('['),
                Text('O', style: TextStyle(color: Colors.cyan)),
                const Text(']ptions'),
              ],
            ),
    );
  }
}
