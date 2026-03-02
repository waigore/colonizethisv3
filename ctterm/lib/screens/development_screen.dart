// Development Screen: manage civilian unit work orders. SPEC/tui/screens/development.md.

import 'package:logger/logger.dart' as log_pkg;
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:ctterm/ctterm_routes.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

final log_pkg.Logger _log = log_pkg.Logger();

/// Valid work targets per spec.
const _validWorkTargets = {
  'build_improvement': 'Build Improvement',
  'build_road': 'Build Road',
  'build_port': 'Build Port',
  'build_fort': 'Build Fort',
  'build_rail': 'Build Railroad',
  'upgrade_town': 'Upgrade Town',
};

/// Development screen for managing civilian unit work orders.
class DevelopmentScreen extends StatefulComponent {
  const DevelopmentScreen({
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
  State<DevelopmentScreen> createState() => _DevelopmentScreenState();
}

class _DevelopmentScreenState extends State<DevelopmentScreen> {
  /// Currently selected unit index in the list.
  int _selectedIndex = 0;
  
  /// Current input mode: none, selectingWorkTarget.
  String _inputMode = 'none';
  
  /// Feedback message to display (e.g., order accepted/rejected).
  String _feedbackMessage = '';
  
  /// Color for feedback message.
  Color _feedbackColor = Colors.white;

  /// Check if a unit is a civilian unit (Builder, Engineer).
  bool _isCivilianUnit(Unit unit) {
    final type = unit.type.toLowerCase();
    return type.contains('builder') || type.contains('engineer');
  }

  /// Get all civilian units for the human player.
  List<Unit> get _playerCivilianUnits {
    final humanPlayerId = _getHumanPlayerId();
    if (humanPlayerId == null) return [];
    
    // Civilian units are Builders and Engineers
    final allUnits = <Unit>[];
    allUnits.addAll(component.game.worldState.oldWorld.units
        .where((u) => u.ownerId == humanPlayerId && _isCivilianUnit(u)));
    allUnits.addAll(component.game.worldState.newWorld.units
        .where((u) => u.ownerId == humanPlayerId && _isCivilianUnit(u)));
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

  String _provinceLabel(String fullProvinceId) {
    final world = component.game.worldState;
    for (final p in world.oldWorld.provinces) {
      if (p.id == fullProvinceId) {
        return p.displayName ?? p.id;
      }
    }
    for (final p in world.newWorld.provinces) {
      if (p.id == fullProvinceId) {
        return p.displayName ?? p.id;
      }
    }
    return fullProvinceId;
  }

  /// Get province name for a unit using its effective location province id.
  String _getProvinceName(Unit unit) {
    final fullProvinceId = unit.locationProvinceId;
    return _provinceLabel(fullProvinceId);
  }

  /// Get the current player's work orders for civilian units.
  List<WorkOrder> _getPlayerWorkOrders() {
    final playerId = _getHumanPlayerId();
    if (playerId == null) return [];
    return component.orders.workOrdersByPlayerId[playerId] ?? [];
  }

  /// Get work order for a specific unit, if any.
  WorkOrder? _getWorkOrderForUnit(String unitId) {
    return _getPlayerWorkOrders().where((o) => o.unitId == unitId).firstOrNull;
  }

  /// Check if a unit has pending work orders.
  bool _unitHasWorkOrder(String unitId) {
    return _getWorkOrderForUnit(unitId) != null;
  }

  /// Handle keyboard input.
  // Type is inferred from Nocterm's Focusable.onKeyEvent callback
  // ignore: strict_top_level_inference
  bool _handleKeyEvent(event) {
    final key = event.logicalKey;
    final c = event.character?.toLowerCase();
    final units = _playerCivilianUnits;
    
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

    // Navigation: arrow keys / j/k to navigate unit list
    if (key == LogicalKey.arrowUp || c == 'k') {
      setState(() => _selectedIndex = (_selectedIndex - 1).clamp(0, units.length - 1));
      return true;
    }
    if (key == LogicalKey.arrowDown || c == 'j') {
      setState(() => _selectedIndex = (_selectedIndex + 1).clamp(0, units.length - 1));
      return true;
    }

    // Enter/Space: enter work target selection mode if unit is idle
    if (key == LogicalKey.enter || key == LogicalKey.space) {
      final unit = units[_selectedIndex];
      if (!_unitHasWorkOrder(unit.id)) {
        setState(() {
          _inputMode = 'selectingWorkTarget';
          _feedbackMessage = 'Select work target (i/r/p/f/R/u)';
          _feedbackColor = Colors.cyan;
        });
      }
      return true;
    }

    // Work target selection mode
    if (_inputMode == 'selectingWorkTarget') {
      return _handleWorkTargetSelection(c, units[_selectedIndex]);
    }

    // x: cancel work order for selected unit
    if (c == 'x') {
      final unit = units[_selectedIndex];
      _cancelWorkOrder(unit.id);
      return true;
    }

    // Direct work target keys (even without Enter)
    if (_validWorkTargets.containsKey(c)) {
      final unit = units[_selectedIndex];
      if (!_unitHasWorkOrder(unit.id)) {
        _assignWorkOrder(unit, c!);
        return true;
      }
    }

    return false;
  }

  /// Handle work target selection keys.
  bool _handleWorkTargetSelection(String? c, Unit unit) {
    if (_validWorkTargets.containsKey(c)) {
      _assignWorkOrder(unit, c!);
      return true;
    }
    return false;
  }

  /// Assign a work order to a unit.
  void _assignWorkOrder(Unit unit, String target) {
    final playerId = _getHumanPlayerId();
    if (playerId == null) return;

    // Create new work order
    final order = WorkOrder(
      unitId: unit.id,
      target: target,
      targetTileKey: unit.provinceId, // Use province as default target
    );

    // Add to existing orders
    final existingOrders = component.orders.workOrdersByPlayerId[playerId] ?? [];
    final updatedOrders = [...existingOrders, order];
    
    final newOrders = Orders(
      moveOrdersByPlayerId: component.orders.moveOrdersByPlayerId,
      buildUnitOrdersByPlayerId: component.orders.buildUnitOrdersByPlayerId,
      workOrdersByPlayerId: {
        ...component.orders.workOrdersByPlayerId,
        playerId: updatedOrders,
      },
      diplomaticOrdersByPlayerId: component.orders.diplomaticOrdersByPlayerId,
      researchOrdersByPlayerId: component.orders.researchOrdersByPlayerId,
      navalMoveOrdersByPlayerId: component.orders.navalMoveOrdersByPlayerId,
      navalMissionOrdersByPlayerId: component.orders.navalMissionOrdersByPlayerId,
    );

    component.onOrdersChanged(newOrders);
    
    setState(() {
      _inputMode = 'none';
      _feedbackMessage = 'Work order assigned: ${_getWorkTargetName(target)}';
      _feedbackColor = Colors.green;
    });
    
    _log.d('tui:development: assigned $target to unit ${unit.id}');
  }

  /// Cancel a work order for a unit.
  void _cancelWorkOrder(String unitId) {
    final playerId = _getHumanPlayerId();
    if (playerId == null) return;

    final existingOrders = component.orders.workOrdersByPlayerId[playerId] ?? [];
    final updatedOrders = existingOrders.where((o) => o.unitId != unitId).toList();
    
    final newOrders = Orders(
      moveOrdersByPlayerId: component.orders.moveOrdersByPlayerId,
      buildUnitOrdersByPlayerId: component.orders.buildUnitOrdersByPlayerId,
      workOrdersByPlayerId: {
        ...component.orders.workOrdersByPlayerId,
        playerId: updatedOrders,
      },
      diplomaticOrdersByPlayerId: component.orders.diplomaticOrdersByPlayerId,
      researchOrdersByPlayerId: component.orders.researchOrdersByPlayerId,
      navalMoveOrdersByPlayerId: component.orders.navalMoveOrdersByPlayerId,
      navalMissionOrdersByPlayerId: component.orders.navalMissionOrdersByPlayerId,
    );

    component.onOrdersChanged(newOrders);
    
    setState(() {
      _feedbackMessage = 'Work order cancelled (no refund)';
      _feedbackColor = Colors.yellow;
    });
    
    _log.d('tui:development: cancelled work order for unit $unitId');
  }

  /// Get display name for work target.
  String _getWorkTargetName(String target) {
    return _validWorkTargets[target] ?? target;
  }

  @override
  Component build(BuildContext context) {
    final units = _playerCivilianUnits;
    final selectedUnit = units.isNotEmpty ? units[_selectedIndex] : null;
    final workOrder = selectedUnit != null ? _getWorkOrderForUnit(selectedUnit.id) : null;

    return Focusable(
      focused: true,
      onKeyEvent: _handleKeyEvent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            color: const Color(0xFF1a1a2e),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: Row(
              children: [
                const Text(
                  ' Development ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(' | Civilian Units | ', style: TextStyle(color: Colors.gray)),
                _buildHelpText(),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: units.isEmpty
                ? const Center(
                    child: Text(
                      'No civilian units available',
                      style: TextStyle(color: Colors.gray),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Unit list
                      Expanded(
                        flex: 2,
                        child: _buildUnitList(units),
                      ),
                      const SizedBox(width: 1),
                      // Detail panel
                      Expanded(
                        flex: 3,
                        child: _buildDetailPanel(selectedUnit, workOrder),
                      ),
                    ],
                  ),
          ),
          // Feedback line
          if (_feedbackMessage.isNotEmpty)
            Container(
              color: const Color(0xFF1a1a2e),
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
              child: Text(
                // ignore: prefer_interpolation_to_compose_strings
                ' ' + _feedbackMessage,
                style: TextStyle(color: _feedbackColor),
              ),
            ),
        ],
      ),
    );
  }

  /// Build help text for current mode.
  Component _buildHelpText() {
    if (_inputMode == 'selectingWorkTarget') {
      return const Text(
        '[i]mprove [r]oad [p]ort [f]ort [R]ail [u]pgrade [x]ancel [Esc]back',
        style: TextStyle(color: Colors.cyan),
      );
    }
    return const Text(
      '[↑/↓/j/k]nav [Ent]assign [x]cancel [Esc]back',
      style: TextStyle(color: Colors.gray),
    );
  }

  /// Build the civilian unit list.
  Component _buildUnitList(List<Unit> units) {
    return Container(
      color: const Color(0xFF0d0d1a),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(1),
            color: const Color(0xFF1a1a2e),
            child: const Text(
              ' UNIT ',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: units.length,
              itemBuilder: (context, index) {
                final unit = units[index];
                final isSelected = index == _selectedIndex;
                final hasWork = _unitHasWorkOrder(unit.id);
                final workOrder = _getWorkOrderForUnit(unit.id);
                
                String status = 'idle';
                if (hasWork && workOrder != null) {
                  status = _getWorkTargetName(workOrder.target);
                }
                
                final bg = isSelected ? const Color(0xFF2a2a4e) : null;
                final fg = isSelected ? Colors.white : Colors.gray;
                
                return Container(
                  color: bg,
                  padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
                  child: Row(
                    children: [
                      if (isSelected)
                        const Text('> ', style: TextStyle(color: Colors.yellow))
                      else
                        const Text('  '),
                      Expanded(
                        child: Text(
                          '${unit.type} @ ${_getProvinceName(unit)}',
                          style: TextStyle(color: fg),
                        ),
                      ),
                      Text(
                        hasWork ? '[${status.substring(0, status.length.clamp(0, 8))}]' : '[idle]',
                        style: TextStyle(
                          color: hasWork ? Colors.cyan : Colors.gray,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build the detail panel for selected unit.
  Component _buildDetailPanel(Unit? unit, WorkOrder? workOrder) {
    if (unit == null) {
      return Container(
        color: const Color(0xFF0d0d1a),
        child: const Center(
          child: Text(
            'Select a unit to view details',
            style: TextStyle(color: Colors.gray),
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFF0d0d1a),
      padding: const EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unit header
          Container(
            width: double.infinity,
            color: const Color(0xFF1a1a2e),
            padding: const EdgeInsets.all(1),
            child: Text(
              ' ${unit.type.toUpperCase()} ',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 1),
          // Unit details
          const SizedBox(height: 1),
          _buildDetailRow('Unit ID', unit.id),
          _buildDetailRow('Location', _getProvinceName(unit)),
          _buildDetailRow('Type', _isCivilianUnit(unit) ? 'Civilian' : 'Military'),
          _buildDetailRow('Status', workOrder != null ? 'Working' : 'Idle'),
          if (workOrder != null) ...[
            const SizedBox(height: 1),
            _buildDetailRow('Work Target', _getWorkTargetName(workOrder.target)),
            _buildDetailRow('Target Tile', workOrder.targetTileKey),
          ],
          const SizedBox(height: 1),
          // Available work targets
          const Text(' Available Work: ', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 1),
          for (final entry in _validWorkTargets.entries)
            Padding(
              padding: const EdgeInsets.only(left: 1),
              child: Text(
                '[${entry.key}] ${entry.value}',
                style: TextStyle(
                  color: workOrder == null ? Colors.gray : const Color(0xFF333344),
                ),
              ),
            ),
          const Spacer(),
          // Current mode hint
          if (_inputMode == 'selectingWorkTarget')
            Container(
              width: double.infinity,
              color: const Color(0xFF2a2a4e),
              padding: const EdgeInsets.all(1),
              child: const Text(
                ' Select work target... ',
                style: TextStyle(color: Colors.cyan),
              ),
            ),
        ],
      ),
    );
  }

  /// Build a detail row.
  Component _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(left: 1),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.gray),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
