// Move fleet dialog. SPEC/ui/move-fleet-dialog.md, SPEC/program/app-ui-wiring.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/ct_e2e.dart';
import '../../../config/editorial_monocle_palette.dart';
import '../../../config/ui_screen_ids.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_section_label.dart';
import '../utils/map_location_resolver.dart';
import '../utils/sea_zone_name_resolver.dart';
import 'chrome/ct_nine_patch_button.dart';
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
    final ThemeData theme = Theme.of(context);
    final l10n = appL10n(context);
    final picks = _picks;
    final seaPicks = picks.whereType<_PickSeaZone>().toList();
    final portPicks = picks.whereType<_PickPort>().toList();
    final fleetLabel = _fleetMoveDialogTitleLabel(widget.fleet);
    final titleText = picks.isEmpty
        ? l10n.moveFleet_title(fleetLabel)
        : l10n.moveFleet_titleWithDestinations(fleetLabel, picks.length);

    final TextStyle titleStyle =
        (theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16))
            .copyWith(
              color: EditorialMonoclePalette.accent,
              letterSpacing: 0.05 * 16,
              fontWeight: FontWeight.w600,
            );
    final TextStyle emptyStyle =
        (theme.textTheme.bodyMedium ?? const TextStyle())
            .copyWith(color: EditorialMonoclePalette.muted);

    final moveColumns = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (seaPicks.isNotEmpty) ...[
          CtSectionLabel(l10n.moveFleet_seaZonesSection),
          const SizedBox(height: 6),
          ...seaPicks.map(_row),
        ],
        if (portPicks.isNotEmpty) ...[
          if (seaPicks.isNotEmpty) const SizedBox(height: 12),
          CtSectionLabel(l10n.moveFleet_provincesDockSection),
          const SizedBox(height: 6),
          ...portPicks.map(_row),
        ],
      ],
    );

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(titleText, style: titleStyle),
        const SizedBox(height: 12),
        if (picks.isEmpty)
          Text(l10n.moveFleet_noAdjacentSeaZones, style: emptyStyle)
        else
          kCtE2EEnabled
              ? KeyedSubtree(
                  key: kCtE2EMoveFleetDialogScrollRootKey,
                  child: moveColumns,
                )
              : moveColumns,
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            CtNinePatchButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.common_cancel),
            ),
            CtNinePatchButton(
              enabled: _selected != null,
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
        ),
      ],
    );

    return CtDialogShell(child: body);
  }

  Widget _row(_MovePick pick) {
    return _MoveFleetDestinationRow(
      pick: pick,
      selected: identical(pick, _selected),
      onTap: () => setState(() => _selected = pick),
      onLocate: () => pick.emitLocate(widget.bus, widget.game),
      locateTooltip: appL10n(context).moveFleet_locateOnMap,
    );
  }
}

/// Single destination row inside `MoveFleetDialog`.
///
/// SPEC: `SPEC/ui/move-fleet-dialog.md` § Layout — radio-row outline contract
/// (#2867 R7). The row renders a 1 px `--border` outline by default and a 2 px
/// `--accent` outline with a filled `--accent` dot when [selected]. No
/// Material `Radio` / `RadioListTile` is used — that ensures the surface
/// remains free of the legacy chrome banned by `SPEC/ui/pixel-art-ui-catalog.md`
/// § Material design ban.
class _MoveFleetDestinationRow extends StatelessWidget {
  const _MoveFleetDestinationRow({
    required this.pick,
    required this.selected,
    required this.onTap,
    required this.onLocate,
    required this.locateTooltip,
  });

  final _MovePick pick;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLocate;
  final String locateTooltip;

  static const double _selectedBorderWidth = 2;
  static const double _idleBorderWidth = 1;
  static const double _dotOuterDiameter = 14;
  static const double _dotInnerDiameter = 6;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color outline = selected
        ? EditorialMonoclePalette.accent
        : EditorialMonoclePalette.border;
    final double outlineWidth = selected
        ? _selectedBorderWidth
        : _idleBorderWidth;
    final TextStyle labelStyle =
        (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
          color: selected
              ? EditorialMonoclePalette.fg
              : EditorialMonoclePalette.fg.withValues(alpha: 0.9),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Semantics(
        button: true,
        selected: selected,
        label: pick.rowLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: outline, width: outlineWidth),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                _RadioDot(selected: selected),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(pick.rowLabel, style: labelStyle),
                ),
                IconButton(
                  tooltip: locateTooltip,
                  icon: Icon(
                    Icons.my_location,
                    size: 18,
                    color: EditorialMonoclePalette.muted,
                  ),
                  onPressed: onLocate,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _MoveFleetDestinationRow._dotOuterDiameter,
      height: _MoveFleetDestinationRow._dotOuterDiameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected
                    ? EditorialMonoclePalette.accent
                    : EditorialMonoclePalette.border,
                width: 1,
              ),
            ),
          ),
          if (selected)
            Container(
              width: _MoveFleetDestinationRow._dotInnerDiameter,
              height: _MoveFleetDestinationRow._dotInnerDiameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EditorialMonoclePalette.accent,
              ),
            ),
        ],
      ),
    );
  }
}
