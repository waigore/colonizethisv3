// Move fleet dialog. SPEC/ui/naval-units-panel.md, SPEC/program/app-ui-wiring.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../utils/map_location_resolver.dart';
import 'units/shared/units_panel_region_label.dart';

sealed class _MovePick {
  const _MovePick();

  NavalMoveOrder toOrder(String fleetId);
  String get rowLabel;
  void emitLocate(AppEventBus bus, Game game);
}

final class _PickSeaZone extends _MovePick {
  const _PickSeaZone({
    required this.seaZoneId,
    required this.zoneRegionId,
    required this.rowLabel,
  });

  final String seaZoneId;
  final String zoneRegionId;
  @override
  final String rowLabel;

  @override
  NavalMoveOrder toOrder(String fleetId) =>
      NavalMoveOrder(fleetId: fleetId, destinationSeaZoneId: seaZoneId);

  @override
  void emitLocate(AppEventBus bus, Game game) {
    final key = tileKeyForSeaZoneLocation(game, zoneRegionId, seaZoneId);
    if (key == null) return;
    bus.emit(LocateMapTileEvent(tileKey: key, regionId: zoneRegionId));
  }
}

final class _PickPort extends _MovePick {
  const _PickPort({
    required this.fullProvinceId,
    required this.rowLabel,
    required this.provinceRegionId,
  });

  final String fullProvinceId;
  @override
  final String rowLabel;
  final String provinceRegionId;

  @override
  NavalMoveOrder toOrder(String fleetId) => NavalMoveOrder(
        fleetId: fleetId,
        destinationPortProvinceId: fullProvinceId,
      );

  @override
  void emitLocate(AppEventBus bus, Game game) {
    final province = tryGetProvince(game.worldState, fullProvinceId);
    if (province == null) return;
    final key = tileKeyForProvinceLocation(game, province);
    if (key == null) return;
    bus.emit(LocateMapTileEvent(tileKey: key, regionId: provinceRegionId));
  }
}

List<_MovePick> _buildNavalMovePicks({
  required Game game,
  required MapTopology topology,
  required String humanPlayerId,
  required Fleet fleet,
}) {
  final outSea = <_PickSeaZone>[];
  final outPort = <_PickPort>[];

  final String? currentSeaZoneId;
  if (fleet.isAtSea) {
    currentSeaZoneId = fleet.seaZoneId;
  } else {
    final inPort = fleet.inPortAtProvinceId;
    if (inPort == null) return const [];
    final rl = regionAndLocalProvinceForFleetInPort(inPort, fleet.regionId);
    currentSeaZoneId = seaZoneIdForProvince(
      topology,
      rl.localId,
      regionId: rl.regionId,
    );
  }
  if (currentSeaZoneId == null || currentSeaZoneId.isEmpty) return const [];

  final fleetSeaRegion =
      regionIdForSeaZone(topology, currentSeaZoneId) ?? fleet.regionId;

  final adjZones = <String>{};
  for (final e in topology.edges) {
    if (e.id1 == currentSeaZoneId) {
      adjZones.add(e.id2);
    } else if (e.id2 == currentSeaZoneId) {
      adjZones.add(e.id1);
    }
  }
  final sortedZones = adjZones.toList()..sort();
  for (final z in sortedZones) {
    final zReg = regionIdForSeaZone(topology, z) ?? fleetSeaRegion;
    final regLabel = unitsPanelRegionLabel(zReg);
    final cross = zReg != fleetSeaRegion;
    final label = cross ? '$z · $regLabel (cross-region)' : '$z · $regLabel';
    outSea.add(_PickSeaZone(seaZoneId: z, zoneRegionId: zReg, rowLabel: label));
  }
  outSea.sort((a, b) => a.rowLabel.compareTo(b.rowLabel));

  if (fleet.isAtSea && fleet.seaZoneId != null) {
    final rz = regionIdForSeaZone(topology, fleet.seaZoneId!) ?? fleet.regionId;
    final localProvinces = provinceIdsAdjacentToSeaZone(
      topology,
      fleet.seaZoneId!,
      regionId: rz,
    );
    final portRows = <({String fullId, String label})>[];
    for (final lp in localProvinces) {
      final full = ProvinceId.full(rz, lp);
      final province = tryGetProvince(game.worldState, full);
      if (province == null || province.ownerId != humanPlayerId) continue;
      final name = province.displayName ?? province.id;
      final isCap = dockOrderTargetsPlayerCapital(game, humanPlayerId, full);
      final label = isCap ? '$name (capital — joins Home Fleet)' : name;
      portRows.add((fullId: full, label: label));
    }
    portRows.sort((a, b) => a.label.compareTo(b.label));
    for (final r in portRows) {
      outPort.add(
        _PickPort(
          fullProvinceId: r.fullId,
          rowLabel: r.label,
          provinceRegionId: rz,
        ),
      );
    }
  }

  return [...outSea, ...outPort];
}

class MoveFleetDialog extends StatefulWidget {
  const MoveFleetDialog({
    super.key,
    required this.game,
    required this.topology,
    required this.humanPlayerId,
    required this.fleet,
    required this.bus,
  });

  final Game game;
  final MapTopology topology;
  final String humanPlayerId;
  final Fleet fleet;
  final AppEventBus bus;

  @override
  State<MoveFleetDialog> createState() => _MoveFleetDialogState();
}

class _MoveFleetDialogState extends State<MoveFleetDialog> {
  late final List<_MovePick> _picks;
  _MovePick? _selected;

  @override
  void initState() {
    super.initState();
    _picks = _buildNavalMovePicks(
      game: widget.game,
      topology: widget.topology,
      humanPlayerId: widget.humanPlayerId,
      fleet: widget.fleet,
    );
  }

  @override
  Widget build(BuildContext context) {
    final picks = _picks;
    final seaPicks = picks.whereType<_PickSeaZone>().toList();
    final portPicks = picks.whereType<_PickPort>().toList();

    return AlertDialog(
      title: Text('Move fleet — ${widget.fleet.id}'),
      content: SizedBox(
        width: 420,
        child: picks.isEmpty
            ? const Text('No adjacent sea zones (check map topology).')
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (seaPicks.isNotEmpty) ...[
                      const Text(
                        'Sea zones',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...seaPicks.map(_row),
                    ],
                    if (portPicks.isNotEmpty) ...[
                      if (seaPicks.isNotEmpty) const SizedBox(height: 12),
                      const Text(
                        'Provinces (dock)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...portPicks.map(_row),
                    ],
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _selected == null
              ? null
              : () {
                  widget.bus.emit(
                    NavalMoveFleetRequestedEvent(
                      humanPlayerId: widget.humanPlayerId,
                      moveOrder: _selected!.toOrder(widget.fleet.id),
                    ),
                  );
                  Navigator.pop(context);
                },
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  Widget _row(_MovePick pick) {
    return RadioListTile<_MovePick>(
      value: pick,
      groupValue: _selected,
      onChanged: (v) => setState(() => _selected = v),
      title: Row(
        children: [
          Expanded(child: Text(pick.rowLabel)),
          IconButton(
            tooltip: 'Locate on map',
            icon: const Icon(Icons.my_location, size: 18),
            onPressed: () => pick.emitLocate(widget.bus, widget.game),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
