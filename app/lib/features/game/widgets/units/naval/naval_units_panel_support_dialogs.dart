import 'package:colonizethis_world/colonizethis_world.dart'
    show GamePlayerLookup;

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../../core/services/app_event_bus_panel_nav.dart';
import '../../../../../core/services/app_event_handler/app_event_handler_scope.dart'
    show trainNavalDialogId;
import '../../panels/tree_builders/naval_tree_builder.dart';
import '../../unit_orders/naval_mission_flow.dart';
import '../../unit_orders/split_fleet_dialog.dart';
import '../shared/base_units_panel.dart';
import 'naval_units_panel.dart';
import 'naval_units_panel_state_base.dart';
import 'naval_units_panel_support_combine.dart';

mixin NavalUnitsPanelDialogs
    on
        BaseUnitsPanelState<NavalUnitsPanel>,
        NavalUnitsPanelStateBase,
        NavalUnitsPanelCombine {
  void openTrainDialog() {
    widget.bus.closePanelThenEmit(OpenDialogEvent(trainNavalDialogId));
  }

  void openSplitDialog(FleetRow row) {
    final id = selectionFleetId(row);
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
        overseasCargoUsed: widget.overseasCargoUsed,
        isCargoUsedReliable: widget.isCargoUsedReliable,
        cargoNotDefined: widget.cargoNotDefined,
      ),
    );
  }

  Future<void> openMoveFleetDialog(FleetRow row) async {
    if (row.isHomeFleet) return;
    final fleet = widget.game.fleetById(row.fleetId);
    final nonNullFleet = fleet;
    if (nonNullFleet == null) return;
    await showMoveFleetDialogForFleet(
      context: context,
      game: widget.game,
      topology: widget.topology,
      humanPlayerId: widget.humanPlayerId,
      fleet: nonNullFleet,
      bus: widget.bus,
    );
  }

  Future<void> openNavalMissionDialog(FleetRow row) async {
    if (row.isHomeFleet || !row.isAtSea) return;
    await showNavalMissionFlow(
      context: context,
      game: widget.game,
      topology: widget.topology,
      humanPlayerId: widget.humanPlayerId,
      draftOrders: widget.draftOrders,
      bus: widget.bus,
      fleetIds: [row.fleetId],
      preselectedFleetId: row.fleetId,
    );
  }
}
