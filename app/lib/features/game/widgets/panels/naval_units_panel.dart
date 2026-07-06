// Naval units panel. SPEC/ui/naval-units-panel.md.

import 'dart:async';

import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show GamePlayerLookup, homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../config/ct_e2e.dart';
import '../../../../config/ct_e2e_last_panel_snapshot.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../../../core/services/app_event_bus_panel_nav.dart';
import '../../../../core/services/app_event_handler_scope.dart'
    show trainNavalDialogId;
import '../../../../l10n/l10n.dart';
import '../chrome/ct_action_text_button.dart';
import '../fleet_expansion_tile.dart';
import 'game_panel_contract.dart';
import '../utils/naval_tree_builder.dart';
import '../move_fleet_dialog.dart';
import '../split_fleet_dialog.dart';
import '../transfer_to_home_fleet_dialog.dart';
import '../units/shared/base_units_panel.dart';
import '../units/shared/location_section_header.dart';
import '../units/shared/region_section_header.dart';
import '../../utils/region_labels.dart';

part 'naval_units_panel_support_combine.dart';
part 'naval_units_panel_support_home_transfer.dart';
part 'naval_units_panel_support_dialogs.dart';

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

class _NavalUnitsPanelState extends BaseUnitsPanelState<NavalUnitsPanel> {
  final Set<String> _visibleScopedFleetIds = <String>{};
  StreamSubscription<NavalMoveFleetRequestedEvent>? _moveRequestedSub;
  bool _pendingScopedAutoCloseAfterMove = false;

  @override
  void initState() {
    super.initState();
    final id = widget.initialSelectedFleetId;
    if (id != null && id.isNotEmpty) {
      // initState runs before the first build, so mutate the store directly
      // rather than via the `setState`-wrapped dispatch.
      selection.toggle(id);
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
      final prunedAny = !selection.selectedIds.every(valid.contains);
      if (prunedAny) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => selection.retainOnly(valid));
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
    final readOnly = widget.readOnly;

    // Header actions render as compact **primary** pills
    // (`CtActionTextButton(primary: true)`) per SPEC/ui/naval-units-panel.md
    // § Header actions and issue #3514 owner decisions #5 / #15. The optional
    // tile-scope pill (and its 4px spacer) leads the shared select-all +
    // Combine cluster assembled by `BaseUnitsPanelState.buildUnitsPanel`.
    final panel = buildUnitsPanel(
      title: tileScopeActive
          ? l10n.naval_units_title_tile
          : l10n.naval_units_title,
      leadingActions: [
        if (tileScopeActive)
          CtActionTextButton(
            primary: true,
            enabled: widget.tileScopeTileKey!.isNotEmpty,
            onPressed: () {
              final key = widget.tileScopeTileKey!;
              widget.bus.closePanelThenEmit(
                OpenMapTileDetailEvent(tileKey: key),
              );
            },
            label: l10n.civilian_units_tile,
          ),
        if (tileScopeActive && hasAny && flat.isNotEmpty)
          const SizedBox(width: 4),
      ],
      trailingActions: [
        CtActionTextButton(
          primary: true,
          onPressed: readOnly ? null : _openTrainDialog,
          enabled: !readOnly,
          label: l10n.common_train,
        ),
      ],
      showCombineCluster: hasAny && flat.isNotEmpty && !readOnly,
      selectableIds: _fleetSelectionIds(flat),
      selectAllTooltip: l10n.naval_units_selectAllFleets,
      deselectAllTooltip: l10n.naval_units_deselectAllFleets,
      combineLabel: l10n.common_combine,
      canCombine: canCombine,
      onSelectAll: () => _onHeaderSelectAllTapped(flat),
      onCombine: () => _performCombine(flat),
      hasContent: hasAny,
      listChildren: [
        for (final group in tree) ...[
          RegionSectionHeader(
            label: regionDisplayLabel(group.regionId),
            variant: RegionHeaderVariant.leftBar,
          ),
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
              isSelectedForCombine: isSelected(
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
                isSelectedForCombine: isSelected(_selectionFleetId(row)),
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
