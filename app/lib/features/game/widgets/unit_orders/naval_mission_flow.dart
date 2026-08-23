// Naval mission assign + map fleet-marker routing (Refs #4213, #4343, #4448).
// SPEC/program/app-ui-wiring.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show navalMissionAvailabilityForFleet;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import 'home_fleet_detach_then_sail_flow.dart';
import 'naval_mission_flow_support.dart';
import 'naval_mission_flow_types.dart';
import 'naval_mission_menu_dialog.dart';
import 'naval_mission_move_dialog.dart';

export 'naval_mission_flow_types.dart';
export 'naval_mission_move_dialog.dart';

/// Map fleet-marker tap: pick fleet when stacked, then route to the legal action.
///
/// Home Fleet (non-empty) → detach-then-sail; empty Home Fleet → tile-scoped
/// [OpenNavalUnitsPanelEvent]; sea-going in port → [MoveFleetDialog];
/// sea-going at sea → [showNavalMissionFlow] (Refs #4343, #4448).
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

/// Opens the human naval mission assign flow for [fleetIds] (map at-sea or panel).
Future<void> showNavalMissionFlow({
  required BuildContext context,
  required Game game,
  required MapTopology topology,
  required String humanPlayerId,
  required Orders draftOrders,
  required AppEventBus bus,
  required List<String> fleetIds,
  String? preselectedFleetId,
  PlayerView? playerView,
  FleetMission? initialMission,
  String? initialTargetProvinceId,
}) async {
  if (fleetIds.isEmpty) return;
  final resolvedPlayerView =
      playerView ?? buildPlayerView(game, topology, humanPlayerId);

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

  final availability = navalMissionAvailabilityForFleet(
    game: game,
    topology: topology,
    playerId: humanPlayerId,
    fleet: fleet,
    currentOrders: draftOrders,
  );

  if (!availability.baseGatesPass && !availability.canCancelPending) {
    return;
  }

  final overlayMission = initialMission;
  if (overlayMission != null &&
      (overlayMission == FleetMission.blockade ||
          overlayMission == FleetMission.beachhead)) {
    await confirmNavalTargetedMission(
      context: context,
      game: game,
      humanPlayerId: humanPlayerId,
      bus: bus,
      fleet: fleet,
      mission: overlayMission,
      targets: overlayMission == FleetMission.blockade
          ? availability.blockadeTargetProvinceIds
          : availability.beachheadTargetProvinceIds,
      playerView: resolvedPlayerView,
      initialTargetProvinceId: initialTargetProvinceId,
    );
    return;
  }
  if (overlayMission != null &&
      (overlayMission == FleetMission.patrol ||
          overlayMission == FleetMission.defend)) {
    bus.emit(
      NavalMissionRequestedEvent(
        humanPlayerId: humanPlayerId,
        missionOrder: NavalMissionOrder(
          fleetId: fleet.id,
          mission: overlayMission.name,
        ),
      ),
    );
    return;
  }

  final choice = await showDialog<NavalMissionMenuChoice>(
    context: context,
    builder: (ctx) => NavalMissionMenuDialog(
      game: game,
      fleet: fleet,
      availability: availability,
    ),
  );
  if (choice == null || !context.mounted) return;

  switch (choice) {
    case NavalMissionMenuChoiceCancelPending():
      bus.emit(
        NavalMissionCancelRequestedEvent(
          humanPlayerId: humanPlayerId,
          fleetId: fleet.id,
        ),
      );
    case NavalMissionMenuChoiceSail():
      await showMoveFleetDialogForFleet(
        context: context,
        game: game,
        topology: topology,
        humanPlayerId: humanPlayerId,
        fleet: fleet,
        bus: bus,
        playerView: resolvedPlayerView,
      );
    case NavalMissionMenuChoiceMission(:final mission):
      if (mission == FleetMission.blockade ||
          mission == FleetMission.beachhead) {
        await confirmNavalTargetedMission(
          context: context,
          game: game,
          humanPlayerId: humanPlayerId,
          bus: bus,
          fleet: fleet,
          mission: mission,
          targets: mission == FleetMission.blockade
              ? availability.blockadeTargetProvinceIds
              : availability.beachheadTargetProvinceIds,
          playerView: resolvedPlayerView,
        );
      } else {
        bus.emit(
          NavalMissionRequestedEvent(
            humanPlayerId: humanPlayerId,
            missionOrder: NavalMissionOrder(
              fleetId: fleet.id,
              mission: mission.name,
            ),
          ),
        );
      }
  }
}
