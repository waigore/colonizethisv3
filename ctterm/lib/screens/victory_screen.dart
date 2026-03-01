// Victory screen: shown when human player wins. SPEC/tui/ctterm.md, SPEC/game/victory.md.

import 'package:logger/logger.dart' as log_pkg;
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:ctterm/ctterm_routes.dart';

final log_pkg.Logger _log = log_pkg.Logger();

/// Victory screen: shown when human player wins the game.
/// 
/// Content:
/// - Winner's display name
/// - Victory type (e.g., "Military victory")
/// - Turn number
/// - Options: Return to Main Menu, View Final Map
class VictoryScreen extends StatefulComponent {
  const VictoryScreen({
    super.key,
    required this.onNavigate,
    required this.onExitToMainMenu,
    required this.victoryType,
    required this.turnNumber,
    this.winnerName = 'You',
  });

  final void Function(CttermRoute) onNavigate;
  final void Function() onExitToMainMenu;
  final String victoryType; // e.g., 'Military'
  final int turnNumber;
  final String winnerName;

  @override
  State<VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends State<VictoryScreen> {
  String _selectedOption = 'menu'; // 'menu' or 'map'

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        final c = event.character?.toLowerCase();
        
        // Navigate options
        if (c == 'm') {
          setState(() => _selectedOption = 'menu');
          return true;
        }
        if (c == 'v') {
          setState(() => _selectedOption = 'map');
          return true;
        }
        
        // Confirm selection
        if (event.logicalKey == LogicalKey.enter || c == 'e') {
          if (_selectedOption == 'menu') {
            _log.d('tui:nav: Victory -> main menu');
            component.onExitToMainMenu();
          } else {
            _log.d('tui:nav: Victory -> final map');
            component.onNavigate(CttermRoute.inGameShell);
          }
          return true;
        }
        
        // Go back (shouldn't happen at victory screen, but for completeness)
        if (event.logicalKey == LogicalKey.escape) {
          component.onNavigate(CttermRoute.inGameShell);
          return true;
        }
        
        return false;
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Victory banner
            Text(
              '*** VICTORY ***',
              style: TextStyle(
                color: Colors.yellow,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 1),
            
            // Winner
            Text(
              '${component.winnerName} have conquered the New World!',
              style: TextStyle(color: Colors.cyan),
            ),
            const SizedBox(height: 1),
            
            // Victory type
            Text(
              '${component.victoryType} Victory',
              style: TextStyle(color: Colors.green),
            ),
            const SizedBox(height: 1),
            
            // Turn number
            Text(
              'Achieved in ${component.turnNumber} turns',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 2),
            
            // Options
            Text('Choose an action:', style: TextStyle(color: Colors.gray)),
            const SizedBox(height: 1),
            
            // Option 1: Return to Main Menu
            _buildOption('m', 'Return to Main Menu', _selectedOption == 'menu'),
            const SizedBox(height: 1),
            
            // Option 2: View Final Map
            _buildOption('v', 'View Final Map', _selectedOption == 'map'),
            
            const SizedBox(height: 2),
            
            // Instructions
            Text(
              '[Enter] Confirm   [M]enu   [V]iew Map',
              style: TextStyle(color: Colors.gray),
            ),
          ],
        ),
      ),
    );
  }

  Component _buildOption(String key, String label, bool isSelected) {
    final prefix = isSelected ? '> ' : '  ';
    final color = isSelected ? Colors.yellow : Colors.white;
    return Text(
      '$prefix[$key] $label',
      style: TextStyle(color: color),
    );
  }
}
