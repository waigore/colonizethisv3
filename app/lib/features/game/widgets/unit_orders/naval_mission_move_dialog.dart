// Local Move Fleet dialog host for marker / Sail / panel Move.
// Refs #4343. SPEC/program/app-ui-wiring.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import 'move_fleet_dialog.dart';

/// Local `showDialog` for [MoveFleetDialog] (panel Move, marker in-port, Sail).
Future<bool?> showMoveFleetDialogForFleet({
  required BuildContext context,
  required Game game,
  required MapTopology topology,
  required String humanPlayerId,
  required Fleet fleet,
  required AppEventBus bus,
  PlayerView? playerView,
}) {
  final resolvedPlayerView =
      playerView ?? buildPlayerView(game, topology, humanPlayerId);
  return showDialog<bool>(
    context: context,
    builder: (ctx) => MoveFleetDialog(
      game: game,
      topology: topology,
      humanPlayerId: humanPlayerId,
      fleet: fleet,
      bus: bus,
      playerView: resolvedPlayerView,
    ),
  );
}
