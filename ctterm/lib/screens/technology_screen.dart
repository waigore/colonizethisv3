// Technology screen — research panel. SPEC/tui/screens/technology.md.

import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:ctterm/ctterm_routes.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

final _log = tuiLogger();

/// Technology research panel.
/// Shows research slots, available techs, and allows assigning research.
class TechnologyScreen extends StatefulComponent {
  const TechnologyScreen({
    super.key,
    required this.game,
    required this.orders,
    required this.onNavigate,
    required this.onOrdersChanged,
  });

  final Game game;
  final Orders orders;
  final void Function(CttermRoute) onNavigate;
  final void Function(Orders orders) onOrdersChanged;

  @override
  State<TechnologyScreen> createState() => _TechnologyScreenState();
}

class _TechnologyScreenState extends State<TechnologyScreen> {
  // Selected slot (0-based index)
  int _selectedSlot = 0;
  // Selected tech in available list
  int _selectedTechIndex = 0;
  // Category filter
  String _categoryFilter = 'all';
  // Show cancel confirmation
  bool _showCancelConfirm = false;
  // Feedback message (for errors, etc.)
  String _feedbackMessage = '';

  // Categories for filtering
  static const _categories = [
    'all',
    'gathering',
    'transport',
    'labour',
    'diplomacy',
    'naval',
    'military',
    'newWorld',
  ];

  // Get human player ID
  String get _humanPlayerId {
    for (final entry in component.game.aiControlByGpId.entries) {
      if (entry.value == false) return entry.key;
    }
    return component.game.players.isNotEmpty ? component.game.players.first.id : '';
  }

  // Get human player
  Player? get _humanPlayer {
    final humanId = _humanPlayerId;
    for (final player in component.game.players) {
      if (player.id == humanId) return player;
    }
    return null;
  }

  // Get research slots (default 3)
  int get _researchSlots => _humanPlayer?.researchSlots ?? 3;

  // Get tech unlocked map
  Map<String, bool> get _techUnlocked => _humanPlayer?.techUnlocked ?? {};

  // Get research progress map
  Map<String, int> get _researchProgress =>
      _humanPlayer?.researchProgressByTechId ?? {};

  // Get current research orders for human player
  List<ResearchOrder> get _researchOrders {
    return component.orders.researchOrdersByPlayerId[_humanPlayerId] ?? [];
  }

  // Get funding level for a slot
  ResearchFundingLevel _getFundingForSlot(int slotIndex) {
    for (final order in _researchOrders) {
      if (order.slotIndex == slotIndex) return order.funding;
    }
    return ResearchFundingLevel.none;
  }

  // Get tech assigned to a slot
  String? _getTechForSlot(int slotIndex) {
    for (final order in _researchOrders) {
      if (order.slotIndex == slotIndex) {
        return order.techId.isNotEmpty ? order.techId : null;
      }
    }
    return null;
  }

  // Get filtered available techs (researchable = prereqs + discovery when applicable). SPEC/game/tech-tree.md.
  List<TechDefinition> get _availableTechs {
    final techs = <TechDefinition>[];
    final unlocked = _techUnlocked;
    final currentResearch = _researchOrders.map((o) => o.techId).toSet();
    final researchableIds = researchableTechIds(
      unlocked,
      hasDiscoveredResource: (r) =>
          hasRevealedResourceForPlayer(component.game, _humanPlayerId, r),
    );

    for (final tech in techCatalog.values) {
      // Skip if category doesn't match
      if (_categoryFilter != 'all' && tech.category != _categoryFilter) {
        continue;
      }

      // Skip if not researchable (prereqs or discovery)
      if (!researchableIds.contains(tech.id)) continue;

      // Skip if already unlocked
      if (unlocked[tech.id] == true) continue;

      // Skip if already being researched
      if (currentResearch.contains(tech.id)) continue;

      techs.add(tech);
    }

    // Sort by era, then name
    techs.sort((a, b) {
      final eraComp = a.era.compareTo(b.era);
      if (eraComp != 0) return eraComp;
      return a.id.compareTo(b.id);
    });

    return techs;
  }

  // Get unlocked tech count
  int get _unlockedCount {
    int count = 0;
    for (final unlocked in _techUnlocked.values) {
      if (unlocked) count++;
    }
    return count;
  }

  // Total tech count
  int get _totalTechCount => techCatalog.length;

  // Assign tech to slot
  void _assignTech(String techId) {
    if (techId.isEmpty) return;

    // Validate prerequisites per SPEC/tui/screens/technology.md lines 118-120
    final techDef = techCatalog[techId];
    if (techDef != null && techDef.prerequisiteIds.isNotEmpty) {
      final unlocked = _techUnlocked;
      final missing = <String>[];
      for (final prereqId in techDef.prerequisiteIds) {
        if (unlocked[prereqId] != true) {
          missing.add(techById(prereqId)?.id ?? prereqId);
        }
      }
      if (missing.isNotEmpty) {
        setState(() {
          _feedbackMessage = 'Prerequisites not met: ${missing.join(', ')}';
        });
        _log.d('failed to assign $techId - missing prerequisites: $missing');
        return;
      }
    }

    // Clear any previous feedback
    setState(() {
      _feedbackMessage = '';
    });

    final humanId = _humanPlayerId;
    final currentOrders = List<ResearchOrder>.from(_researchOrders);

    // Find existing order for this slot
    final existingIndex = currentOrders.indexWhere((o) => o.slotIndex == _selectedSlot);

    final newOrder = ResearchOrder(
      slotIndex: _selectedSlot,
      techId: techId,
      funding: existingIndex >= 0 ? currentOrders[existingIndex].funding : ResearchFundingLevel.medium,
    );

    if (existingIndex >= 0) {
      currentOrders[existingIndex] = newOrder;
    } else {
      currentOrders.add(newOrder);
    }

    final newOrdersByPlayerId = Map<String, List<ResearchOrder>>.from(
      component.orders.researchOrdersByPlayerId,
    );
    newOrdersByPlayerId[humanId] = currentOrders;

    final newOrders = Orders(
      moveOrdersByPlayerId: component.orders.moveOrdersByPlayerId,
      buildUnitOrdersByPlayerId: component.orders.buildUnitOrdersByPlayerId,
      workOrdersByPlayerId: component.orders.workOrdersByPlayerId,
      diplomaticOrdersByPlayerId: component.orders.diplomaticOrdersByPlayerId,
      researchOrdersByPlayerId: newOrdersByPlayerId,
      navalMoveOrdersByPlayerId: component.orders.navalMoveOrdersByPlayerId,
      navalMissionOrdersByPlayerId: component.orders.navalMissionOrdersByPlayerId,
    );

    component.onOrdersChanged(newOrders);
    _log.d('assigned $techId to slot ${_selectedSlot + 1}');
  }

  // Set funding level for slot
  void _setFunding(ResearchFundingLevel level) {
    final humanId = _humanPlayerId;
    final currentOrders = List<ResearchOrder>.from(_researchOrders);

    final existingIndex = currentOrders.indexWhere((o) => o.slotIndex == _selectedSlot);
    if (existingIndex < 0) return; // No tech in slot

    final existing = currentOrders[existingIndex];
    final updated = ResearchOrder(
      slotIndex: existing.slotIndex,
      techId: existing.techId,
      funding: level,
    );
    currentOrders[existingIndex] = updated;

    final newOrdersByPlayerId = Map<String, List<ResearchOrder>>.from(
      component.orders.researchOrdersByPlayerId,
    );
    newOrdersByPlayerId[humanId] = currentOrders;

    final newOrders = Orders(
      moveOrdersByPlayerId: component.orders.moveOrdersByPlayerId,
      buildUnitOrdersByPlayerId: component.orders.buildUnitOrdersByPlayerId,
      workOrdersByPlayerId: component.orders.workOrdersByPlayerId,
      diplomaticOrdersByPlayerId: component.orders.diplomaticOrdersByPlayerId,
      researchOrdersByPlayerId: newOrdersByPlayerId,
      navalMoveOrdersByPlayerId: component.orders.navalMoveOrdersByPlayerId,
      navalMissionOrdersByPlayerId: component.orders.navalMissionOrdersByPlayerId,
    );

    component.onOrdersChanged(newOrders);
    _log.d('set funding ${level.name} for slot ${_selectedSlot + 1}');
  }

  // Cancel research in slot
  void _cancelResearch() {
    final humanId = _humanPlayerId;
    final currentOrders = List<ResearchOrder>.from(_researchOrders);

    currentOrders.removeWhere((o) => o.slotIndex == _selectedSlot);

    final newOrdersByPlayerId = Map<String, List<ResearchOrder>>.from(
      component.orders.researchOrdersByPlayerId,
    );
    newOrdersByPlayerId[humanId] = currentOrders;

    final newOrders = Orders(
      moveOrdersByPlayerId: component.orders.moveOrdersByPlayerId,
      buildUnitOrdersByPlayerId: component.orders.buildUnitOrdersByPlayerId,
      workOrdersByPlayerId: component.orders.workOrdersByPlayerId,
      diplomaticOrdersByPlayerId: component.orders.diplomaticOrdersByPlayerId,
      researchOrdersByPlayerId: newOrdersByPlayerId,
      navalMoveOrdersByPlayerId: component.orders.navalMoveOrdersByPlayerId,
      navalMissionOrdersByPlayerId: component.orders.navalMissionOrdersByPlayerId,
    );

    component.onOrdersChanged(newOrders);
    setState(() => _showCancelConfirm = false);
    _log.d('cancelled slot ${_selectedSlot + 1}');
  }

  @override
  Component build(BuildContext context) {
    final techs = _availableTechs;
    final slots = _researchSlots;

    // Clamp selected indices
    if (_selectedSlot >= slots) _selectedSlot = slots - 1;
    if (_selectedSlot < 0) _selectedSlot = 0;
    if (_selectedTechIndex >= techs.length) _selectedTechIndex = techs.isEmpty ? 0 : techs.length - 1;

    return Focusable(
      focused: true,
      onKeyEvent: _handleKeyEvent,
      child: _showCancelConfirm
          ? _buildCancelConfirm()
          : _buildMainPanel(techs, slots),
    );
  }

  Component _buildCancelConfirm() {
    return Container(
      padding: const EdgeInsets.all(1),
      child: Column(
        children: [
          const Text('Cancel research? Progress will be lost.'),
          const SizedBox(height: 1),
          const Text('[Y] Yes  [N] No'),
        ],
      ),
    );
  }

  Component _buildMainPanel(List<TechDefinition> techs, int slots) {
    return Container(
      padding: const EdgeInsets.all(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text('Technology'),
              const SizedBox(width: 2),
              Text(
                'Turn ${component.game.worldState.turnState.turnNumber}',
                style: TextStyle(color: Colors.gray),
              ),
              const Spacer(),
              const Text('[Esc: Back]'),
            ],
          ),
          Text('─' * 60),

          // Feedback message
          if (_feedbackMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(
                _feedbackMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          // Research Slots
          Text('Research Slots (${_selectedSlot + 1}/$slots)'),
          _buildSlotsTable(slots),
          const SizedBox(height: 1),

          // Available Techs with filter
          Row(children: [
            Text('Available Techs (filter: ${_categoryFilter.toUpperCase()})'),
            const Spacer(),
            const Text('[Tab]'),
          ]),
          _buildTechsList(techs),
          const SizedBox(height: 1),

          // Footer
          Text('Unlocked Techs: $_unlockedCount/$_totalTechCount'),
          const Text('[F1-F4: Slot] [Enter: Assign] [1-5: Funding] [Del: Cancel] [Tab: Filter] [W/S: Scroll]'),
        ],
      ),
    );
  }

  Component _buildSlotsTable(int slots) {
    final rows = <Component>[];

    // Header row
    rows.add(Row(children: [
      const Text('Slot ', style: TextStyle(fontWeight: FontWeight.bold)),
      const Text('Tech ', style: TextStyle(fontWeight: FontWeight.bold)),
      const Text('Funding ', style: TextStyle(fontWeight: FontWeight.bold)),
      const Text('Progress ', style: TextStyle(fontWeight: FontWeight.bold)),
    ]));

    // Slot rows
    for (int i = 0; i < slots; i++) {
      final techId = _getTechForSlot(i);
      final funding = _getFundingForSlot(i);
      final isSelected = i == _selectedSlot;

      final techDef = techId != null ? techById(techId) : null;
      final progress = techId != null ? (_researchProgress[techId] ?? 0) : 0;
      final cost = techDef?.cost ?? 0;
      final progressBar = _renderProgressBar(progress, cost);

      final label = isSelected ? '▶ ' : '  ';

      rows.add(Row(children: [
        Text('$label${i + 1} '),
        Text(techId ?? '— Empty —'),
        Text(' '),
        Text(_fundingLabel(funding)),
        Text(' '),
        Text(progressBar),
        Text(' $progress/$cost RP'),
      ]));
    }

    return Column(children: rows);
  }

  String _renderProgressBar(int progress, int cost) {
    if (cost == 0) return '—';
    final percent = (progress / cost).clamp(0.0, 1.0);
    final filled = (percent * 10).round();
    final empty = 10 - filled;
    return '█' * filled + '░' * empty;
  }

  String _fundingLabel(ResearchFundingLevel level) {
    switch (level) {
      case ResearchFundingLevel.none:
        return 'None';
      case ResearchFundingLevel.low:
        return 'Low';
      case ResearchFundingLevel.medium:
        return 'Medium';
      case ResearchFundingLevel.high:
        return 'High';
      case ResearchFundingLevel.maximum:
        return 'Maximum';
    }
  }

  Component _buildTechsList(List<TechDefinition> techs) {
    if (techs.isEmpty) {
      return const Text('  (no available techs in this category)');
    }

    final rows = <Component>[];

    // Header
    rows.add(Row(children: [
      const Text('Era ', style: TextStyle(fontWeight: FontWeight.bold)),
      const Text('Tech ', style: TextStyle(fontWeight: FontWeight.bold)),
      const Text('Cost ', style: TextStyle(fontWeight: FontWeight.bold)),
      const Text('Prereqs ', style: TextStyle(fontWeight: FontWeight.bold)),
    ]));

    // Tech rows (limit to 10 for now)
    final displayTechs = techs.take(10).toList();
    for (int i = 0; i < displayTechs.length; i++) {
      final tech = displayTechs[i];
      final isSelected = i == _selectedTechIndex;

      final label = isSelected ? '▶ ' : '  ';
      final prereqStr = tech.prerequisiteIds.isEmpty
          ? '—'
          : tech.prerequisiteIds.map((p) => techById(p)?.id ?? p).join(', ');

      rows.add(Row(children: [
        Text('$label${tech.era} '),
        Text(tech.id.replaceAll('_', ' ')),
        Text(' ${tech.cost} '),
        Text(prereqStr),
      ]));
    }

    if (techs.length > 10) {
      rows.add(Text('  ... (${techs.length - 10} more)'));
    }

    return Column(children: rows);
  }

  // ignore: strict_top_level_inference
  bool _handleKeyEvent(event) {
    final key = event.logicalKey;
    final c = event.character?.toLowerCase();

    // Handle cancel confirmation
    if (_showCancelConfirm) {
      if (c == 'y') {
        _cancelResearch();
        return true;
      } else if (c == 'n' || key == LogicalKey.escape) {
        setState(() => _showCancelConfirm = false);
        return true;
      }
      return false;
    }

    // Escape or Q - back
    if (key == LogicalKey.escape || c == 'q') {
      component.onNavigate(CttermRoute.inGameShell);
      return true;
    }

    // F1-F4 - select slot
    if (key == LogicalKey.f1) {
      setState(() => _selectedSlot = 0);
      return true;
    } else if (key == LogicalKey.f2) {
      setState(() => _selectedSlot = 1);
      return true;
    } else if (key == LogicalKey.f3) {
      setState(() => _selectedSlot = 2);
      return true;
    } else if (key == LogicalKey.f4) {
      if (_researchSlots >= 4) {
        setState(() => _selectedSlot = 3);
      }
      return true;
    }

    // 1-5 - funding levels
    if (c == '1') {
      _setFunding(ResearchFundingLevel.none);
      return true;
    } else if (c == '2') {
      _setFunding(ResearchFundingLevel.low);
      return true;
    } else if (c == '3') {
      _setFunding(ResearchFundingLevel.medium);
      return true;
    } else if (c == '4') {
      _setFunding(ResearchFundingLevel.high);
      return true;
    } else if (c == '5') {
      _setFunding(ResearchFundingLevel.maximum);
      return true;
    }

    // Delete or C - cancel research
    if (key == LogicalKey.delete || c == 'c') {
      final techId = _getTechForSlot(_selectedSlot);
      if (techId != null) {
        setState(() => _showCancelConfirm = true);
      }
      return true;
    }

    // Tab - cycle category
    if (key == LogicalKey.tab) {
      final currentIdx = _categories.indexOf(_categoryFilter);
      final nextIdx = (currentIdx + 1) % _categories.length;
      setState(() {
        _categoryFilter = _categories[nextIdx];
        _selectedTechIndex = 0;
      });
      return true;
    }

    // Up/Down or W/S - navigate tech list
    if (c == 'w' || key == LogicalKey.arrowUp) {
      setState(() {
        if (_selectedTechIndex > 0) _selectedTechIndex--;
      });
      return true;
    } else if (c == 's' || key == LogicalKey.arrowDown) {
      final techs = _availableTechs;
      setState(() {
        if (_selectedTechIndex < techs.length - 1 && _selectedTechIndex < 9) {
          _selectedTechIndex++;
        }
      });
      return true;
    }

    // Enter - assign tech
    if (key == LogicalKey.enter) {
      final techs = _availableTechs;
      if (_selectedTechIndex < techs.length) {
        _assignTech(techs[_selectedTechIndex].id);
      }
      return true;
    }

    return false;
  }
}
