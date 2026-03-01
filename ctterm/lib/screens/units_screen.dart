// Units Screen: manage military and civilian unit orders. SPEC/tui/screens/units.md.

import 'package:logger/logger.dart' as log_pkg;
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:ctterm/ctterm_routes.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

final log_pkg.Logger _log = log_pkg.Logger();

/// Units screen for managing unit stacks and issuing orders.
class UnitsScreen extends StatefulComponent {
  const UnitsScreen({
    super.key,
    required this.game,
    required this.orders,
    required this.onNavigate,
    required this.onOrdersChanged,
  });

  /// Current game state (required for unit data).
  final Game game;
  /// Current orders for the human player.
  final Orders orders;
  final void Function(CttermRoute) onNavigate;
  /// Callback when orders are changed (to propagate to game).
  final void Function(Orders) onOrdersChanged;

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  /// Currently selected unit index in the list.
  int _selectedIndex = 0;
  
  /// Current input mode: none, moveTarget, attackTarget.
  String _inputMode = 'none';
  
  /// Feedback message to display (e.g., order accepted/rejected).
  String _feedbackMessage = '';
  
  /// Color for feedback message.
  Color _feedbackColor = Colors.white;

  /// Get all units for the human player from both regions.
  List<Unit> get _playerUnits {
    final humanPlayerId = _getHumanPlayerId();
    if (humanPlayerId == null) return [];
    
    final allUnits = <Unit>[];
    allUnits.addAll(component.game.worldState.oldWorld.units
        .where((u) => u.ownerId == humanPlayerId));
    allUnits.addAll(component.game.worldState.newWorld.units
        .where((u) => u.ownerId == humanPlayerId));
    return allUnits;
  }

  /// Get the human player's ID (non-AI controlled).
  String? _getHumanPlayerId() {
    for (final entry in component.game.aiControlByGpId.entries) {
      if (!entry.value) return entry.key;
    }
    // Fallback: first player
    return component.game.players.isNotEmpty ? component.game.players.first.id : null;
  }

  /// Get province name for a unit (formatted as prefixId).
  String _getProvinceName(Unit unit) {
    return unit.provinceId;
  }

  /// Get the current player's orders for units.
  List<MoveOrder> _getPlayerMoveOrders() {
    final playerId = _getHumanPlayerId();
    if (playerId == null) return [];
    return component.orders.moveOrdersByPlayerId[playerId] ?? [];
  }

  /// Check if a unit has pending orders.
  bool _unitHasOrders(String unitId) {
    return _getPlayerMoveOrders().any((o) => o.unitId == unitId);
  }

  /// Handle keyboard input.
  // Type is inferred from Nocterm's Focusable.onKeyEvent callback
  // ignore: strict_top_level_inference
  bool _handleKeyEvent(event) {
    final key = event.logicalKey;
    final c = event.character?.toLowerCase();
    final units = _playerUnits;
    
    if (units.isEmpty) {
      if (c == 'escape') {
        component.onNavigate(CttermRoute.inGameShell);
        return true;
      }
      return false;
    }

    // Escape: back to shell or cancel input mode
    if (key == LogicalKey.escape) {
      if (_inputMode != 'none') {
        setState(() {
          _inputMode = 'none';
          _feedbackMessage = '';
        });
        _log.d('tui:nav: cancelled input mode');
        return true;
      }
      component.onNavigate(CttermRoute.inGameShell);
      return true;
    }

    // Navigation in input modes
    if (_inputMode == 'moveTarget' || _inputMode == 'attackTarget') {
      if (key == LogicalKey.arrowUp || c == 'k') {
        _selectAdjacentProvince(-1);
        return true;
      }
      if (key == LogicalKey.arrowDown || c == 'j') {
        _selectAdjacentProvince(1);
        return true;
      }
      if (key == LogicalKey.enter || c == 'y') {
        _confirmTargetProvince();
        return true;
      }
      if (c == 'n') {
        setState(() {
          _inputMode = 'none';
          _feedbackMessage = 'Cancelled';
        });
        return true;
      }
      return false;
    }

    // Navigation: arrow keys / j/k to navigate unit list
    if (key == LogicalKey.arrowUp || c == 'k') {
      setState(() => _selectedIndex = (_selectedIndex - 1).clamp(0, units.length - 1));
      return true;
    }
    if (key == LogicalKey.arrowDown || c == 'j') {
      setState(() => _selectedIndex = (_selectedIndex + 1).clamp(0, units.length - 1));
      return true;
    }

    // Enter/Space: select unit (show detail)
    if (key == LogicalKey.enter || key == LogicalKey.space) {
      // For now, just show the unit detail
      _log.d('tui:units: selected unit ${units[_selectedIndex].id}');
      return true;
    }

    // m: issue Move order
    if (c == 'm') {
      _startMoveOrder(units[_selectedIndex]);
      return true;
    }

    // a: issue Attack order
    if (c == 'a') {
      _startAttackOrder(units[_selectedIndex]);
      return true;
    }

    // c: clear orders
    if (c == 'c') {
      _clearOrders(units[_selectedIndex]);
      return true;
    }

    return false;
  }

  /// Get adjacent provinces for the selected unit (simplified - returns a few dummy options for MVP).
  List<String> _getAdjacentProvinces(Unit unit) {
    // MVP: return some dummy adjacent provinces based on the unit's current province
    // Full implementation would check adjacency from map topology
    final provId = unit.provinceId;
    if (provId.isEmpty) return [];
    
    // For MVP, just show a few placeholder adjacent provinces
    // In a real implementation, we'd query the map topology
    return [
      '$provId-adjacent-1',
      '$provId-adjacent-2', 
      '$provId-adjacent-3',
    ];
  }

  int _selectedAdjacentIndex = 0;

  void _selectAdjacentProvince(int delta) {
    final adj = _getAdjacentProvinces(_playerUnits[_selectedIndex]);
    if (adj.isEmpty) return;
    setState(() {
      _selectedAdjacentIndex = (_selectedAdjacentIndex + delta).clamp(0, adj.length - 1);
    });
  }

  void _confirmTargetProvince() {
    final units = _playerUnits;
    if (_selectedIndex >= units.length) return;
    
    final unit = units[_selectedIndex];
    final adj = _getAdjacentProvinces(unit);
    if (_selectedAdjacentIndex >= adj.length) return;
    
    final targetProvince = adj[_selectedAdjacentIndex];
    
    if (_inputMode == 'moveTarget') {
      _issueMoveOrder(unit, targetProvince);
    } else if (_inputMode == 'attackTarget') {
      _issueAttackOrder(unit, targetProvince);
    }
    
    setState(() {
      _inputMode = 'none';
    });
  }

  void _startMoveOrder(Unit unit) {
    final adj = _getAdjacentProvinces(unit);
    if (adj.isEmpty) {
      setState(() {
        _feedbackMessage = 'No adjacent provinces available';
        _feedbackColor = Colors.red;
      });
      return;
    }
    setState(() {
      _inputMode = 'moveTarget';
      _selectedAdjacentIndex = 0;
      _feedbackMessage = 'Select target province (y/n)';
      _feedbackColor = Colors.yellow;
    });
    _log.d('tui:units: start move order for ${unit.id}');
  }

  void _startAttackOrder(Unit unit) {
    final adj = _getAdjacentProvinces(unit);
    if (adj.isEmpty) {
      setState(() {
        _feedbackMessage = 'No enemy provinces in range';
        _feedbackColor = Colors.red;
      });
      return;
    }
    setState(() {
      _inputMode = 'attackTarget';
      _selectedAdjacentIndex = 0;
      _feedbackMessage = 'Select enemy province to attack (y/n)';
      _feedbackColor = Colors.yellow;
    });
    _log.d('tui:units: start attack order for ${unit.id}');
  }

  void _issueMoveOrder(Unit unit, String targetProvince) {
    // Validate: check movement points (simplified)
    if (unit.movementPoints <= 0) {
      setState(() {
        _feedbackMessage = 'Invalid: not enough movement points';
        _feedbackColor = Colors.red;
      });
      _log.w('tui:units: move rejected - no movement points');
      return;
    }

    // Create move order
    final playerId = _getHumanPlayerId();
    if (playerId == null) {
      setState(() {
        _feedbackMessage = 'Error: no human player';
        _feedbackColor = Colors.red;
      });
      return;
    }

    // Get current orders and add new one
    final currentOrders = component.orders;
    final playerMoveOrders = List<MoveOrder>.from(
        currentOrders.moveOrdersByPlayerId[playerId] ?? []);
    
    // Remove any existing order for this unit
    playerMoveOrders.removeWhere((o) => o.unitId == unit.id);
    
    // Add new order
    playerMoveOrders.add(MoveOrder(
      unitId: unit.id,
      destinationProvinceId: targetProvince,
    ));

    // Create updated orders
    final updatedOrders = currentOrders.copyWith(
      moveOrdersByPlayerId: Map<String, List<MoveOrder>>.from(
          currentOrders.moveOrdersByPlayerId)
        ..[playerId] = playerMoveOrders,
    );

    // Propagate to parent
    component.onOrdersChanged(updatedOrders);

    setState(() {
      _feedbackMessage = 'Move order accepted';
      _feedbackColor = Colors.green;
    });
    _log.i('tui:units: move order accepted for ${unit.id} -> $targetProvince');
  }

  void _issueAttackOrder(Unit unit, String targetProvince) {
    // For MVP, just accept the attack order with simplified validation
    // Full implementation would check enemy ownership and visibility
    
    final playerId = _getHumanPlayerId();
    if (playerId == null) {
      setState(() {
        _feedbackMessage = 'Error: no human player';
        _feedbackColor = Colors.red;
      });
      return;
    }

    // Get current orders and add new one
    final currentOrders = component.orders;
    final playerMoveOrders = List<MoveOrder>.from(
        currentOrders.moveOrdersByPlayerId[playerId] ?? []);
    
    // Remove any existing order for this unit
    playerMoveOrders.removeWhere((o) => o.unitId == unit.id);
    
    // Add new order (attack is represented as move in MVP)
    playerMoveOrders.add(MoveOrder(
      unitId: unit.id,
      destinationProvinceId: targetProvince,
    ));

    // Create updated orders
    final updatedOrders = currentOrders.copyWith(
      moveOrdersByPlayerId: Map<String, List<MoveOrder>>.from(
          currentOrders.moveOrdersByPlayerId)
        ..[playerId] = playerMoveOrders,
    );

    // Propagate to parent
    component.onOrdersChanged(updatedOrders);

    setState(() {
      _feedbackMessage = 'Attack order accepted';
      _feedbackColor = Colors.green;
    });
    _log.i('tui:units: attack order accepted for ${unit.id} -> $targetProvince');
  }

  void _clearOrders(Unit unit) {
    final playerId = _getHumanPlayerId();
    if (playerId == null) return;

    final currentOrders = component.orders;
    final playerMoveOrders = List<MoveOrder>.from(
        currentOrders.moveOrdersByPlayerId[playerId] ?? []);
    
    final hadOrders = playerMoveOrders.any((o) => o.unitId == unit.id);
    playerMoveOrders.removeWhere((o) => o.unitId == unit.id);

    if (hadOrders) {
      final updatedOrders = currentOrders.copyWith(
        moveOrdersByPlayerId: Map<String, List<MoveOrder>>.from(
            currentOrders.moveOrdersByPlayerId)
          ..[playerId] = playerMoveOrders,
      );
      component.onOrdersChanged(updatedOrders);
      
      setState(() {
        _feedbackMessage = 'Orders cleared';
        _feedbackColor = Colors.cyan;
      });
      _log.i('tui:units: cleared orders for ${unit.id}');
    } else {
      setState(() {
        _feedbackMessage = 'No pending orders to clear';
        _feedbackColor = Colors.gray;
      });
    }
  }

  @override
  Component build(BuildContext context) {
    final units = _playerUnits;
    final selectedUnit = units.isNotEmpty && _selectedIndex < units.length 
        ? units[_selectedIndex] 
        : null;

    return Focusable(
      focused: true,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: 1),
          // Main content
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unit list
                Expanded(
                  flex: 2,
                  child: _buildUnitList(units, selectedUnit),
                ),
                // Detail panel
                if (selectedUnit != null) ...[
                  const SizedBox(width: 1),
                  Expanded(
                    flex: 1,
                    child: _buildDetailPanel(selectedUnit),
                  ),
                ],
              ],
            ),
          ),
          // Feedback/message area
          if (_feedbackMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              child: Text(
                _feedbackMessage,
                style: TextStyle(color: _feedbackColor),
              ),
            ),
          // Command bar
          _buildCommandBar(units, selectedUnit),
        ],
      ),
    );
  }

  Component _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: const Text(
        '=== UNITS ===',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Component _buildUnitList(List<Unit> units, Unit? selectedUnit) {
    if (units.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(2),
        child: const Text('No units available'),
      );
    }

    return Container(
      padding: const EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: const Text(
              'LOC        TYPE      STATUS   ORDERS',
              style: TextStyle(color: Colors.gray),
            ),
          ),
          const SizedBox(height: 1),
          // Unit rows
          ...units.asMap().entries.map((entry) {
            final index = entry.key;
            final unit = entry.value;
            final isSelected = index == _selectedIndex;
            final hasOrders = _unitHasOrders(unit.id);
            
            final location = _getProvinceName(unit).padRight(10);
            final type = (unit.type.length > 8 
                ? unit.type.substring(0, 8) 
                : unit.type).padRight(8);
            final status = unit.status.name.padRight(8);
            final orders = hasOrders ? 'YES' : 'none';
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              color: isSelected ? Colors.blue.withOpacity(0.3) : null,
              child: Text(
                '$location $type $status $orders',
                style: isSelected 
                    ? const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyan)
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }

  Component _buildDetailPanel(Unit unit) {
    final hasOrders = _unitHasOrders(unit.id);
    final orders = hasOrders ? _getPlayerMoveOrders().where((o) => o.unitId == unit.id).toList() : <MoveOrder>[];
    
    return Container(
      padding: const EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '--- DETAIL ---',
            style: TextStyle(color: Colors.gray),
          ),
          const SizedBox(height: 1),
          Text('ID: ${unit.id}'),
          Text('Type: ${unit.type}'),
          Text('Owner: ${unit.ownerId}'),
          Text('Province: ${unit.provinceId}'),
          Text('Status: ${unit.status.name}'),
          Text('Movement: ${unit.movementPoints}'),
          Text('Medals: ${unit.medals}'),
          if (hasOrders) ...[
            const SizedBox(height: 1),
            const Text('Orders:', style: TextStyle(color: Colors.yellow)),
            ...orders.map((o) => Text(
              '  -> ${o.destinationProvinceId}',
              style: const TextStyle(color: Colors.cyan),
            )),
          ],
        ],
      ),
    );
  }

  Component _buildCommandBar(List<Unit> units, Unit? selectedUnit) {
    final isInputMode = _inputMode != 'none';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: isInputMode
          ? Row(
              children: [
                Text(
                  'Target: ${_getAdjacentProvinces(selectedUnit!).isNotEmpty ? _getAdjacentProvinces(selectedUnit)[_selectedAdjacentIndex] : "none"}',
                  style: const TextStyle(color: Colors.yellow),
                ),
                const Text(' [Y]es [N]o '),
              ],
            )
          : Row(
              children: [
                const Text('['),
                Text('↑↓', style: TextStyle(color: Colors.cyan)),
                const Text(']nav '),
                const Text('['),
                Text('m', style: TextStyle(color: Colors.cyan)),
                const Text(']ove '),
                const Text('['),
                Text('a', style: TextStyle(color: Colors.cyan)),
                const Text(']ttack '),
                const Text('['),
                Text('c', style: TextStyle(color: Colors.cyan)),
                const Text(']lear '),
                const Text('['),
                Text('Esc', style: TextStyle(color: Colors.cyan)),
                const Text(']ack'),
              ],
            ),
    );
  }
}