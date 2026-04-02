// Move army dialog. SPEC/ui/military-units-panel.md, SPEC/program/app-ui-wiring.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import 'units/shared/units_panel_region_label.dart';

/// Destination picks for one army move order.
List<String> armyMoveDestinationFullProvinceIds({
  required Game game,
  required MapTopology topology,
  required String humanPlayerId,
  required Army army,
}) {
  final fromFull = army.stationedProvinceId;
  final regionId = ProvinceId.regionIdFrom(fromFull);
  final fromLocal = ProvinceId.localIdFrom(fromFull);
  final out = <String>{};

  for (final n in neighborProvinceIdsInRegion(topology, regionId, fromLocal)) {
    out.add(ProvinceId.full(regionId, n));
  }
  for (final p in allProvinces(game.worldState)) {
    if (p.ownerId == humanPlayerId) {
      out.add(p.id);
    }
  }
  out.remove(fromFull);
  final sorted = out.toList()..sort();
  return sorted;
}

class MoveArmyDialog extends StatefulWidget {
  const MoveArmyDialog({
    super.key,
    required this.army,
    required this.game,
    required this.humanPlayerId,
    required this.bus,
    required this.topology,
  });

  final Army army;
  final Game game;
  final String humanPlayerId;
  final AppEventBus bus;
  final MapTopology topology;

  @override
  State<MoveArmyDialog> createState() => _MoveArmyDialogState();
}

class _MoveArmyDialogState extends State<MoveArmyDialog> {
  String? _selected;

  List<({String regionId, String fullProvinceId, String label})>
  _destinationEntries() {
    final destIds = armyMoveDestinationFullProvinceIds(
      game: widget.game,
      topology: widget.topology,
      humanPlayerId: widget.humanPlayerId,
      army: widget.army,
    );
    final out = <({String regionId, String fullProvinceId, String label})>[];
    for (final id in destIds) {
      final province = tryGetProvince(widget.game.worldState, id);
      final label = province?.displayName ?? ProvinceId.localIdFrom(id);
      out.add((
        regionId: ProvinceId.regionIdFrom(id),
        fullProvinceId: id,
        label: label,
      ));
    }
    out.sort((a, b) {
      final regionCmp = a.regionId.compareTo(b.regionId);
      if (regionCmp != 0) return regionCmp;
      final labelCmp = a.label.compareTo(b.label);
      if (labelCmp != 0) return labelCmp;
      return a.fullProvinceId.compareTo(b.fullProvinceId);
    });
    return out;
  }

  List<DropdownMenuItem<String>> _groupedDropdownItems(
    List<({String regionId, String fullProvinceId, String label})> entries,
  ) {
    final items = <DropdownMenuItem<String>>[];
    String? currentRegion;
    for (final entry in entries) {
      if (entry.regionId != currentRegion) {
        currentRegion = entry.regionId;
        final regionLabel = unitsPanelRegionLabel(entry.regionId);
        items.add(
          DropdownMenuItem<String>(
            enabled: false,
            value: '__header__${entry.regionId}',
            child: Text(
              regionLabel,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
      items.add(
        DropdownMenuItem<String>(
          value: entry.fullProvinceId,
          child: Text(entry.label),
        ),
      );
    }
    return items;
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
                value: _selected,
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
          onPressed: _selected == null
              ? null
              : () {
                  widget.bus.emit(
                    ArmyMoveRequestedEvent(
                      humanPlayerId: widget.humanPlayerId,
                      moveOrder: ArmyMoveOrder(
                        armyId: widget.army.id,
                        destinationProvinceId: _selected!,
                      ),
                    ),
                  );
                  Navigator.of(context).pop();
                },
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
