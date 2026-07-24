import 'package:colonizethis_app/core/utils/prefixed_id.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show GamePlayerLookup, homeFleetIdFor;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../panels/tree_builders/naval_tree_builder.dart';
import '../../unit_orders/transfer_to_home_fleet_dialog.dart';
import '../shared/base_units_panel.dart';
import 'naval_units_panel.dart';
import 'naval_units_panel_state_base.dart';

mixin NavalUnitsPanelCombine
    on BaseUnitsPanelState<NavalUnitsPanel>, NavalUnitsPanelStateBase {
  /// Canonical fleet id for combine/split selection (Home Fleet uses [homeFleetIdFor]).
  String selectionFleetId(FleetRow row) {
    if (row.isHomeFleet) return homeFleetIdFor(widget.humanPlayerId);
    return row.fleetId;
  }

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

  Fleet? fleetForRow(FleetRow row) {
    final id = selectionFleetId(row);
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

  String? humanCapitalProvinceId() {
    for (final p in widget.game.players) {
      if (p.id == widget.humanPlayerId) return p.capitalProvinceId;
    }
    return null;
  }

  bool provinceMatchesCapital(String provinceId, String capitalProvinceId) {
    if (provinceId == capitalProvinceId) return true;
    final capRegionId = ProvinceId.regionIdFrom(capitalProvinceId);
    final capLocalId = ProvinceId.localIdFrom(capitalProvinceId);
    return provinceId == capLocalId || provinceId == '$capRegionId|$capLocalId';
  }

  bool seaZoneAdjacentToCapital({
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

  bool isEligibleHomeTransferSource(FleetRow sourceRow) {
    final sourceFleet = fleetForRow(sourceRow);
    final capitalProvinceId = humanCapitalProvinceId();
    if (sourceFleet == null || capitalProvinceId == null) return false;
    if (sourceFleet.ownerId != widget.humanPlayerId) return false;
    if (!sourceFleet.isAtSea) {
      final inPortId = sourceFleet.inPortAtProvinceId;
      if (inPortId == null) return false;
      return provinceMatchesCapital(inPortId, capitalProvinceId);
    }
    final seaZoneId = sourceFleet.seaZoneId;
    if (seaZoneId == null || seaZoneId.isEmpty) return false;
    return seaZoneAdjacentToCapital(
      sourceSeaZoneId: seaZoneId,
      sourceRegionId: sourceFleet.regionId,
      capitalProvinceId: capitalProvinceId,
    );
  }

  void openTransferToHomeDialog({
    required FleetRow homeRow,
    required FleetRow sourceRow,
  }) {
    final homeFleet = fleetForRow(homeRow);
    final sourceFleet = fleetForRow(sourceRow);
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
}
