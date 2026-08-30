import 'package:colonizethis_world/colonizethis_world.dart'
    show GamePlayerLookup, homeFleetIdFor;

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../panels/tree_builders/naval_tree_builder.dart';
import '../../unit_orders/transfer_to_home_fleet_dialog.dart';
import '../shared/base_units_panel.dart';
import 'home_fleet_transfer_eligibility.dart';
import 'naval_units_panel.dart';
import 'naval_units_panel_state_base.dart';

mixin NavalUnitsPanelCombineHome
    on BaseUnitsPanelState<NavalUnitsPanel>, NavalUnitsPanelStateBase {
  String selectionFleetId(FleetRow row) {
    if (row.isHomeFleet) return homeFleetIdFor(widget.humanPlayerId);
    return row.fleetId;
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

  String? humanCapitalProvinceId() =>
      widget.game.playerById(widget.humanPlayerId)?.capitalProvinceId;

  bool isEligibleHomeTransferSource(FleetRow sourceRow) {
    final sourceFleet = fleetForRow(sourceRow);
    final capitalProvinceId = humanCapitalProvinceId();
    if (sourceFleet == null || capitalProvinceId == null) return false;
    return isEligibleHomeTransferSourceFleet(
      sourceFleet: sourceFleet,
      humanPlayerId: widget.humanPlayerId,
      capitalProvinceId: capitalProvinceId,
      topology: widget.topology,
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
        overseasCargoUsed: widget.overseasCargoUsed,
        isCargoUsedReliable: widget.isCargoUsedReliable,
        cargoNotDefined: widget.cargoNotDefined,
      ),
    );
  }
}
