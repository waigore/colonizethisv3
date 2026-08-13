// Naval mission assign + map fleet-marker routing (Refs #4213, #4343).
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
import 'move_fleet_dialog.dart';
import 'naval_mission_menu_dialog.dart';
import 'naval_mission_target_dialog.dart';

/// Map fleet-marker tap: pick fleet when stacked, then route to the legal action.
///
/// Home Fleet → tile-scoped [OpenNavalUnitsPanelEvent]; sea-going in port →
/// [MoveFleetDialog]; sea-going at sea → [showNavalMissionFlow] (Refs #4343).
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
}) async {
  if (fleetIds.isEmpty) return;

  final selectedFleetId = await _pickFleetId(
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
    bus.emit(
      OpenNavalUnitsPanelEvent(
        locationScopeKey: locationScopeKey,
        initialSelectedFleetId: fleet.id,
        tileScopeTileKey: tileScopeTileKey,
      ),
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
}) async {
  if (fleetIds.isEmpty) return;

  final selectedFleetId = await _pickFleetId(
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

/// Local `showDialog` for [MoveFleetDialog] (panel Move, marker in-port, Sail).
Future<bool?> showMoveFleetDialogForFleet({
  required BuildContext context,
  required Game game,
  required MapTopology topology,
  required String humanPlayerId,
  required Fleet fleet,
  required AppEventBus bus,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => MoveFleetDialog(
      game: game,
      topology: topology,
      humanPlayerId: humanPlayerId,
      fleet: fleet,
      bus: bus,
    ),
  );
}

Future<String?> _pickFleetId({
  required BuildContext context,
  required Game game,
  required String humanPlayerId,
  required List<String> fleetIds,
  String? preselectedFleetId,
}) async {
  if (fleetIds.length > 1) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => NavalMissionFleetPickerDialog(
        game: game,
        humanPlayerId: humanPlayerId,
        fleetIds: fleetIds,
        initialFleetId: preselectedFleetId,
      ),
    );
  }
  return fleetIds.first;
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

/// Opens [MoveFleetDialog] from `DLG31001` Sail / Move (Refs #4343).
final class NavalMissionMenuChoiceSail extends NavalMissionMenuChoice {
  const NavalMissionMenuChoiceSail();
}

/// Screen ids for naval mission dialog hosts (Refs #4213).
abstract final class NavalMissionDialogIds {
  static const menuDialog = UiScreenIds.navalMissionMenuDialog;
  static const targetDialog = UiScreenIds.navalMissionTargetDialog;
  static const fleetPickerDialog = UiScreenIds.navalMissionFleetPickerDialog;
}

String navalMissionMenuLabel(FleetMission mission) =>
    fleetMissionDisplayLabel(mission);

/// One-line player-facing effect summary for [mission] (Refs #4295).
String navalMissionEffectLine(AppLocalizations l10n, FleetMission mission) {
  return switch (mission) {
    FleetMission.patrol => l10n.naval_mission_effect_patrol,
    FleetMission.defend => l10n.naval_mission_effect_defend,
    FleetMission.blockade => l10n.naval_mission_effect_blockade,
    FleetMission.beachhead => l10n.naval_mission_effect_beachhead,
    FleetMission.none => '',
  };
}

/// Target-picker caption for Blockade / Beachhead (Refs #4295).
String? navalMissionTargetCaption(AppLocalizations l10n, FleetMission mission) {
  return switch (mission) {
    FleetMission.blockade => l10n.naval_mission_targetCaption_blockade,
    FleetMission.beachhead => l10n.naval_mission_targetCaption_beachhead,
    _ => null,
  };
}
