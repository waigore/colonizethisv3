// Game Setup screen. SPEC/tui/screens/game-setup.md, SPEC/tui/ctterm.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:nocterm/nocterm.dart' hide Logger;

final _log = tuiLogger();

/// Number of player slots: 1 human + 5 AI.
const int _kNumSlots = 6;

/// Focus index for "enforce fair GP assignment" row (between slots and Start).
const int _kFocusFairAssignment = 6;

/// Game Setup: six player slots with nation and leader selection.
class GameSetupScreen extends StatefulComponent {
  const GameSetupScreen({
    super.key,
    required this.onStartGame,
    required this.onBack,
  });

  final void Function(
    List<String> orderedGpIdsForSlots,
    Map<String, String> leaderVariantByGpId,
    bool enforceFairGpOldWorldAssignment,
  ) onStartGame;
  final void Function() onBack;

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  /// Current focus: -1 = Start Game, -2 = Back, 0-5 = slot index, 6 = fair assignment.
  int _focusIndex = 0;

  var _enforceFairGpOldWorldAssignment = false;
  
  /// For each slot: selected GP id (empty = none).
  late List<String> _orderedGpIdsBySlot;
  
  /// For each GP id: selected leader variant id.
  late Map<String, String> _leaderVariantByGpId;
  
  /// Use default naming config for nations and leaders.
  final ResolvedNamingConfig _naming = defaultNamingConfig;

  /// Which dropdown is focused: -1 = none, 0 = nation, 1 = leader.
  int _dropdownFocus = 0;

  @override
  void initState() {
    super.initState();
    _orderedGpIdsBySlot = List.filled(_kNumSlots, '');
    _leaderVariantByGpId = {};
  }

  /// All available GP ids from naming config.
  List<String> get _allGpIds => _naming.greatPowers.map((g) => g.id).toList();

  /// GP ids available for a slot: empty (unselected) + not used in other slots.
  List<String> _availableGpIdsForSlot(int slotIndex) {
    final others = _allGpIds.where((id) {
      final indexOf = _orderedGpIdsBySlot.indexOf(id);
      return indexOf == -1 || indexOf == slotIndex;
    }).toList();
    return ['', ...others];
  }

  /// Auto-assign nations and default leaders to any empty slots from top to bottom.
  void _autoAssignGaps() {
    final currentOrdered = List<String>.from(_orderedGpIdsBySlot);
    final currentLeaders = Map<String, String>.from(_leaderVariantByGpId);
    final assigned = <String>{
      for (final id in currentOrdered)
        if (id.isNotEmpty) id,
    };
    final filledSlots = <int>[];

    for (var slotIndex = 0; slotIndex < _kNumSlots; slotIndex++) {
      if (currentOrdered[slotIndex].isNotEmpty) {
        continue;
      }
      final gpId = _allGpIds.firstWhere(
        (id) => !assigned.contains(id),
        orElse: () => '',
      );
      if (gpId.isEmpty) {
        continue;
      }

      currentOrdered[slotIndex] = gpId;
      final gp = _naming.gpById(gpId);
      if (gp != null && gp.leaderVariants.isNotEmpty) {
        currentLeaders[gpId] = gp.defaultLeaderVariantId;
      }
      assigned.add(gpId);
      filledSlots.add(slotIndex);
    }

    if (filledSlots.isEmpty) {
      _log.i('auto-assign: no changes');
      return;
    }

    setState(() {
      _orderedGpIdsBySlot = currentOrdered;
      _leaderVariantByGpId = currentLeaders;
    });
    _log.i('auto-assign filled slots $filledSlots');
  }

  /// Check if all slots have nation and leader selected.
  bool get _startEnabled =>
      _orderedGpIdsBySlot.every((id) => id.isNotEmpty) &&
      _orderedGpIdsBySlot.every((id) {
        if (id.isEmpty) return false;
        return _leaderVariantByGpId.containsKey(id) && _leaderVariantByGpId[id]!.isNotEmpty;
      });

  void _handleKey(String c) {
    switch (c) {
      case 'arrowup':
        setState(() {
          _focusIndex = (_focusIndex - 1).clamp(-2, _kFocusFairAssignment);
          _dropdownFocus = 0;
        });
        break;
      case 'arrowdown':
        setState(() {
          _focusIndex = (_focusIndex + 1).clamp(-2, _kFocusFairAssignment);
          _dropdownFocus = 0;
        });
        break;
      case 'arrowleft':
        if (_focusIndex >= 0) {
          setState(() => _dropdownFocus = (_dropdownFocus - 1).clamp(0, 1));
        }
        break;
      case 'arrowright':
        if (_focusIndex >= 0) {
          setState(() => _dropdownFocus = (_dropdownFocus + 1).clamp(0, 1));
        }
        break;
      case 'a':
      case 'A':
        _autoAssignGaps();
        break;
      case 's':
      case 'S':
        if (_startEnabled) {
          _doStartGame();
        }
        break;
      case 'b':
      case 'B':
      case 'escape':
        _log.d('back pressed');
        component.onBack();
        break;
      case 'enter':
        if (_focusIndex == -1 && _startEnabled) {
          _doStartGame();
        } else if (_focusIndex == -2) {
          component.onBack();
        } else if (_focusIndex == _kFocusFairAssignment) {
          setState(
            () => _enforceFairGpOldWorldAssignment =
                !_enforceFairGpOldWorldAssignment,
          );
        } else if (_focusIndex >= 0) {
          // Cycle through dropdown options
          _handleDropdownCycle();
        }
        break;
      case ' ':
        if (_focusIndex == _kFocusFairAssignment) {
          setState(
            () => _enforceFairGpOldWorldAssignment =
                !_enforceFairGpOldWorldAssignment,
          );
        } else if (_focusIndex >= 0) {
          _handleDropdownCycle();
        }
        break;
    }
  }

  void _handleDropdownCycle() {
    if (_focusIndex < 0) return;
    
    final slotIndex = _focusIndex;
    final gpId = _orderedGpIdsBySlot[slotIndex];
    
    if (_dropdownFocus == 0) {
      // Cycle through nations
      final available = _availableGpIdsForSlot(slotIndex);
      final currentIndex = available.indexOf(gpId);
      final nextIndex = (currentIndex + 1) % available.length;
      final newGpId = available[nextIndex];
      
      setState(() {
        _orderedGpIdsBySlot[slotIndex] = newGpId;
        if (newGpId.isNotEmpty) {
          final gp = _naming.gpById(newGpId);
          if (gp != null && gp.leaderVariants.isNotEmpty) {
            _leaderVariantByGpId[newGpId] = gp.defaultLeaderVariantId;
          }
        }
      });
      _log.d('slot $slotIndex nation -> $newGpId');
    } else {
      // Cycle through leaders for selected nation
      if (gpId.isEmpty) return;
      final gp = _naming.gpById(gpId);
      if (gp == null || gp.leaderVariants.isEmpty) return;
      
      final currentVariant = _leaderVariantByGpId[gpId] ?? gp.defaultLeaderVariantId;
      final variants = gp.leaderVariants;
      final currentIndex = variants.indexWhere((v) => v.id == currentVariant);
      final nextIndex = (currentIndex + 1) % variants.length;
      final newVariant = variants[nextIndex].id;
      
      setState(() {
        _leaderVariantByGpId[gpId] = newVariant;
      });
      _log.d('slot $slotIndex leader -> $newVariant');
    }
  }

  void _doStartGame() {
    final leaderMap = <String, String>{};
    for (final gpId in _orderedGpIdsBySlot) {
      final variantId = _leaderVariantByGpId[gpId];
      if (variantId != null && variantId.isNotEmpty) {
        leaderMap[gpId] = variantId;
      } else {
        final gp = _naming.gpById(gpId);
        if (gp != null && gp.leaderVariants.isNotEmpty) {
          leaderMap[gpId] = gp.defaultLeaderVariantId;
        }
      }
    }
    _log.i('start game with ${_orderedGpIdsBySlot.length} players');
    component.onStartGame(
      List<String>.from(_orderedGpIdsBySlot),
      leaderMap,
      _enforceFairGpOldWorldAssignment,
    );
  }

  @override
  Component build(BuildContext context) {
    return Focusable(
      focused: true,
      onKeyEvent: (event) {
        final key = event.logicalKey;
        if (key == LogicalKey.arrowUp) {
          _handleKey('arrowup');
          return true;
        }
        if (key == LogicalKey.arrowDown) {
          _handleKey('arrowdown');
          return true;
        }
        if (key == LogicalKey.arrowLeft) {
          _handleKey('arrowleft');
          return true;
        }
        if (key == LogicalKey.arrowRight) {
          _handleKey('arrowright');
          return true;
        }
        if (key == LogicalKey.enter || key == LogicalKey.space) {
          _handleKey(key == LogicalKey.enter ? 'enter' : ' ');
          return true;
        }
        final c = event.character?.toLowerCase();
        if (c != null) {
          _handleKey(c);
          return true;
        }
        if (key == LogicalKey.escape) {
          _handleKey('escape');
          return true;
        }
        return false;
      },
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Game Setup', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 1),
            // Player slots
            ...List.generate(_kNumSlots, (i) => _buildSlotRow(i)),
            const SizedBox(height: 1),
            _buildFairAssignmentRow(),
            const SizedBox(height: 1),
            // Buttons
            _buildButtonRow(),
          ],
        ),
      ),
    );
  }

  Component _buildSlotRow(int slotIndex) {
    final isSelected = _focusIndex == slotIndex;
    final gpId = _orderedGpIdsBySlot[slotIndex];
    final gp = gpId.isEmpty ? null : _naming.gpById(gpId);
    final variants = gp?.leaderVariants ?? [];
    final currentVariantId = gp != null
        ? (_leaderVariantByGpId[gpId] ?? gp.defaultLeaderVariantId)
        : '';
    
    final label = slotIndex == 0 ? 'Player 1 (You)' : 'Player ${slotIndex + 1} (AI)';
    final prefix = isSelected ? '> ' : '  ';
    
    // Nation display
    String nationText;
    if (gpId.isEmpty) {
      nationText = 'Select nation';
    } else {
      nationText = gp?.countryName ?? gpId;
    }
    
    // Leader display
    String leaderText;
    if (gpId.isEmpty) {
      leaderText = '-';
    } else if (variants.isEmpty) {
      leaderText = '-';
    } else {
      final variant = variants.firstWhere(
        (v) => v.id == currentVariantId,
        orElse: () => variants.first,
      );
      leaderText = variant.name;
    }
    
    // Determine dropdown highlight
    final nationHighlight = isSelected && _dropdownFocus == 0;
    final leaderHighlight = isSelected && _dropdownFocus == 1 && gpId.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Text(
        '$prefix$label  [${nationHighlight ? "▼" : " "}$nationText] [${leaderHighlight ? "▼" : " "}$leaderText]',
        style: TextStyle(
          color: isSelected ? Colors.cyan : null,
        ),
      ),
    );
  }

  Component _buildFairAssignmentRow() {
    final focused = _focusIndex == _kFocusFairAssignment;
    final prefix = focused ? '> ' : '  ';
    final box = _enforceFairGpOldWorldAssignment ? '[x]' : '[ ]';
    return Text(
      '${prefix}Fair GP assignment (repair) $box  (toggle when focused)',
      style: TextStyle(
        color: focused ? Colors.cyan : null,
        fontWeight: focused ? FontWeight.bold : null,
      ),
    );
  }

  Component _buildButtonRow() {
    final startEnabled = _startEnabled;
    final startFocused = _focusIndex == -1;
    final backFocused = _focusIndex == -2;
    
    final startStyle = startEnabled
        ? (startFocused ? TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold) : null)
        : TextStyle(color: Colors.gray);
    final backStyle = backFocused ? TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold) : null;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('[A] Auto-assign  '),
        Text(
          startEnabled ? '[S] Start Game  ' : '[S] Start Game  ',
          style: startStyle,
        ),
        Text(
          '[B] Back',
          style: backStyle,
        ),
      ],
    );
  }
}
