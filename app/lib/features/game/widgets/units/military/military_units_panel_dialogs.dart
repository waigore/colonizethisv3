/// Dialog openers and combine mutations for military army actions.
/// SPEC/ui/military-units-panel.md.

part of 'military_units_panel.dart';

extension _MilitaryUnitsPanelDialogs on _MilitaryUnitsPanelState {
  Iterable<String> _armyIds(List<ArmyBlock> flat) =>
      flat.map((b) => b.army.id);

  void _performCombine(List<ArmyBlock> flat) {
    if (!canCombineArmySelection(flat, selection.selectedIds)) return;
    final ids = selection.selectedIds.toList()..sort();
    widget.bus.emit(
      ArmyCombineRequestedEvent(
        humanPlayerId: widget.humanPlayerId,
        armyIds: ids,
      ),
    );
    clearSelection();
  }

  void _openTrainDialog() {
    widget.bus.closePanelThenEmit(OpenDialogEvent(trainMilitaryDialogId));
  }

  void _openSplitDialog(ArmyBlock block) {
    showDialog<void>(
      context: context,
      builder: (ctx) => SplitArmyDialog(
        army: block.army,
        game: widget.game,
        humanPlayerId: widget.humanPlayerId,
        bus: widget.bus,
        isHomeArmy: block.army.isHomeArmy,
      ),
    );
  }

  void _openMoveDialog(ArmyBlock block) {
    final playerView = buildPlayerView(
      widget.game,
      widget.topology,
      widget.humanPlayerId,
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => MoveArmyDialog(
        army: block.army,
        game: widget.game,
        humanPlayerId: widget.humanPlayerId,
        bus: widget.bus,
        topology: widget.topology,
        draftOrders: widget.draftOrders,
        playerView: playerView,
      ),
    );
  }
}
