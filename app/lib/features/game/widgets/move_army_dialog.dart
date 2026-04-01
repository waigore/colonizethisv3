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

  for (final n in neighborProvinceIdsInRegion(
    topology,
    regionId,
    fromLocal,
  )) {
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

  @override
  void initState() {
    super.initState();
    final destIds = armyMoveDestinationFullProvinceIds(
      game: widget.game,
      topology: widget.topology,
      humanPlayerId: widget.humanPlayerId,
      army: widget.army,
    );
    if (destIds.isNotEmpty) {
      _selected = destIds.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final destIds = armyMoveDestinationFullProvinceIds(
      game: widget.game,
      topology: widget.topology,
      humanPlayerId: widget.humanPlayerId,
      army: widget.army,
    );

    return AlertDialog(
      title: Text('Move army ${widget.army.id}'),
      content: SizedBox(
        width: 320,
        child: destIds.isEmpty
            ? const Text('No valid destinations.')
            : ListView.builder(
                shrinkWrap: true,
                itemCount: destIds.length,
                itemBuilder: (ctx, i) {
                  final id = destIds[i];
                  final province = tryGetProvince(widget.game.worldState, id);
                  final label =
                      province?.displayName ?? ProvinceId.localIdFrom(id);
                  final regionLabel =
                      unitsPanelRegionLabel(ProvinceId.regionIdFrom(id));
                  return RadioListTile<String>(
                    title: Text(label),
                    subtitle: Text('$regionLabel · $id'),
                    value: id,
                    groupValue: _selected,
                    onChanged: (v) => setState(() => _selected = v),
                  );
                },
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
