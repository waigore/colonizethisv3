// Move fleet dialog. SPEC/ui/move-fleet-dialog.md, SPEC/program/app-ui-wiring.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/ct_e2e.dart';
import '../../../config/editorial_monocle_palette.dart';
import '../../../config/ui_screen_ids.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_icon_action.dart';
import '../../../widgets/ct_section_label.dart';
import '../../../widgets/ct_spacing.dart';
import '../utils/map_location_resolver.dart';
import '../utils/region_labels.dart';
import '../utils/sea_zone_name_resolver.dart';
import 'move_units_dialog_base.dart';

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
    final province = game.worldState.tryGetProvince(fullProvinceId);
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
    final regLabel = regionDisplayLabel(zReg);
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
      final province = game.worldState.tryGetProvince(full);
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

  /// SPEC/ui/move-fleet-dialog.md — [UiScreenIds.moveFleetDialog].
  static const screenId = UiScreenIds.moveFleetDialog;

  final Game game;
  final MapTopology topology;
  final String humanPlayerId;
  final Fleet fleet;
  final AppEventBus bus;

  @override
  State<MoveFleetDialog> createState() => _MoveFleetDialogState();
}

class _MoveFleetDialogState extends MoveUnitsDialogState<MoveFleetDialog> {
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
  String get moveDialogTitle {
    final l10n = appL10n(context);
    final fleetLabel = _fleetMoveDialogTitleLabel(widget.fleet);
    return _picks.isEmpty
        ? l10n.moveFleet_title(fleetLabel)
        : l10n.moveFleet_titleWithDestinations(fleetLabel, _picks.length);
  }

  @override
  bool get moveDialogHasDestinations => _picks.isNotEmpty;

  @override
  String get moveDialogEmptyText =>
      appL10n(context).moveFleet_noAdjacentSeaZones;

  @override
  bool get moveDialogCanConfirm => _selected != null;

  @override
  void onMoveDialogConfirm() {
    final selected = _selected;
    if (selected == null) return;
    widget.bus.emit(
      NavalMoveFleetRequestedEvent(
        humanPlayerId: widget.humanPlayerId,
        moveOrder: selected.toOrder(widget.fleet.id),
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  void onMoveDialogCancel() => Navigator.pop(context, false);

  @override
  Widget build(BuildContext context) => buildMoveDialogScaffold(context);

  @override
  Widget buildMoveDialogDestinations(BuildContext context) {
    final l10n = appL10n(context);
    final seaPicks = _picks.whereType<_PickSeaZone>().toList();
    final portPicks = _picks.whereType<_PickPort>().toList();

    final moveColumns = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (seaPicks.isNotEmpty) ...[
          CtSectionLabel(l10n.moveFleet_seaZonesSection),
          const SizedBox(height: CtSpacing.s),
          for (var i = 0; i < seaPicks.length; i++) _row(seaPicks[i], i),
        ],
        if (portPicks.isNotEmpty) ...[
          if (seaPicks.isNotEmpty) const SizedBox(height: CtSpacing.ml),
          CtSectionLabel(l10n.moveFleet_provincesDockSection),
          const SizedBox(height: CtSpacing.s),
          for (var i = 0; i < portPicks.length; i++)
            _row(portPicks[i], seaPicks.length + i),
        ],
      ],
    );

    // When `kCtE2EEnabled`, wrap the rows column so fleet-reach e2e helpers can
    // scope a scroll root without Material chrome (Refs #2336).
    return kCtE2EEnabled
        ? KeyedSubtree(
            key: kCtE2EMoveFleetDialogScrollRootKey,
            child: moveColumns,
          )
        : moveColumns;
  }

  Widget _row(_MovePick pick, int index) {
    final bool selected = identical(pick, _selected);
    final row = MoveDialogDestinationRow(
      // Deterministic per-row key (CT_E2E only) so fleet-reach e2e helpers can
      // select the first available destination without Material `RadioListTile`
      // chrome (Refs #2336).
      key: kCtE2EEnabled ? kCtE2EMoveFleetDestinationRowKey(index) : null,
      selected: selected,
      semanticsLabel: pick.rowLabel,
      onTap: () => setState(() => _selected = pick),
      content: Text(
        pick.rowLabel,
        style: moveDialogRowLabelStyle(Theme.of(context), selected: selected),
      ),
      trailing: CtIconAction(
        tooltip: appL10n(context).moveFleet_locateOnMap,
        icon: Icons.my_location,
        iconColor: EditorialMonoclePalette.muted,
        onPressed: () => pick.emitLocate(widget.bus, widget.game),
      ),
    );
    // Additionally expose sea-zone rows by their topology id (CT_E2E only) so
    // the fleet-reach helper can tap the adjacent sea zone that makes BFS
    // progress toward the New World warp rather than the alphabetically-first
    // row. Wrapping in a `KeyedSubtree` keeps the inner row's positional key
    // (and rendered chrome) unchanged (Refs #2336 AC6/AC7).
    if (kCtE2EEnabled && pick is _PickSeaZone) {
      return KeyedSubtree(
        key: kCtE2EMoveFleetDestinationSeaZoneRowKey(pick.seaZoneId),
        child: row,
      );
    }
    return row;
  }
}
