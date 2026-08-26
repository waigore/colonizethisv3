import 'package:colonizethis_world/colonizethis_world.dart'
    show applyNavalCombineFleets, resolveNavalCombineTargetFleetId;

import 'package:colonizethis_models/colonizethis_models.dart';

import '../../panels/tree_builders/naval_tree_builder.dart';
import '../shared/base_units_panel.dart';
import 'naval_units_panel.dart';
import 'naval_units_panel_state_base.dart';
import 'naval_units_panel_support_combine_home.dart';

mixin NavalUnitsPanelCombine
    on
        BaseUnitsPanelState<NavalUnitsPanel>,
        NavalUnitsPanelStateBase,
        NavalUnitsPanelCombineHome {
  bool canCombineSelection(List<FleetRow> flat) {
    final rowsById = <String, FleetRow>{
      for (final r in flat) selectionFleetId(r): r,
    };
    final activeIds = selection.selectedIds
        .where(rowsById.containsKey)
        .toList();
    if (activeIds.length < 2) return false;
    final homeTransferRows = homeTransferRowsFor(flat, activeIds.toSet());
    if (homeTransferRows != null) {
      return isEligibleHomeTransferSource(homeTransferRows.source);
    }
    String? locationKey;
    for (final id in activeIds) {
      final row = rowsById[id]!;
      locationKey ??= row.locationKey;
      if (row.locationKey != locationKey) return false;
    }
    return true;
  }

  String combineTargetFleetId(List<FleetRow> flat, Set<String> selected) {
    final preferIds = <String>[
      for (final row in flat)
        if (selected.contains(selectionFleetId(row))) selectionFleetId(row),
    ];
    if (preferIds.isEmpty) {
      throw StateError('combine target: empty selection');
    }
    return resolveNavalCombineTargetFleetId(
      humanPlayerId: widget.humanPlayerId,
      fleetIdsInPreferOrder: preferIds,
    );
  }

  void toggleFleetSelection(FleetRow row) {
    toggleSelection(selectionFleetId(row));
  }

  Iterable<String> fleetSelectionIds(List<FleetRow> flat) =>
      flat.map(selectionFleetId);

  /// Select-all header: from none or partial → select every row; from all → clear.
  /// Does not rely on [Checkbox] tristate `next` (indeterminate taps may pass false).
  void onHeaderSelectAllTapped(List<FleetRow> flat) {
    selectAllOrClear(fleetSelectionIds(flat));
  }

  void performCombine(List<FleetRow> flat) {
    if (!canCombineSelection(flat)) return;

    final selected = Set<String>.from(selection.selectedIds);
    final homeTransferRows = homeTransferRowsFor(flat, selected);
    if (homeTransferRows != null &&
        isEligibleHomeTransferSource(homeTransferRows.source)) {
      openTransferToHomeDialog(
        homeRow: homeTransferRows.home,
        sourceRow: homeTransferRows.source,
      );
      return;
    }
    // Prefer-order matches panel display order among the selection.
    final preferIds = <String>[
      for (final row in flat)
        if (selected.contains(selectionFleetId(row))) selectionFleetId(row),
    ];
    final newGame = applyNavalCombineFleets(
      game: widget.game,
      humanPlayerId: widget.humanPlayerId,
      fleetIds: preferIds,
    );

    clearSelection();
    widget.bus.emit(NavalFleetsUpdatedEvent(game: newGame));
  }

  ({FleetRow home, FleetRow source})? homeTransferRowsFor(
    List<FleetRow> flat,
    Set<String> selectedIds,
  ) {
    if (selectedIds.length != 2) return null;
    FleetRow? home;
    FleetRow? source;
    for (final row in flat) {
      final id = selectionFleetId(row);
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
}
