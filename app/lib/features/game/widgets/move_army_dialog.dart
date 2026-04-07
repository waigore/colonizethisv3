// Move army dialog. SPEC/ui/military-units-panel.md, SPEC/program/app-ui-wiring.md.

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

String moveArmyFactionGroupHeaderLabel(
  Game game,
  ArmyMovePickerDestination entry,
) {
  if (entry.isPlayerOwned) return 'Your provinces';
  if (entry.ownerFactionId == '__unowned__') return 'Unowned';
  final gp = game.playerById(entry.ownerFactionId);
  if (gp != null) return gp.displayName;
  for (final m in game.minorNations) {
    if (m.id == entry.ownerFactionId) {
      return m.displayName ?? m.id;
    }
  }
  for (final t in game.tribes) {
    if (t.id == entry.ownerFactionId) {
      return t.displayName ?? t.id;
    }
  }
  return entry.ownerFactionId;
}

class MoveArmyDialog extends StatefulWidget {
  const MoveArmyDialog({
    super.key,
    required this.army,
    required this.game,
    required this.humanPlayerId,
    required this.bus,
    required this.topology,
    required this.draftOrders,
  });

  final Army army;
  final Game game;
  final String humanPlayerId;
  final AppEventBus bus;
  final MapTopology topology;
  final Orders draftOrders;

  @override
  State<MoveArmyDialog> createState() => _MoveArmyDialogState();
}

class _MoveArmyDialogState extends State<MoveArmyDialog> {
  String? _selected;

  List<ArmyMovePickerDestination> _destinationEntries() {
    return armyMovePickerDestinations(
      game: widget.game,
      topology: widget.topology,
      playerId: widget.humanPlayerId,
      army: widget.army,
      currentOrders: widget.draftOrders,
    );
  }

  String _groupKey(ArmyMovePickerDestination e) =>
      e.isPlayerOwned ? '__player__' : e.ownerFactionId;

  List<DropdownMenuItem<String>> _groupedDropdownItems(
    List<ArmyMovePickerDestination> entries,
  ) {
    final items = <DropdownMenuItem<String>>[];
    String? currentGroup;
    for (final entry in entries) {
      final g = _groupKey(entry);
      if (g != currentGroup) {
        currentGroup = g;
        items.add(
          DropdownMenuItem<String>(
            enabled: false,
            value: '__header__$g',
            child: Text(
              moveArmyFactionGroupHeaderLabel(widget.game, entry),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
      items.add(
        DropdownMenuItem<String>(
          value: entry.fullProvinceId,
          child: Text(entry.provinceLabel),
        ),
      );
    }
    return items;
  }

  ArmyMovePickerDestination? _selectedEntry(
    List<ArmyMovePickerDestination> entries,
  ) {
    final id = _selected;
    if (id == null) return null;
    for (final e in entries) {
      if (e.fullProvinceId == id) return e;
    }
    return null;
  }

  void _emitAndClose(ArmyMovePickerDestination entry) {
    widget.bus.emit(
      ArmyMoveRequestedEvent(
        humanPlayerId: widget.humanPlayerId,
        moveOrder: ArmyMoveOrder(
          armyId: widget.army.id,
          destinationProvinceId: entry.fullProvinceId,
        ),
        declareWarTargetFactionId: entry.requiresDeclareWarOnConfirm
            ? entry.ownerFactionId
            : null,
      ),
    );
    Navigator.of(context).pop();
  }

  Future<void> _onConfirmPressed() async {
    final entries = _destinationEntries();
    final entry = _selectedEntry(entries);
    if (entry == null) return;

    if (!entry.requiresDeclareWarOnConfirm) {
      _emitAndClose(entry);
      return;
    }

    final ownerLabel = moveArmyFactionGroupHeaderLabel(widget.game, entry);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invade province?'),
        content: Text(
          'Moving into $ownerLabel territory will declare war this turn '
          'and then move the army. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Declare war and move'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      _emitAndClose(entry);
    }
  }

  @override
  void initState() {
    super.initState();
    final entries = _destinationEntries();
    if (entries.isNotEmpty) {
      _selected = entries.first.fullProvinceId;
    }
  }

  @override
  void didUpdateWidget(MoveArmyDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draftOrders != widget.draftOrders ||
        oldWidget.game != widget.game ||
        oldWidget.army != widget.army) {
      final entries = _destinationEntries();
      if (_selected == null ||
          !entries.any((e) => e.fullProvinceId == _selected)) {
        _selected = entries.isEmpty ? null : entries.first.fullProvinceId;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _destinationEntries();
    final items = _groupedDropdownItems(entries);

    return AlertDialog(
      title: Text('Move army ${widget.army.id}'),
      content: SizedBox(
        width: 320,
        child: entries.isEmpty
            ? const Text('No valid destinations.')
            : DropdownButtonFormField<String>(
                initialValue: _selected,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Destination province',
                ),
                items: items,
                onChanged: (v) => setState(() => _selected = v),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _selected == null ? null : _onConfirmPressed,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
