/// Dialog openers and combine mutations for military army actions.
/// SPEC/ui/military-units-panel.md.
library;

import 'package:colonizethis_world/colonizethis_world.dart' show buildPlayerView;

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../../core/services/app_event_bus_panel_nav.dart';
import '../../../../../core/services/app_event_handler/app_event_handler_scope.dart'
    show trainMilitaryDialogId;
import '../../panels/tree_builders/military_tree_builder.dart';
import '../../unit_orders/move_army_dialog.dart';
import '../../unit_orders/split_army_dialog.dart';
import '../shared/base_units_panel.dart';
import 'military_units_panel.dart';

mixin MilitaryUnitsPanelDialogs on BaseUnitsPanelState<MilitaryUnitsPanel> {
  Iterable<String> armyIds(List<ArmyBlock> flat) => flat.map((b) => b.army.id);

  void performCombine(List<ArmyBlock> flat) {
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

  void openTrainDialog() {
    widget.bus.closePanelThenEmit(OpenDialogEvent(trainMilitaryDialogId));
  }

  void openSplitDialog(ArmyBlock block) {
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

  void openMoveDialog(ArmyBlock block) {
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
