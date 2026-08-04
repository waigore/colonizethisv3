// Naval mission assign flow: fleet pick → mission menu → target pick (Refs #4213).
// SPEC/program/app-ui-wiring.md.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show navalMissionAvailabilityForFleet;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import '../../../../config/ui_screen_ids.dart';
import '../panels/tree_builders/fleet_mission_label.dart';
import 'naval_mission_menu_dialog.dart';
import 'naval_mission_target_dialog.dart';

/// Opens the human naval mission assign flow for [fleetIds] (map marker or panel).
Future<void> showNavalMissionFlow({
  required BuildContext context,
  required Game game,
  required MapTopology topology,
  required String humanPlayerId,
  required Orders draftOrders,
  required AppEventBus bus,
  required List<String> fleetIds,
  String? preselectedFleetId,
}) async {
  if (fleetIds.isEmpty) return;

  var selectedFleetId = preselectedFleetId;
  if (fleetIds.length > 1) {
    selectedFleetId = await showDialog<String>(
      context: context,
      builder: (ctx) => NavalMissionFleetPickerDialog(
        game: game,
        humanPlayerId: humanPlayerId,
        fleetIds: fleetIds,
        initialFleetId: preselectedFleetId,
      ),
    );
    if (selectedFleetId == null || !context.mounted) return;
  } else {
    selectedFleetId = fleetIds.first;
  }

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
    case NavalMissionMenuChoiceMission(:final mission):
      if (mission == FleetMission.blockade || mission == FleetMission.beachhead) {
        final targets = mission == FleetMission.blockade
            ? availability.blockadeTargetProvinceIds
            : availability.beachheadTargetProvinceIds;
        final targetId = await showDialog<String>(
          context: context,
          builder: (ctx) => NavalMissionTargetDialog(
            game: game,
            mission: mission,
            fleet: fleet,
            targetProvinceIds: targets,
          ),
        );
        if (targetId == null || !context.mounted) return;
        bus.emit(
          NavalMissionRequestedEvent(
            humanPlayerId: humanPlayerId,
            missionOrder: NavalMissionOrder(
              fleetId: fleet.id,
              mission: mission.name,
              targetProvinceId: targetId,
            ),
          ),
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

/// Menu selection for [showNavalMissionFlow].
sealed class NavalMissionMenuChoice {
  const NavalMissionMenuChoice();
}

final class NavalMissionMenuChoiceMission extends NavalMissionMenuChoice {
  const NavalMissionMenuChoiceMission(this.mission);
  final FleetMission mission;
}

final class NavalMissionMenuChoiceCancelPending extends NavalMissionMenuChoice {
  const NavalMissionMenuChoiceCancelPending();
}

/// Screen ids for naval mission dialog hosts (Refs #4213).
abstract final class NavalMissionDialogIds {
  static const menuDialog = UiScreenIds.navalMissionMenuDialog;
  static const targetDialog = UiScreenIds.navalMissionTargetDialog;
  static const fleetPickerDialog = UiScreenIds.navalMissionFleetPickerDialog;
}

String navalMissionMenuLabel(FleetMission mission) =>
    fleetMissionDisplayLabel(mission);
