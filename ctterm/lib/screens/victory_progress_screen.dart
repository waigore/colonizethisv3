// Victory/Progress screen: shows progress toward victory. SPEC/tui/ctterm.md, SPEC/tui/screens/victory-progress.md.

import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:ctterm/ctterm_routes.dart';

final _log = tuiLogger();

/// Victory/Progress screen: shows progress toward victory condition.
/// 
/// MVP shows:
/// - Human player progress (static values for now)
/// - Victory condition info (31 OW provinces needed)
/// - Option to return to shell
class VictoryProgressScreen extends StatefulComponent {
  const VictoryProgressScreen({
    super.key,
    required this.onNavigate,
    required this.onVictory,
    required this.onDefeat,
  });

  final void Function(CttermRoute) onNavigate;
  final void Function() onVictory; // Human wins
  final void Function() onDefeat; // AI wins

  @override
  State<VictoryProgressScreen> createState() => _VictoryProgressScreenState();
}

class _VictoryProgressScreenState extends State<VictoryProgressScreen> {
  // MVP: Static progress data (would come from game state in full impl)
  // In full implementation, this would count OW provinces per GP from game state
  static const int _victoryThreshold = 31;
  
  // Placeholder: human player has 15 OW provinces, AI has 20
  final Map<String, int> _gpProvinces = {
    'player': 15,  // Human player (MVP)
    'gpa': 20,    // AI GP A
    'gpb': 8,    // AI GP B
    'gpc': 12,   // AI GP C
  };
  
  final Map<String, String> _gpNames = {
    'player': 'You',
    'gpa': 'British Empire',
    'gpb': 'French Republic',
    'gpc': 'Spanish Crown',
  };

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        if (event.logicalKey == LogicalKey.escape || 
            event.character?.toLowerCase() == 'b') {
          _log.d('Victory/Progress -> shell');
          component.onNavigate(CttermRoute.inGameShell);
          return true;
        }
        // For testing: V = victory, D = defeat
        if (event.character?.toLowerCase() == 'v') {
          _log.d('test victory triggered');
          component.onVictory();
          return true;
        }
        if (event.character?.toLowerCase() == 'd') {
          _log.d('test defeat triggered');
          component.onDefeat();
          return true;
        }
        return false;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(1),
            child: const Text('=== VICTORY / PROGRESS ==='),
          ),
          const SizedBox(height: 1),
          
          // Victory condition info
          Container(
            padding: const EdgeInsets.all(1),
            child: Text(
              'Victory Condition: Control $_victoryThreshold or more Old World provinces',
              style: TextStyle(color: Colors.yellow),
            ),
          ),
          const SizedBox(height: 1),
          
          // Progress table
          _buildProgressTable(),
          
          const SizedBox(height: 1),
          
          // Legend
          _buildLegend(),
          
          const Spacer(),
          
          // Footer
          Container(
            padding: const EdgeInsets.all(1),
            child: Text(
              '[Esc/B] Back to Map  [V] Test Victory  [D] Test Defeat',
              style: TextStyle(color: Colors.gray),
            ),
          ),
        ],
      ),
    );
  }

  Component _buildProgressTable() {
    // Sort GPs by province count (descending)
    final sortedEntries = _gpProvinces.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Find the maximum province count for leading GP detection
    final maxProvinces = _gpProvinces.values.isEmpty 
        ? 0 
        : _gpProvinces.values.reduce((a, b) => a > b ? a : b);
    
    return Container(
      padding: const EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Great Power              Provinces   Progress'),
          Text('=' * 50),
          ...sortedEntries.map((entry) {
            final name = _gpNames[entry.key] ?? entry.key;
            final provinces = entry.value;
            final progress = (provinces / _victoryThreshold * 100).clamp(0, 100).toInt();
            final isPlayer = entry.key == 'player';
            final isLeading = provinces == maxProvinces;
            
            // Build progress bar
            final barLength = 20;
            final filled = (provinces / _victoryThreshold * barLength).clamp(0, barLength).toInt();
            final bar = '[${'=' * filled}${' ' * (barLength - filled)}]';
            
            final color = isPlayer 
                ? Colors.cyan 
                : (isLeading ? Colors.green : Colors.white);
            
            return Text(
              '${name.padRight(22)} ${provinces.toString().padLeft(3)} / $_victoryThreshold   $bar $progress%',
              style: TextStyle(color: color),
            );
          }),
        ],
      ),
    );
  }

  Component _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Legend:', style: TextStyle(color: Colors.gray)),
          Text('  Cyan = You', style: TextStyle(color: Colors.cyan)),
          Text('  Green = Leading', style: TextStyle(color: Colors.green)),
          Text('  White = Other Great Powers', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
