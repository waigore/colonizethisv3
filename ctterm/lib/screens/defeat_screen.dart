// Defeat screen: shown when human player loses. SPEC/tui/ctterm.md, SPEC/game/victory.md.

import 'package:logger/logger.dart' as log_pkg;
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:ctterm/ctterm_routes.dart';

final log_pkg.Logger _log = log_pkg.Logger();

/// Defeat screen: shown when another Great Power wins the game.
/// 
/// Content:
/// - "You have been defeated" message
/// - Winner's display name
/// - Victory type
/// - Final standings
/// - Options: View Final Map, Return to Main Menu
class DefeatScreen extends StatefulComponent {
  const DefeatScreen({
    super.key,
    required this.onNavigate,
    required this.onExitToMainMenu,
    required this.winnerName,
    required this.victoryType,
    required this.turnNumber,
    this.finalStandings = const [],
  });

  final void Function(CttermRoute) onNavigate;
  final void Function() onExitToMainMenu;
  final String winnerName;
  final String victoryType;
  final int turnNumber;
  final List<MapEntry<String, int>> finalStandings; // GP name -> province count

  @override
  State<DefeatScreen> createState() => _DefeatScreenState();
}

class _DefeatScreenState extends State<DefeatScreen> {
  String _selectedOption = 'map'; // 'map' or 'menu'

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        final c = event.character?.toLowerCase();
        
        // Navigate options
        if (c == 'v') {
          setState(() => _selectedOption = 'map');
          return true;
        }
        if (c == 'm') {
          setState(() => _selectedOption = 'menu');
          return true;
        }
        
        // Confirm selection
        if (event.logicalKey == LogicalKey.enter || c == 'e') {
          if (_selectedOption == 'menu') {
            _log.d('tui:nav: Defeat -> main menu');
            component.onExitToMainMenu();
          } else {
            _log.d('tui:nav: Defeat -> final map');
            component.onNavigate(CttermRoute.inGameShell);
          }
          return true;
        }
        
        // Go back
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
            // Defeat banner
            Text(
              '*** DEFEAT ***',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 1),
            
            // You have been defeated
            Text(
              'You have been defeated!',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 1),
            
            // Winner info
            Text(
              '${component.winnerName} has conquered the New World.',
              style: TextStyle(color: Colors.yellow),
            ),
            const SizedBox(height: 1),
            
            // Victory type
            Text(
              '${component.victoryType} Victory',
              style: TextStyle(color: Colors.gray),
            ),
            const SizedBox(height: 1),
            
            // Turn number
            Text(
              'Achieved in ${component.turnNumber} turns',
              style: TextStyle(color: Colors.gray),
            ),
            const SizedBox(height: 2),
            
            // Final standings
            _buildFinalStandings(),
            
            const SizedBox(height: 2),
            
            // Options
            Text('Choose an action:', style: TextStyle(color: Colors.gray)),
            const SizedBox(height: 1),
            
            // Option 1: View Final Map
            _buildOption('v', 'View Final Map', _selectedOption == 'map'),
            const SizedBox(height: 1),
            
            // Option 2: Return to Main Menu
            _buildOption('m', 'Return to Main Menu', _selectedOption == 'menu'),
            
            const SizedBox(height: 2),
            
            // Instructions
            Text(
              '[Enter] Confirm   [V]iew Map   [M]enu',
              style: TextStyle(color: Colors.gray),
            ),
          ],
        ),
      ),
    );
  }

  Component _buildFinalStandings() {
    // Default standings if none provided
    final standings = component.finalStandings.isEmpty
        ? [
            MapEntry('British Empire', 35),
            MapEntry('French Republic', 22),
            MapEntry('You', 15),
            MapEntry('Spanish Crown', 8),
          ]
        : component.finalStandings;
    
    return Container(
      padding: const EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Final Standings:', style: TextStyle(color: Colors.gray)),
          const SizedBox(height: 1),
          ...standings.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final name = entry.value.key;
            final provinces = entry.value.value;
            final isWinner = name == component.winnerName;
            final isPlayer = name == 'You' || name == 'Player';
            
            final color = isWinner 
                ? Colors.yellow 
                : (isPlayer ? Colors.red : Colors.white);
            final prefix = isWinner ? '👑 ' : '   ';
            
            return Text(
              '$prefix$rank. $name - $provinces provinces',
              style: TextStyle(color: color),
            );
          }),
        ],
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
