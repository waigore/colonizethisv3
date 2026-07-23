/// Fleet combine/selection helpers. SPEC/ui/naval-units-panel.md.

part of 'naval_units_panel.dart';

extension _NavalUnitsPanelCombine on _NavalUnitsPanelState {
  /// Canonical fleet id for combine/split selection (Home Fleet uses [homeFleetIdFor]).
  String _selectionFleetId(FleetRow row) {
    if (row.isHomeFleet) return homeFleetIdFor(widget.humanPlayerId);
    return row.fleetId;
  }

  bool _canCombineSelection(List<FleetRow> flat) {
    final rowsById = <String, FleetRow>{
      for (final r in flat) _selectionFleetId(r): r,
    };
    final activeIds = selection.selectedIds
        .where(rowsById.containsKey)
        .toList();
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
    toggleSelection(_selectionFleetId(row));
  }

  Iterable<String> _fleetSelectionIds(List<FleetRow> flat) =>
      flat.map(_selectionFleetId);

  /// Select-all header: from none or partial → select every row; from all → clear.
  /// Does not rely on [Checkbox] tristate `next` (indeterminate taps may pass false).
  void _onHeaderSelectAllTapped(List<FleetRow> flat) {
    selectAllOrClear(_fleetSelectionIds(flat));
  }

  void _performCombine(List<FleetRow> flat) {
    if (!_canCombineSelection(flat)) return;

    final selected = Set<String>.from(selection.selectedIds);
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

    clearSelection();
    widget.bus.emit(NavalFleetsUpdatedEvent(game: newGame));
  }
}
