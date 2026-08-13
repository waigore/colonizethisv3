// Overlay Move/Invade flow: optional army picker → MoveArmyDialog (Refs #4350).
// SPEC/ui/overlay-army-move-picker-dialog.md, SPEC/ui/move-army-dialog.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import 'overlay_army_move_picker_dialog.dart';
import 'show_move_army_dialog.dart';

/// Opens Move army dialog for [armyIds]; multi-army shows [OverlayArmyMovePickerDialog] first.
Future<void> showOverlayArmyMoveFlow({
  required BuildContext context,
  required Game game,
  required MapTopology topology,
  required String humanPlayerId,
  required Orders draftOrders,
  required AppEventBus bus,
  required List<String> armyIds,
  PlayerView? playerView,
  String? initialDestinationProvinceId,
  String? preselectedArmyId,
}) async {
  if (armyIds.isEmpty) return;

  var selectedArmyId = preselectedArmyId;
  if (armyIds.length > 1) {
    selectedArmyId = await showDialog<String>(
      context: context,
      builder: (ctx) => OverlayArmyMovePickerDialog(
        game: game,
        humanPlayerId: humanPlayerId,
        armyIds: armyIds,
        initialArmyId: preselectedArmyId,
      ),
    );
    if (selectedArmyId == null || !context.mounted) return;
  } else {
    selectedArmyId = armyIds.first;
  }

  Army? army;
  for (final a in game.worldState.armies) {
    if (a.id == selectedArmyId) {
      army = a;
      break;
    }
  }
  if (army == null || !context.mounted) return;

  await showMoveArmyDialog(
    context: context,
    army: army,
    game: game,
    humanPlayerId: humanPlayerId,
    bus: bus,
    topology: topology,
    draftOrders: draftOrders,
    playerView: playerView,
    initialDestinationProvinceId: initialDestinationProvinceId,
  );
}
