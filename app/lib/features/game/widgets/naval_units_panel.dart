// Naval units panel. SPEC/ui/naval-units-panel.md.

import 'dart:async';

import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show GamePlayerLookup, homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/ct_e2e.dart';
import '../../../config/ct_e2e_last_panel_snapshot.dart';
import '../../../config/ui_screen_ids.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_spacing.dart';
import 'fleet_expansion_tile.dart';
import 'game_panel_contract.dart';
import 'utils/naval_tree_builder.dart';
import 'move_fleet_dialog.dart';
import 'split_fleet_dialog.dart';
import 'transfer_to_home_fleet_dialog.dart';
import 'units/shared/location_section_header.dart';
import 'units/shared/region_section_header.dart';
import 'units/shared/units_panel_shell.dart';
import '../utils/region_labels.dart';

class NavalUnitsPanel extends StatefulWidget with GamePanelMixin {
  const NavalUnitsPanel({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.bus,
    required this.topology,
    this.draftOrders = const Orders(),
    this.tileMapByRegion,
    this.topologyByRegion,
    this.locationScopeKey,
    this.initialSelectedFleetId,
    this.tileScopeTileKey,
    this.readOnly = false,
  });

  /// SPEC/ui/naval-units-panel.md — [UiScreenIds.navalUnitsPanel].
  static const screenId = UiScreenIds.navalUnitsPanel;

  @override
  final Game game;
  @override
  final String humanPlayerId;
  @override
  final AppEventBus bus;
  final MapTopology topology;
  final Orders draftOrders;
  final Map<String, TileMapResult>? tileMapByRegion;
  final Map<String, MapTopology>? topologyByRegion;
  final String? locationScopeKey;
  final String? initialSelectedFleetId;
  final String? tileScopeTileKey;
  @override
  final bool readOnly;

  @override
  State<NavalUnitsPanel> createState() => _NavalUnitsPanelState();
}

class _NavalUnitsPanelState extends State<NavalUnitsPanel> {
  final Set<String> _selectedFleetIds = {};
  final Set<String> _visibleScopedFleetIds = <String>{};
  static const double _desktopViewportThreshold = 1280;
  static const double _scaledWidthMin = 420;
  static const double _scaledWidthMax = 640;
  static const double _scaledViewportFactor = 0.36;
  StreamSubscription<NavalMoveFleetRequestedEvent>? _moveRequestedSub;
  bool _pendingScopedAutoCloseAfterMove = false;

  @override
  void initState() {
    super.initState();
    final id = widget.initialSelectedFleetId;
    if (id != null && id.isNotEmpty) {
      _selectedFleetIds.add(id);
    }
    _moveRequestedSub = widget.bus.on<NavalMoveFleetRequestedEvent>().listen((
      event,
    ) {
      if (widget.locationScopeKey == null) return;
      if (_visibleScopedFleetIds.contains(event.moveOrder.fleetId)) {
        _pendingScopedAutoCloseAfterMove = true;
      }
    });
  }

  @override
  void dispose() {
    _moveRequestedSub?.cancel();
    super.dispose();
  }

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
    final homeTransferRows = _homeTransferRows(flat, activeIds.toSet());
    if (homeTransferRows != null) {
      return _isEligibleHomeTransferSource(homeTransferRows.source);
    }
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
    final found = widget.game.fleetById(id);
    if (found != null) return found;
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
        _selectedFleetIds.clear();
        _selectedFleetIds.addAll(ids);
      }
    });
  }

  void _performCombine(List<FleetRow> flat) {
    if (!_canCombineSelection(flat)) return;

    final selected = Set<String>.from(_selectedFleetIds);
    final homeTransferRows = _homeTransferRows(flat, selected);
    if (homeTransferRows != null &&
        _isEligibleHomeTransferSource(homeTransferRows.source)) {
      _openTransferToHomeDialog(
        homeRow: homeTransferRows.home,
        sourceRow: homeTransferRows.source,
      );
      return;
    }
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

  ({FleetRow home, FleetRow source})? _homeTransferRows(
    List<FleetRow> flat,
    Set<String> selectedIds,
  ) {
    if (selectedIds.length != 2) return null;
    FleetRow? home;
    FleetRow? source;
    for (final row in flat) {
      final id = _selectionFleetId(row);
      if (!selectedIds.contains(id)) continue;
      if (row.isHomeFleet) {
        home = row;
      } else {
        source = row;
      }
    }
    if (home == null || source == null) return null;
    return (home: home, source: source);
  }

  String? _humanCapitalProvinceId() {
    for (final p in widget.game.players) {
      if (p.id == widget.humanPlayerId) return p.capitalProvinceId;
    }
    return null;
  }

  bool _provinceMatchesCapital(String provinceId, String capitalProvinceId) {
    if (provinceId == capitalProvinceId) return true;
    final capRegionId = ProvinceId.regionIdFrom(capitalProvinceId);
    final capLocalId = ProvinceId.localIdFrom(capitalProvinceId);
    return provinceId == capLocalId || provinceId == '$capRegionId|$capLocalId';
  }

  bool _seaZoneAdjacentToCapital({
    required String sourceSeaZoneId,
    required String sourceRegionId,
    required String capitalProvinceId,
  }) {
    final capRegionId = ProvinceId.regionIdFrom(capitalProvinceId);
    final capLocalId = ProvinceId.localIdFrom(capitalProvinceId);
    final sourceSeaLocal = prefixedIdLocalSegment(sourceSeaZoneId);
    final sourceSeaPrefixed = prefixedIdHasDelimiter(sourceSeaZoneId)
        ? sourceSeaZoneId
        : '$sourceRegionId|$sourceSeaZoneId';
    final sourceSeaCandidates = <String>{
      sourceSeaZoneId,
      sourceSeaLocal,
      sourceSeaPrefixed,
    };
    final capitalCandidates = <String>{
      capitalProvinceId,
      capLocalId,
      '$capRegionId|$capLocalId',
    };
    for (final edge in widget.topology.edges) {
      final a = edge.id1;
      final b = edge.id2;
      final aIsSea = sourceSeaCandidates.contains(a);
      final bIsSea = sourceSeaCandidates.contains(b);
      final aIsCap = capitalCandidates.contains(a);
      final bIsCap = capitalCandidates.contains(b);
      if ((aIsSea && bIsCap) || (bIsSea && aIsCap)) {
        return true;
      }
    }
    return false;
  }

  bool _isEligibleHomeTransferSource(FleetRow sourceRow) {
    final sourceFleet = _fleetForRow(sourceRow);
    final capitalProvinceId = _humanCapitalProvinceId();
    if (sourceFleet == null || capitalProvinceId == null) return false;
    if (sourceFleet.ownerId != widget.humanPlayerId) return false;
    if (!sourceFleet.isAtSea) {
      final inPortId = sourceFleet.inPortAtProvinceId;
      if (inPortId == null) return false;
      return _provinceMatchesCapital(inPortId, capitalProvinceId);
    }
    final seaZoneId = sourceFleet.seaZoneId;
    if (seaZoneId == null || seaZoneId.isEmpty) return false;
    return _seaZoneAdjacentToCapital(
      sourceSeaZoneId: seaZoneId,
      sourceRegionId: sourceFleet.regionId,
      capitalProvinceId: capitalProvinceId,
    );
  }

  void _openTransferToHomeDialog({
    required FleetRow homeRow,
    required FleetRow sourceRow,
  }) {
    final homeFleet = _fleetForRow(homeRow);
    final sourceFleet = _fleetForRow(sourceRow);
    if (homeFleet == null || sourceFleet == null) return;
    showDialog<void>(
      context: context,
      builder: (_) => TransferToHomeFleetDialog(
        sourceFleet: sourceFleet,
        homeFleet: homeFleet,
        game: widget.game,
        humanPlayerId: widget.humanPlayerId,
        bus: widget.bus,
      ),
    );
  }

  @override
  void didUpdateWidget(covariant NavalUnitsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final gameOrDraftChanged =
        oldWidget.game != widget.game ||
        oldWidget.draftOrders != widget.draftOrders;
    if (gameOrDraftChanged) {
      final oldFlat = flattenNavalTree(
        buildNavalTree(
          oldWidget.game,
          oldWidget.humanPlayerId,
          oldWidget.topology,
          oldWidget.draftOrders,
          appL10n(context),
          tileMapByRegion: oldWidget.tileMapByRegion,
          topologyByRegion: oldWidget.topologyByRegion,
          locationScopeKeyFilter: oldWidget.locationScopeKey,
        ),
      );
      final flat = flattenNavalTree(
        buildNavalTree(
          widget.game,
          widget.humanPlayerId,
          widget.topology,
          widget.draftOrders,
          appL10n(context),
          tileMapByRegion: widget.tileMapByRegion,
          topologyByRegion: widget.topologyByRegion,
          locationScopeKeyFilter: widget.locationScopeKey,
        ),
      );
      final valid = flat.map(_selectionFleetId).toSet();
      final pruned = _selectedFleetIds.intersection(valid);
      if (pruned.length != _selectedFleetIds.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _selectedFleetIds.clear();
            _selectedFleetIds.addAll(pruned);
          });
        });
      }
      if (_pendingScopedAutoCloseAfterMove &&
          widget.locationScopeKey != null &&
          oldFlat.isNotEmpty &&
          flat.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.bus.emit(const ClosePanelEvent());
        });
      }
      if (_pendingScopedAutoCloseAfterMove) {
        _pendingScopedAutoCloseAfterMove = false;
      }
    }
  }

  void _openSplitDialog(FleetRow row) {
    final id = _selectionFleetId(row);
    final fleet = widget.game.fleetById(id);
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

  Future<void> _openMoveFleetDialog(FleetRow row) async {
    if (row.isHomeFleet) return;
    final fleet = widget.game.fleetById(row.fleetId);
    final nonNullFleet = fleet;
    if (nonNullFleet == null) return;
    await showDialog<bool>(
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

  BoxConstraints _panelConstraints(BuildContext context) {
    final viewportWidth = MediaQuery.sizeOf(context).width;
    if (viewportWidth < _desktopViewportThreshold) {
      return UnitsPanelShell.defaultPanelConstraints;
    }
    final scaledWidth = (viewportWidth * _scaledViewportFactor).clamp(
      _scaledWidthMin,
      _scaledWidthMax,
    );
    return BoxConstraints(
      maxWidth: scaledWidth,
      maxHeight: UnitsPanelShell.defaultPanelConstraints.maxHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final tileScopeActive =
        widget.tileScopeTileKey != null && widget.tileScopeTileKey!.isNotEmpty;
    final tree = buildNavalTree(
      widget.game,
      widget.humanPlayerId,
      widget.topology,
      widget.draftOrders,
      l10n,
      tileMapByRegion: widget.tileMapByRegion,
      topologyByRegion: widget.topologyByRegion,
      locationScopeKeyFilter: widget.locationScopeKey,
    );
    final flat = flattenNavalTree(tree);
    _visibleScopedFleetIds.clear();
    _visibleScopedFleetIds.addAll(flat.map((row) => row.fleetId));
    final hasAny = tree.any(
      (group) => group.homeFleet != null || group.locations.isNotEmpty,
    );
    final canCombine = !widget.readOnly && _canCombineSelection(flat);
    final headerCheckbox = _headerSelectAllValue(flat);
    final readOnly = widget.readOnly;

    final panel = UnitsPanelShell(
      title: tileScopeActive
          ? l10n.naval_units_title_tile
          : l10n.naval_units_title,
      actions: [
        if (tileScopeActive)
          CtNinePatchButton(
            enabled: widget.tileScopeTileKey!.isNotEmpty,
            onPressed: () {
              final key = widget.tileScopeTileKey!;
              widget.bus.emit(const ClosePanelEvent());
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.bus.emit(OpenMapTileDetailEvent(tileKey: key));
              });
            },
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: CtSpacing.s,
            ),
            minHeight: 32,
            child: Text(l10n.civilian_units_tile),
          ),
        if (tileScopeActive && hasAny && flat.isNotEmpty)
          const SizedBox(width: 4),
        if (hasAny && flat.isNotEmpty && !readOnly) ...[
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
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: CtSpacing.s,
            ),
            minHeight: 32,
            child: Text(l10n.common_combine),
          ),
        ],
      ],
      hasContent: hasAny,
      listChildren: [
        for (final group in tree) ...[
          RegionSectionHeader(label: regionDisplayLabel(group.regionId)),
          if (group.homeFleet != null)
            FleetExpansionTile(
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
              combineSelectionEnabled: !readOnly,
              onCombineSelectionToggle: () =>
                  _toggleFleetSelection(group.homeFleet!),
              onSplitFleet: readOnly
                  ? null
                  : () => _openSplitDialog(group.homeFleet!),
              onMoveFleet: null,
              isSplitAllowed: !readOnly,
            ),
          for (final loc in group.locations) ...[
            LocationSectionHeader(
              label: loc.displayLabel,
              regionLabel: regionDisplayLabel(loc.regionId),
            ),
            for (final row in loc.fleets)
              FleetExpansionTile(
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
                combineSelectionEnabled: !readOnly,
                onCombineSelectionToggle: () => _toggleFleetSelection(row),
                onSplitFleet: readOnly ? null : () => _openSplitDialog(row),
                onMoveFleet: readOnly ? null : () => _openMoveFleetDialog(row),
                isSplitAllowed: true,
              ),
          ],
        ],
      ],
      emptyMessage: l10n.naval_units_empty,
      panelConstraints: _panelConstraints(context),
    );
    if (kCtE2EEnabled) {
      updateCtE2eNavalPanelSnapshotIfEnabled(
        CtE2eNavalPanelSnapshot(
          game: widget.game,
          humanPlayerId: widget.humanPlayerId,
          topology: widget.topology,
          draftOrders: widget.draftOrders,
          tileMapByRegion: widget.tileMapByRegion,
          topologyByRegion: widget.topologyByRegion,
          locationScopeKey: widget.locationScopeKey,
          initialSelectedFleetId: widget.initialSelectedFleetId,
          tileScopeTileKey: widget.tileScopeTileKey,
        ),
      );
      return KeyedSubtree(key: kCtE2ENavalPanelRootKey, child: panel);
    }
    return panel;
  }
}
