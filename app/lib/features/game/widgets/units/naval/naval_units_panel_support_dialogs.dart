/// Dialog openers for naval fleet actions. SPEC/ui/naval-units-panel.md.

part of 'naval_units_panel.dart';

extension _NavalUnitsPanelDialogs on _NavalUnitsPanelState {
  void _openTrainDialog() {
    widget.bus.closePanelThenEmit(OpenDialogEvent(trainNavalDialogId));
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
}
