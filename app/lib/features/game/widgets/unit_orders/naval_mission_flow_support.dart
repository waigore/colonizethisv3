// Fleet picker + Blockade/Beachhead confirm helpers for naval mission flow.
// Refs #4213, #4413. SPEC/program/app-ui-wiring.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import 'naval_mission_menu_dialog.dart';
import 'naval_mission_target_dialog.dart';

Future<String?> pickNavalMissionFleetId({
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

Future<void> confirmNavalTargetedMission({
  required BuildContext context,
  required Game game,
  required String humanPlayerId,
  required AppEventBus bus,
  required Fleet fleet,
  required FleetMission mission,
  required List<String> targets,
  required PlayerView playerView,
  String? initialTargetProvinceId,
}) async {
  final targetId = await showDialog<String>(
    context: context,
    builder: (ctx) => NavalMissionTargetDialog(
      game: game,
      mission: mission,
      fleet: fleet,
      targetProvinceIds: targets,
      humanPlayerId: humanPlayerId,
      playerView: playerView,
      initialTargetProvinceId: initialTargetProvinceId,
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
}
