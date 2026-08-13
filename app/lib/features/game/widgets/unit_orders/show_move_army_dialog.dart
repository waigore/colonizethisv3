// Shared opener for MoveArmyDialog (panel + overlay). SPEC/ui/move-army-dialog.md.

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;
import 'package:flutter/material.dart';

import 'move_army_dialog.dart';

Future<void> showMoveArmyDialog({
  required BuildContext context,
  required Army army,
  required Game game,
  required String humanPlayerId,
  required AppEventBus bus,
  required MapTopology topology,
  required Orders draftOrders,
  PlayerView? playerView,
  String? initialDestinationProvinceId,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => MoveArmyDialog(
      army: army,
      game: game,
      humanPlayerId: humanPlayerId,
      bus: bus,
      topology: topology,
      draftOrders: draftOrders,
      playerView: playerView,
      initialDestinationProvinceId: initialDestinationProvinceId,
    ),
  );
}
