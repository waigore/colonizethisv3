// Move fleet dialog. SPEC/ui/naval-units-panel.md, SPEC/program/app-ui-wiring.md.

// ignore_for_file: deprecated_member_use

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/ct_e2e.dart';
import '../../../l10n/l10n.dart';
import '../utils/map_location_resolver.dart';
import '../utils/sea_zone_name_resolver.dart';
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

String _fleetMoveDialogTitleLabel(Fleet fleet) => 'Fleet ${fleet.id}';

String _fullProvinceIdForTopologyProvince(
  String topologyProvinceId,
  String regionId,
) {
  if (ProvinceId.isPrefixed(topologyProvinceId)) return topologyProvinceId;
  return ProvinceId.full(regionId, topologyProvinceId);
}

List<_MovePick> _buildNavalMovePicks({
  required Game game,
  required MapTopology topology,
  required String humanPlayerId,
  required Fleet fleet,
  required String warpLinkLabel,
  required String Function(String regionLabel) warpLinkLabelForRegion,
}) {
  final outSea = <_PickSeaZone>[];
  final outPort = <_PickPort>[];

  final topo = navalMoveTopologyPicksForFleet(topology: topology, fleet: fleet);
  if (topo.totalCount == 0) return const [];

  final fleetSeaRegion = fleet.isAtSea && fleet.seaZoneId != null
      ? regionIdForSeaZone(topology, fleet.seaZoneId!) ?? fleet.regionId
      : fleet.regionId;

  for (final z in topo.adjacentSeaZoneIds) {
    final zReg = regionIdForSeaZone(topology, z) ?? fleetSeaRegion;
    final regLabel = unitsPanelRegionLabel(zReg);
    final cross = zReg != fleetSeaRegion;
    final isWarp = isWarpZoneSeaZone(topology, z);
    final zoneLabel = seaZoneDisplayName(
      game: game,
      regionId: zReg,
      seaZoneId: z,
    );
    final label = !isWarp
        ? zoneLabel
        : cross
        ? '$zoneLabel ${warpLinkLabelForRegion(regLabel)}'
        : '$zoneLabel $warpLinkLabel';
    outSea.add(_PickSeaZone(seaZoneId: z, zoneRegionId: zReg, rowLabel: label));
  }
  outSea.sort((a, b) => a.rowLabel.compareTo(b.rowLabel));

  if (fleet.isAtSea && fleet.seaZoneId != null) {
    final rz = regionIdForSeaZone(topology, fleet.seaZoneId!) ?? fleet.regionId;
    final portRows = <({String fullId, String label})>[];
    for (final lp in topo.adjacentProvinceIdsForDock) {
      final full = _fullProvinceIdForTopologyProvince(lp, rz);
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
  var _picksInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_picksInitialized) return;
    final l10n = appL10n(context);
    _picks = _buildNavalMovePicks(
      game: widget.game,
      topology: widget.topology,
      humanPlayerId: widget.humanPlayerId,
      fleet: widget.fleet,
      warpLinkLabel: l10n.moveFleet_warpLink,
      warpLinkLabelForRegion: l10n.moveFleet_warpLinkToRegion,
    );
    _picksInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final picks = _picks;
    final seaPicks = picks.whereType<_PickSeaZone>().toList();
    final portPicks = picks.whereType<_PickPort>().toList();
    final fleetLabel = _fleetMoveDialogTitleLabel(widget.fleet);
    final titleText = picks.isEmpty
        ? l10n.moveFleet_title(fleetLabel)
        : l10n.moveFleet_titleWithDestinations(fleetLabel, picks.length);

    final moveColumns = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (seaPicks.isNotEmpty) ...[
          Text(
            l10n.moveFleet_seaZonesSection,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ...seaPicks.map(_row),
        ],
        if (portPicks.isNotEmpty) ...[
          if (seaPicks.isNotEmpty) const SizedBox(height: 12),
          Text(
            l10n.moveFleet_provincesDockSection,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ...portPicks.map(_row),
        ],
      ],
    );

    return AlertDialog(
      title: Text(titleText),
      content: SizedBox(
        width: 420,
        child: picks.isEmpty
            ? Text(l10n.moveFleet_noAdjacentSeaZones)
            : SingleChildScrollView(
                child: kCtE2EEnabled
                    ? KeyedSubtree(
                        key: kCtE2EMoveFleetDialogScrollRootKey,
                        child: moveColumns,
                      )
                    : moveColumns,
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.common_cancel),
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
                  Navigator.pop(context, true);
                },
          child: Text(l10n.common_confirm),
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
            tooltip: appL10n(context).moveFleet_locateOnMap,
            icon: const Icon(Icons.my_location, size: 18),
            onPressed: () => pick.emitLocate(widget.bus, widget.game),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
