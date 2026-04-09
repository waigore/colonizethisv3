// Naval units panel. SPEC/ui/naval-units-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart' show homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import 'utils/naval_tree_builder.dart';
import 'move_fleet_dialog.dart';
import 'split_fleet_dialog.dart';
import 'units/shared/location_section_header.dart';
import 'units/shared/region_section_header.dart';
import 'units/shared/units_panel_region_label.dart';
import 'units/shared/units_panel_shell.dart';

class NavalUnitsPanel extends StatefulWidget {
  const NavalUnitsPanel({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.bus,
    required this.topology,
    this.draftOrders = const Orders(),
  });

  final Game game;
  final String humanPlayerId;
  final AppEventBus bus;
  final MapTopology topology;
  final Orders draftOrders;

  @override
  State<NavalUnitsPanel> createState() => _NavalUnitsPanelState();
}

class _NavalUnitsPanelState extends State<NavalUnitsPanel> {
  final Set<String> _selectedFleetIds = {};

  /// Canonical fleet id for combine/split selection (Home Fleet uses [homeFleetIdFor]).
  String _selectionFleetId(FleetRow row) {
    if (row.isHomeFleet) return homeFleetIdFor(widget.humanPlayerId);
    return row.fleetId;
  }

  bool _canCombineSelection(List<FleetRow> flat) {
    final rowsById = <String, FleetRow>{
      for (final r in flat) _selectionFleetId(r): r,
    };
    final activeIds = _selectedFleetIds.where(rowsById.containsKey).toList();
    if (activeIds.length < 2) return false;
    String? locationKey;
    for (final id in activeIds) {
      final row = rowsById[id]!;
      locationKey ??= row.locationKey;
      if (row.locationKey != locationKey) return false;
    }
    return true;
  }

  String _combineTargetFleetId(List<FleetRow> flat, Set<String> selected) {
    for (final row in flat) {
      final id = _selectionFleetId(row);
      if (!selected.contains(id)) continue;
      if (row.isHomeFleet) return id;
    }
    for (final row in flat) {
      final id = _selectionFleetId(row);
      if (selected.contains(id)) return id;
    }
    throw StateError('combine target: empty selection');
  }

  Fleet? _fleetForRow(FleetRow row) {
    final id = _selectionFleetId(row);
    for (final f in widget.game.worldState.fleets) {
      if (f.id == id) return f;
    }
    if (row.isHomeFleet) {
      final portId = row.inPortAtProvinceId;
      if (portId == null) return null;
      return Fleet(
        id: id,
        ownerId: widget.humanPlayerId,
        regionId: row.regionId,
        inPortAtProvinceId: portId,
        ships: const [],
        mission: FleetMission.none,
      );
    }
    return null;
  }

  void _toggleFleetSelection(FleetRow row) {
    setState(() {
      final id = _selectionFleetId(row);
      if (_selectedFleetIds.contains(id)) {
        _selectedFleetIds.remove(id);
      } else {
        _selectedFleetIds.add(id);
      }
    });
  }

  bool? _headerSelectAllValue(List<FleetRow> flat) {
    if (flat.isEmpty) return false;
    final ids = flat.map(_selectionFleetId).toSet();
    var n = 0;
    for (final id in ids) {
      if (_selectedFleetIds.contains(id)) n++;
    }
    if (n == 0) return false;
    if (n == ids.length) return true;
    return null;
  }

  /// Select-all header: from none or partial → select every row; from all → clear.
  /// Does not rely on [Checkbox] tristate `next` (indeterminate taps may pass false).
  void _onHeaderSelectAllTapped(List<FleetRow> flat) {
    setState(() {
      final ids = flat.map(_selectionFleetId).toSet();
      final allSelected =
          ids.isNotEmpty && ids.every(_selectedFleetIds.contains);
      if (allSelected) {
        _selectedFleetIds.clear();
      } else {
        _selectedFleetIds
          ..clear()
          ..addAll(ids);
      }
    });
  }

  void _performCombine(List<FleetRow> flat) {
    if (!_canCombineSelection(flat)) return;

    final selected = Set<String>.from(_selectedFleetIds);
    final targetId = _combineTargetFleetId(flat, selected);

    FleetRow? targetRow;
    for (final row in flat) {
      if (_selectionFleetId(row) == targetId) {
        targetRow = row;
        break;
      }
    }
    if (targetRow == null) return;

    final targetFleet = _fleetForRow(targetRow);
    if (targetFleet == null) return;

    final mergedShips = <ShipInstance>[...targetFleet.ships];
    for (final row in flat) {
      final id = _selectionFleetId(row);
      if (!selected.contains(id) || id == targetId) continue;
      final f = _fleetForRow(row);
      if (f != null) mergedShips.addAll(f.ships);
    }

    final merged = Fleet(
      id: targetId,
      ownerId: widget.humanPlayerId,
      seaZoneId: targetFleet.seaZoneId,
      inPortAtProvinceId: targetFleet.inPortAtProvinceId,
      regionId: targetFleet.regionId,
      ships: mergedShips,
      mission: FleetMission.none,
    );

    final homeId = homeFleetIdFor(widget.humanPlayerId);
    var updated = widget.game.worldState.fleets
        .where((f) => !selected.contains(f.id))
        .toList();
    updated = [...updated, merged];
    updated = updated
        .where((f) => f.ships.isNotEmpty || f.id == homeId)
        .toList();

    final newGame = widget.game.copyWith(
      worldState: widget.game.worldState.copyWith(fleets: updated),
    );

    setState(_selectedFleetIds.clear);
    widget.bus.emit(NavalFleetsUpdatedEvent(game: newGame));
  }

  @override
  void didUpdateWidget(covariant NavalUnitsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game != widget.game ||
        oldWidget.draftOrders != widget.draftOrders) {
      final flat = flattenNavalTree(
        buildNavalTree(
          widget.game,
          widget.humanPlayerId,
          widget.topology,
          widget.draftOrders,
        ),
      );
      final valid = flat.map(_selectionFleetId).toSet();
      final pruned = _selectedFleetIds.intersection(valid);
      if (pruned.length != _selectedFleetIds.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _selectedFleetIds
              ..clear()
              ..addAll(pruned);
          });
        });
      }
    }
  }

  void _openSplitDialog(FleetRow row) {
    final id = _selectionFleetId(row);
    Fleet? fleet;
    for (final f in widget.game.worldState.fleets) {
      if (f.id == id) {
        fleet = f;
        break;
      }
    }
    if (fleet == null) return;

    final original = fleet;
    showDialog<void>(
      context: context,
      builder: (ctx) => SplitFleetDialog(
        originalFleet: original,
        game: widget.game,
        humanPlayerId: widget.humanPlayerId,
        isHomeFleet: row.isHomeFleet,
        bus: widget.bus,
      ),
    );
  }

  void _openMoveFleetDialog(FleetRow row) {
    if (row.isHomeFleet) return;
    Fleet? fleet;
    for (final f in widget.game.worldState.fleets) {
      if (f.id == row.fleetId) {
        fleet = f;
        break;
      }
    }
    final nonNullFleet = fleet;
    if (nonNullFleet == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => MoveFleetDialog(
        game: widget.game,
        topology: widget.topology,
        humanPlayerId: widget.humanPlayerId,
        fleet: nonNullFleet,
        bus: widget.bus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tree = buildNavalTree(
      widget.game,
      widget.humanPlayerId,
      widget.topology,
      widget.draftOrders,
    );
    final flat = flattenNavalTree(tree);
    final hasAny = tree.any(
      (group) => group.homeFleet != null || group.locations.isNotEmpty,
    );
    final canCombine = _canCombineSelection(flat);
    final headerCheckbox = _headerSelectAllValue(flat);

    return UnitsPanelShell(
      title: l10n.naval_units_title,
      actions: [
        if (hasAny && flat.isNotEmpty) ...[
          Tooltip(
            message: headerCheckbox == true
                ? l10n.naval_units_deselectAllFleets
                : l10n.naval_units_selectAllFleets,
            child: Checkbox(
              tristate: true,
              value: headerCheckbox,
              onChanged: (_) => _onHeaderSelectAllTapped(flat),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 4),
          CtNinePatchButton(
            onPressed: canCombine ? () => _performCombine(flat) : null,
            enabled: canCombine,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minHeight: 32,
            child: Text(l10n.common_combine),
          ),
        ],
      ],
      hasContent: hasAny,
      listChildren: [
        for (final group in tree) ...[
          RegionSectionHeader(label: unitsPanelRegionLabel(group.regionId)),
          if (group.homeFleet != null)
            _FleetExpansionTile(
              row: group.homeFleet!,
              l10n: l10n,
              onTap: group.homeFleet!.tileKey != null
                  ? () => widget.bus.emit(
                      LocateMapTileEvent(
                        tileKey: group.homeFleet!.tileKey!,
                        regionId: group.homeFleet!.regionId,
                      ),
                    )
                  : null,
              isSelectedForCombine: _selectedFleetIds.contains(
                _selectionFleetId(group.homeFleet!),
              ),
              onCombineSelectionToggle: () =>
                  _toggleFleetSelection(group.homeFleet!),
              onSplitFleet: () => _openSplitDialog(group.homeFleet!),
              onMoveFleet: null,
              isSplitAllowed: true,
            ),
          for (final loc in group.locations) ...[
            LocationSectionHeader(
              label: loc.displayLabel,
              regionLabel: unitsPanelRegionLabel(loc.regionId),
            ),
            for (final row in loc.fleets)
              _FleetExpansionTile(
                row: row,
                l10n: l10n,
                onTap: row.tileKey != null
                    ? () => widget.bus.emit(
                        LocateMapTileEvent(
                          tileKey: row.tileKey!,
                          regionId: row.regionId,
                        ),
                      )
                    : null,
                isSelectedForCombine: _selectedFleetIds.contains(
                  _selectionFleetId(row),
                ),
                onCombineSelectionToggle: () => _toggleFleetSelection(row),
                onSplitFleet: () => _openSplitDialog(row),
                onMoveFleet: () => _openMoveFleetDialog(row),
                isSplitAllowed: true,
              ),
          ],
        ],
      ],
      emptyMessage: l10n.naval_units_empty,
    );
  }
}

class _FleetExpansionTile extends StatelessWidget {
  const _FleetExpansionTile({
    required this.row,
    required this.l10n,
    this.onTap,
    required this.isSelectedForCombine,
    required this.onCombineSelectionToggle,
    this.onSplitFleet,
    this.onMoveFleet,
    this.isSplitAllowed = false,
  });

  final FleetRow row;
  final AppLocalizations l10n;
  final VoidCallback? onTap;
  final bool isSelectedForCombine;
  final VoidCallback onCombineSelectionToggle;
  final VoidCallback? onSplitFleet;
  final VoidCallback? onMoveFleet;
  final bool isSplitAllowed;

  String _summary() {
    final parts = <String>[];
    parts.add(l10n.naval_units_totalShips(row.totalShips));
    parts.add(l10n.naval_units_strength(row.strength.toStringAsFixed(1)));
    if (row.warshipCount > 0) {
      parts.add(l10n.naval_units_warships(row.warshipCount));
    }
    if (row.merchantCount > 0) {
      parts.add(l10n.naval_units_merchants(row.merchantCount));
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: ExpansionTile(
        title: Row(
          children: [
            Checkbox(
              value: isSelectedForCombine,
              onChanged: (_) => onCombineSelectionToggle(),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 4),
            Flexible(child: Text(row.label, overflow: TextOverflow.ellipsis)),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              IconButton(
                tooltip: l10n.naval_units_locateFleet,
                onPressed: onTap,
                icon: const Icon(Icons.my_location),
                iconSize: 18,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${row.locationLabel}\n${l10n.naval_units_mission(row.missionLabel)} · ${_summary()}'
          '${row.draftNavalMoveLine != null ? '\n${row.draftNavalMoveLine}' : ''}',
        ),
        dense: true,
        children: [
          if (row.shipCountsByType.isEmpty)
            ListTile(title: Text(l10n.naval_units_noShipsInFleet), dense: true)
          else ...[
            for (final entry in row.shipCountsByType.entries)
              ListTile(
                title: Text(
                  '${shipTypeDisplayName(entry.key)}: ${entry.value}',
                ),
                dense: true,
              ),
          ],
          ListTile(
            title: Text(
              l10n.naval_units_strength(row.strength.toStringAsFixed(1)),
            ),
            dense: true,
          ),
          ListTile(
            title: Text(
              row.isHomeFleet
                  ? l10n.naval_units_cargoCapacity(row.cargoCapacity)
                  : l10n.naval_units_cargoCapacityIfAssigned(row.cargoCapacity),
            ),
            dense: true,
          ),
          if (isSplitAllowed)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onMoveFleet != null) ...[
                    CtNinePatchButton(
                      onPressed: onMoveFleet,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minHeight: 36,
                      child: Text(l10n.common_move),
                    ),
                    const SizedBox(width: 8),
                  ],
                  CtNinePatchButton(
                    onPressed: onSplitFleet,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minHeight: 36,
                    child: Text(l10n.common_split),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
