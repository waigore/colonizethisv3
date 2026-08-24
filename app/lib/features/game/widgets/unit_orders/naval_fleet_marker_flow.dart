// Map fleet-marker tap routing (Refs #4213, #4343, #4448, #4625).
// SPEC/program/app-ui-wiring.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import '../../../../providers/home_fleet_cargo_provider.dart';
import '../units/naval/home_fleet_transfer_eligibility.dart';
import 'home_fleet_detach_then_sail_flow.dart';
import 'in_port_fleet_marker_actions_dialog.dart';
import 'naval_mission_flow.dart';
import 'naval_mission_flow_support.dart';
import 'naval_mission_move_dialog.dart';
import 'overlay_transfer_to_home_fleet_flow.dart';

/// Map fleet-marker tap: pick fleet when stacked, then route to the legal action.
///
/// Home Fleet (non-empty) → detach-then-sail; empty Home Fleet → tile-scoped
/// [OpenNavalUnitsPanelEvent]; capital in-port eligible transfer →
/// [InPortFleetMarkerActionsDialog] then Move or Transfer; other in-port →
/// [MoveFleetDialog]; sea-going at sea → [showNavalMissionFlow]
/// (Refs #4343, #4448, #4625).
Future<void> showNavalFleetMarkerFlow({
  required BuildContext context,
  required Game game,
  required MapTopology topology,
  required String humanPlayerId,
  required Orders draftOrders,
  required AppEventBus bus,
  required List<String> fleetIds,
  required String locationScopeKey,
  String? preselectedFleetId,
  String? tileScopeTileKey,
  int overseasCargoUsed = 0,
  int homeFleetCargoCapacity = 0,
  bool isCargoUsedReliable = true,
  bool cargoNotDefined = false,
}) async {
  if (fleetIds.isEmpty) return;

  final selectedFleetId = await pickNavalMissionFleetId(
    context: context,
    game: game,
    humanPlayerId: humanPlayerId,
    fleetIds: fleetIds,
    preselectedFleetId: preselectedFleetId,
  );
  if (selectedFleetId == null || !context.mounted) return;

  final fleet = game.fleetById(selectedFleetId);
  if (fleet == null || !context.mounted) return;

  if (fleet.id == homeFleetIdFor(humanPlayerId)) {
    if (fleet.ships.isEmpty) {
      bus.emit(
        OpenNavalUnitsPanelEvent(
          locationScopeKey: locationScopeKey,
          initialSelectedFleetId: fleet.id,
          tileScopeTileKey: tileScopeTileKey,
        ),
      );
      return;
    }
    await showHomeFleetDetachThenSailFlow(
      context: context,
      game: game,
      topology: topology,
      humanPlayerId: humanPlayerId,
      bus: bus,
      overseasCargoUsed: overseasCargoUsed,
      isCargoUsedReliable: isCargoUsedReliable,
      cargoNotDefined: cargoNotDefined,
    );
    return;
  }

  if (!fleet.isAtSea) {
    final routed = await _tryCapitalInPortTransferThenMove(
      context: context,
      game: game,
      topology: topology,
      humanPlayerId: humanPlayerId,
      bus: bus,
      fleet: fleet,
      overseasCargoUsed: overseasCargoUsed,
      homeFleetCargoCapacity: homeFleetCargoCapacity,
      isCargoUsedReliable: isCargoUsedReliable,
      cargoNotDefined: cargoNotDefined,
    );
    if (routed || !context.mounted) return;
    await showMoveFleetDialogForFleet(
      context: context,
      game: game,
      topology: topology,
      humanPlayerId: humanPlayerId,
      fleet: fleet,
      bus: bus,
    );
    return;
  }

  await showNavalMissionFlow(
    context: context,
    game: game,
    topology: topology,
    humanPlayerId: humanPlayerId,
    draftOrders: draftOrders,
    bus: bus,
    fleetIds: [fleet.id],
    preselectedFleetId: fleet.id,
  );
}

/// Returns true when Transfer was chosen (Move is left to the caller).
Future<bool> _tryCapitalInPortTransferThenMove({
  required BuildContext context,
  required Game game,
  required MapTopology topology,
  required String humanPlayerId,
  required AppEventBus bus,
  required Fleet fleet,
  required int overseasCargoUsed,
  required int homeFleetCargoCapacity,
  required bool isCargoUsedReliable,
  required bool cargoNotDefined,
}) async {
  final capitalProvinceId = game.playerById(humanPlayerId)?.capitalProvinceId;
  final home = game.fleetById(homeFleetIdFor(humanPlayerId));
  final canTransfer =
      capitalProvinceId != null &&
      home != null &&
      isEligibleHomeTransferSourceFleet(
        sourceFleet: fleet,
        humanPlayerId: humanPlayerId,
        capitalProvinceId: capitalProvinceId,
        topology: topology,
      );
  if (!canTransfer) return false;
  final choice = await showDialog<InPortFleetMarkerAction>(
    context: context,
    builder: (_) => const InPortFleetMarkerActionsDialog(),
  );
  if (!context.mounted || choice == null) return true;
  if (choice != InPortFleetMarkerAction.transferHome) return false;
  await showOverlayTransferToHomeFleetFlow(
    context: context,
    game: game,
    humanPlayerId: humanPlayerId,
    bus: bus,
    homeFleet: home,
    sourceFleets: [fleet],
    cargo: HomeFleetCargoSummary(
      used: overseasCargoUsed,
      capacity: homeFleetCargoCapacity,
      isCargoUsedReliable: isCargoUsedReliable,
      notDefined: cargoNotDefined,
    ),
  );
  return true;
}
