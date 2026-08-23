import 'package:colonizethis_world/colonizethis_world.dart' show homeFleetIdFor;

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
    for (final row in flat) {
      final id = selectionFleetId(row);
      if (!selected.contains(id)) continue;
      if (row.isHomeFleet) return id;
    }
    for (final row in flat) {
      final id = selectionFleetId(row);
      if (selected.contains(id)) return id;
    }
    throw StateError('combine target: empty selection');
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
    final targetId = combineTargetFleetId(flat, selected);

    FleetRow? targetRow;
    for (final row in flat) {
      if (selectionFleetId(row) == targetId) {
        targetRow = row;
        break;
      }
    }
    if (targetRow == null) return;

    final targetFleet = fleetForRow(targetRow);
    if (targetFleet == null) return;

    final mergedShips = <ShipInstance>[...targetFleet.ships];
    for (final row in flat) {
      final id = selectionFleetId(row);
      if (!selected.contains(id) || id == targetId) continue;
      final f = fleetForRow(row);
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
