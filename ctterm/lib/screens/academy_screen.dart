// Academy Screen: train military regiments. SPEC/tui/screens/academy.md.

import 'package:nocterm/nocterm.dart' hide Logger;

import 'package:ctterm/ctterm_routes.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';



/// Display info for a regiment type in the Academy.
class RegimentDisplayInfo {
  final String id;
  final String name;
  final String category;
  final int era;
  final int cost;
  final Map<String, int> inputs;
  final int foodUpkeep;
  final int fpn;
  final int fpm;
  final int rng;
  final int def;
  final int mvr;
  final String? requiredTech;
  final bool isAvailable;

  const RegimentDisplayInfo({
    required this.id,
    required this.name,
    required this.category,
    required this.era,
    required this.cost,
    required this.inputs,
    required this.foodUpkeep,
    required this.fpn,
    required this.fpm,
    required this.rng,
    required this.def,
    required this.mvr,
    this.requiredTech,
    required this.isAvailable,
  });
}

/// Training order display info.
class TrainingOrderInfo {
  final String regimentId;
  final String regimentName;
  final String provinceId;
  final int turnsRemaining;

  const TrainingOrderInfo({
    required this.regimentId,
    required this.regimentName,
    required this.provinceId,
    required this.turnsRemaining,
  });
}

/// Academy screen for training military regiments.
class AcademyScreen extends StatefulComponent {
  const AcademyScreen({
    super.key,
    required this.game,
    required this.orders,
    required this.onNavigate,
    required this.onOrdersChanged,
  });

  final Game game;
  final Orders orders;
  final void Function(CttermRoute) onNavigate;
  final void Function(Orders) onOrdersChanged;

  @override
  State<AcademyScreen> createState() => _AcademyScreenState();
}

class _AcademyScreenState extends State<AcademyScreen> {
  /// Currently selected regiment index in the list.
  int _selectedIndex = 0;

  /// Current input mode: 'none', 'train', 'cancel'.
  String _inputMode = 'none';

  /// Feedback message to display.
  String _feedbackMessage = '';

  /// Color for feedback message.
  Color _feedbackColor = Colors.white;

  /// Province input buffer.
  String _provinceInput = '';

  /// Get the human player's ID.
  String? _getHumanPlayerId() {
    for (final entry in component.game.aiControlByGpId.entries) {
      if (!entry.value) return entry.key;
    }
    return component.game.players.isNotEmpty
        ? component.game.players.first.id
        : null;
  }

  /// Get the human player's data.
  Player? _getHumanPlayer() {
    final playerId = _getHumanPlayerId();
    if (playerId == null) return null;
    for (final player in component.game.players) {
      if (player.id == playerId) return player;
    }
    return null;
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

  /// Get all regiment display info, filtered by tech availability.
  List<RegimentDisplayInfo> _getRegimentList() {
    final player = _getHumanPlayer();
    final techUnlocked = player?.techUnlocked;
    final unlockMap = unlockingTechByRegimentId;

    final result = <RegimentDisplayInfo>[];
    for (final stats in regimentCatalog) {
      final economy = _getEconomyForRegiment(stats.id);
      final requiredTech = unlockMap[stats.id];
      final isAvailable = requiredTech == null ||
          (techUnlocked?[requiredTech] ?? false);

      result.add(RegimentDisplayInfo(
        id: stats.id,
        name: _formatRegimentName(stats.id),
        category: stats.category.name,
        era: stats.era,
        cost: economy?.buildTreasuryCost ?? 0,
        inputs: economy?.buildInputs.map(
              (key, value) => MapEntry(key, value),
            ) ??
            {},
        foodUpkeep: economy?.foodUpkeep ?? 0,
        fpn: stats.fpn,
        fpm: stats.fpm,
        rng: stats.rng,
        def: stats.def,
        mvr: stats.mvr,
        requiredTech: requiredTech,
        isAvailable: isAvailable,
      ));
    }
    return result;
  }

  /// Get economy for a regiment type.
  RegimentEconomy? _getEconomyForRegiment(String id) {
    switch (id) {
      case 'peasant_levies':
        return RegimentEconomyCatalog.peasantLevies;
      case 'pikemen':
        return RegimentEconomyCatalog.pikemen;
      case 'arquebusiers':
        return RegimentEconomyCatalog.arquebusiers;
      case 'bowmen':
        return RegimentEconomyCatalog.bowmen;
      case 'squires':
        return RegimentEconomyCatalog.squires;
      case 'knights':
        return RegimentEconomyCatalog.knights;
      case 'culverin':
        return RegimentEconomyCatalog.culverin;
      case 'calivermen':
        return RegimentEconomyCatalog.calivermen;
      case 'halberdiers':
        return RegimentEconomyCatalog.halberdiers;
      case 'musketeers':
        return RegimentEconomyCatalog.musketeers;
      case 'cossacks':
        return RegimentEconomyCatalog.cossacks;
      case 'lancers':
        return RegimentEconomyCatalog.lancers;
      case 'harquebusiers':
        return RegimentEconomyCatalog.harquebusiers;
      case 'horse_artillery':
        return RegimentEconomyCatalog.horseArtillery;
      default:
        return null;
    }
  }

  /// Format regiment ID to display name.
  String _formatRegimentName(String id) {
    return id.replaceAll('_', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  /// Get the current training queue for the human player.
  List<TrainingOrderInfo> _getTrainingQueue() {
    final playerId = _getHumanPlayerId();
    if (playerId == null) return [];

    final orders = component.orders.buildUnitOrdersByPlayerId[playerId] ?? [];
    return orders.where((o) => o.isMilitary).map((order) {
      return TrainingOrderInfo(
        regimentId: order.unitType,
        regimentName: _formatRegimentName(order.unitType),
        provinceId: order.spawnProvinceId,
        turnsRemaining: 1, // MVP: assume 1 turn per unit
      );
    }).toList();
  }

  /// Handle keyboard input.
  // Type is inferred from Nocterm's Focusable.onKeyEvent callback
  // ignore: strict_top_level_inference
  bool _handleKeyEvent(event) {
    final key = event.logicalKey;
    final c = event.character?.toLowerCase();

    if (key == LogicalKey.escape) {
      if (_inputMode != 'none') {
        setState(() {
          _inputMode = 'none';
          _provinceInput = '';
          _feedbackMessage = '';
        });
        return true;
      }
      component.onNavigate(CttermRoute.inGameShell);
      return true;
    }

    final regimentList = _getRegimentList();
    if (regimentList.isEmpty) return false;

    if (_inputMode == 'train') {
      // Province ID input mode
      if (key == LogicalKey.enter || c == 'y') {
        _confirmTraining(regimentList[_selectedIndex]);
        return true;
      } else if (key == LogicalKey.backspace || c == 'n') {
        if (key == LogicalKey.backspace) {
          setState(() {
            if (_provinceInput.isNotEmpty) {
              _provinceInput = _provinceInput.substring(0, _provinceInput.length - 1);
            }
          });
        } else {
          // 'n' to cancel
          setState(() {
            _inputMode = 'none';
            _provinceInput = '';
            _feedbackMessage = 'Cancelled';
            _feedbackColor = Colors.gray;
          });
        }
        return true;
      } else if (c != null && c.length == 1) {
        setState(() {
          _provinceInput += c;
        });
        return true;
      }
      return true;
    }

    if (_inputMode == 'cancel') {
      if (key == LogicalKey.enter || key == LogicalKey.space) {
        _confirmCancel();
        return true;
      }
      return true;
    }

    // Navigation mode
    if (key == LogicalKey.arrowUp || c == 'k') {
      setState(() {
        _selectedIndex = (_selectedIndex - 1).clamp(0, regimentList.length - 1);
      });
      return true;
    }
    if (key == LogicalKey.arrowDown || c == 'j') {
      setState(() {
        _selectedIndex = (_selectedIndex + 1).clamp(0, regimentList.length - 1);
      });
      return true;
    }
    if (key == LogicalKey.enter || key == LogicalKey.space) {
      // Select regiment - show details (already shown)
      return true;
    }
    if (key == LogicalKey.keyT) {
      // Train order
      final selected = regimentList[_selectedIndex];
      if (!selected.isAvailable) {
        setState(() {
          _feedbackMessage = 'Regiment not available (locked by tech)';
          _feedbackColor = Colors.red;
        });
        return true;
      }
      setState(() {
        _inputMode = 'train';
        _provinceInput = '';
        _feedbackMessage = 'Enter province ID for training:';
        _feedbackColor = Colors.cyan;
      });
      return true;
    }
    if (key == LogicalKey.keyC) {
      // Cancel training order
      final queue = _getTrainingQueue();
      if (queue.isEmpty) {
        setState(() {
          _feedbackMessage = 'No training orders to cancel';
          _feedbackColor = Colors.yellow;
        });
        return true;
      }
      setState(() {
        _inputMode = 'cancel';
        _feedbackMessage = 'Cancel training? Press Enter to confirm';
        _feedbackColor = Colors.cyan;
      });
      return true;
    }

    return false;
  }

  /// Confirm training order.
  void _confirmTraining(RegimentDisplayInfo regiment) {
    final playerId = _getHumanPlayerId();
    if (playerId == null) {
      setState(() {
        _feedbackMessage = 'Error: no human player found';
        _feedbackColor = Colors.red;
        _inputMode = 'none';
      });
      return;
    }

    if (_provinceInput.isEmpty) {
      setState(() {
        _feedbackMessage = 'Please enter a province ID';
        _feedbackColor = Colors.yellow;
      });
      return;
    }

    // Check if province exists and belongs to player
    final provinceExists = _provinceExists(_provinceInput);
    if (!provinceExists) {
      setState(() {
        _feedbackMessage = 'Province not found: $_provinceInput';
        _feedbackColor = Colors.red;
        _inputMode = 'none';
      });
      return;
    }

    // Create the training order
    final newOrder = BuildUnitOrder(
      unitType: regiment.id,
      isMilitary: true,
      spawnProvinceId: _provinceInput,
    );

    // Add to existing orders
    final existingOrders = component.orders;
    final playerOrders =
        existingOrders.buildUnitOrdersByPlayerId[playerId] ?? [];
    final updatedOrders = Orders(
      moveOrdersByPlayerId: existingOrders.moveOrdersByPlayerId,
      workOrdersByPlayerId: existingOrders.workOrdersByPlayerId,
      buildUnitOrdersByPlayerId: {
        ...existingOrders.buildUnitOrdersByPlayerId,
        playerId: [...playerOrders, newOrder],
      },
    );

    component.onOrdersChanged(updatedOrders);

    setState(() {
      _feedbackMessage =
          'Training ordered: ${regiment.name} in $_provinceInput';
      _feedbackColor = Colors.green;
      _inputMode = 'none';
      _provinceInput = '';
    });
  }

  /// Check if a province exists in the game world.
  bool _provinceExists(String provinceId) {
    // Check old world
    for (final p in component.game.worldState.oldWorld.provinces) {
      if (p.id == provinceId) return true;
    }
    // Check new world
    for (final p in component.game.worldState.newWorld.provinces) {
      if (p.id == provinceId) return true;
    }
    return false;
  }

  /// Confirm cancellation of training order.
  void _confirmCancel() {
    final playerId = _getHumanPlayerId();
    if (playerId == null) return;

    final queue = _getTrainingQueue();
    if (queue.isEmpty) {
      setState(() {
        _inputMode = 'none';
        _feedbackMessage = 'No training orders to cancel';
        _feedbackColor = Colors.yellow;
      });
      return;
    }

    // Cancel the first order in queue (simple MVP approach)
    final existingOrders = component.orders;
    final playerOrders =
        existingOrders.buildUnitOrdersByPlayerId[playerId] ?? [];

    if (playerOrders.isEmpty) {
      setState(() {
        _inputMode = 'none';
        _feedbackMessage = 'No training orders to cancel';
        _feedbackColor = Colors.yellow;
      });
      return;
    }

    // Remove first military unit order
    final updatedBuildOrders = <BuildUnitOrder>[];
    bool found = false;
    for (final order in playerOrders) {
      if (order.isMilitary && !found) {
        found = true; // Skip the first one
        continue;
      }
      updatedBuildOrders.add(order);
    }

    final updatedOrders = Orders(
      moveOrdersByPlayerId: existingOrders.moveOrdersByPlayerId,
      workOrdersByPlayerId: existingOrders.workOrdersByPlayerId,
      buildUnitOrdersByPlayerId: {
        ...existingOrders.buildUnitOrdersByPlayerId,
        playerId: updatedBuildOrders,
      },
    );

    component.onOrdersChanged(updatedOrders);

    setState(() {
      _inputMode = 'none';
      _feedbackMessage = 'Training order cancelled';
      _feedbackColor = Colors.green;
    });
  }

  @override
  Component build(BuildContext context) {
    final regimentList = _getRegimentList();
    final trainingQueue = _getTrainingQueue();

    return KeyboardListener(
      onKeyEvent: _handleKeyEvent,
      child: Container(
        color: Colors.black,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(1),
              color: Colors.blue,
              child: Row(
                children: [
                  const Text(
                    ' === ACADEMY === ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    ' [j/k or ↑/↓]:Nav  [t]:Train  [c]:Cancel  [Esc]:Back ',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Regiment list
                  Expanded(
                    flex: 3,
                    child: Container(
                      margin: const EdgeInsets.only(right: 1),
                      child: _buildRegimentList(regimentList),
                    ),
                  ),
                  // Training queue
                  Expanded(
                    flex: 2,
                    child: _buildTrainingQueue(trainingQueue),
                  ),
                ],
              ),
            ),
            // Feedback/message line
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
              color: Colors.grey,
              child: Row(
                children: [
                  Text(
                    _feedbackMessage.isEmpty
                        ? ' Select a regiment type to view details '
                        : ' $_feedbackMessage ',
                    style: TextStyle(color: _feedbackColor),
                  ),
                  if (_inputMode == 'train') ...[
                    const Text(' > ', style: TextStyle(color: Colors.cyan)),
                    Text(
                      _provinceInput.isEmpty ? '_' : _provinceInput,
                      style: const TextStyle(color: Colors.cyan),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the regiment list panel.
  Component _buildRegimentList(List<RegimentDisplayInfo> regiments) {
    if (regiments.isEmpty) {
      return Container(
        color: Colors.grey,
        child: const Center(
          child: Text('No regiment types available', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Container(
      color: Colors.grey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
            color: Colors.blue,
            child: const Row(
              children: [
                Text(' # ', style: TextStyle(color: Colors.white)),
                Text('Regiment', style: TextStyle(color: Colors.white)),
                Text(' Era ', style: TextStyle(color: Colors.white)),
                Text(' Cost ', style: TextStyle(color: Colors.white)),
                Text(' Status ', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          // List items
          Expanded(
            child: ListView.builder(
              itemCount: regiments.length,
              itemBuilder: (context, index) {
                final reg = regiments[index];
                final isSelected = index == _selectedIndex;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
                  color: isSelected ? Colors.blue : (index % 2 == 0 ? Colors.black : Colors.grey),
                  child: Row(
                    children: [
                      Text(
                        '${index + 1}'.padLeft(2),
                        style: TextStyle(
                          color: isSelected ? Colors.cyan : Colors.white,
                          
                        ),
                      ),
                      Text(
                        reg.name.substring(0, reg.name.length.clamp(0, 14)).padRight(14),
                        style: TextStyle(
                          color: isSelected ? Colors.cyan : Colors.white,
                          
                        ),
                      ),
                      Text(
                        '${reg.era}'.padLeft(3),
                        style: TextStyle(
                          color: isSelected ? Colors.cyan : Colors.white,
                          
                        ),
                      ),
                      Text(
                        '${reg.cost}'.padLeft(5),
                        style: TextStyle(
                          color: isSelected ? Colors.cyan : Colors.white,
                          
                        ),
                      ),
                      Text(
                        reg.isAvailable ? ' Available ' : ' Locked  ',
                        style: TextStyle(
                          color: reg.isAvailable ? Colors.green : Colors.red,
                          
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

  /// Build the training queue panel.
  Component _buildTrainingQueue(List<TrainingOrderInfo> queue) {
    return Container(
      color: Colors.grey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
            color: Colors.blue,
            child: const Row(
              children: [
                Text(' TRAINING QUEUE ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          // Selected regiment details
          _buildSelectedRegimentDetails(),
          // Queue header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
            color: Colors.grey,
            child: const Row(
              children: [
                Text(' # ', style: TextStyle(color: Colors.white)),
                Text('Regiment', style: TextStyle(color: Colors.white)),
                Text(' Province', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          // Queue items
          Expanded(
            child: queue.isEmpty
                ? const Center(
                    child: Text('No training orders',
                        style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    itemCount: queue.length,
                    itemBuilder: (context, index) {
                      final item = queue[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
                        color: index % 2 == 0 ? Colors.black : Colors.grey,
                        child: Row(
                          children: [
                            Text(
                              '${index + 1}'.padLeft(2),
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              item.regimentName.substring(0, item.regimentName.length.clamp(0, 10)).padRight(10),
                              style: const TextStyle(color: Colors.white),
                            ),
                            Text(
                              _provinceLabel(item.provinceId),
                              style: const TextStyle(color: Colors.grey),
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

  /// Build details panel for selected regiment.
  Component _buildSelectedRegimentDetails() {
    final regimentList = _getRegimentList();
    if (regimentList.isEmpty || _selectedIndex >= regimentList.length) {
      return const SizedBox.shrink();
    }

    final reg = regimentList[_selectedIndex];
    return Container(
      padding: const EdgeInsets.all(1),
      color: Colors.grey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ' DETAILS: ${reg.name} ',
            style: TextStyle(
              color: reg.isAvailable ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              
            ),
          ),
          Text(
            ' Category: ${reg.category} | Era: ${reg.era} ',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            ' Cost: ${reg.cost} gold | Upkeep: ${reg.foodUpkeep}/turn ',
            style: const TextStyle(color: Colors.white),
          ),
          Text(
            ' Inputs: ${reg.inputs.isEmpty ? "None" : reg.inputs.entries.map((e) => "${e.value} ${e.key}").join(", ")} ',
            style: const TextStyle(color: Colors.white),
          ),
          const Text(
            ' --- Tactical Stats --- ',
            style: TextStyle(color: Colors.grey),
          ),
          Text(
            ' FPN:${reg.fpn} FPM:${reg.fpm} RNG:${reg.rng} DEF:${reg.def} MVR:${reg.mvr} ',
            style: const TextStyle(color: Colors.cyan),
          ),
          if (reg.requiredTech != null)
            Text(
              reg.isAvailable
                  ? ' Unlocked: ${reg.requiredTech} '
                  : ' Requires: ${reg.requiredTech} ',
              style: TextStyle(
                color: reg.isAvailable ? Colors.green : Colors.red,
                
              ),
            ),
        ],
      ),
    );
  }
}
