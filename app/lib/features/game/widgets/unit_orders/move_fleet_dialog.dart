// Move fleet dialog. SPEC/ui/move-fleet-dialog.md, SPEC/program/app-ui-wiring.md.
//
// De-parted wave-9 cluster (Refs #4117).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../config/ui_screen_ids.dart';
import 'move_fleet_dialog_state.dart';

class MoveFleetDialog extends StatefulWidget {
  const MoveFleetDialog({
    super.key,
    required this.game,
    required this.topology,
    required this.humanPlayerId,
    required this.fleet,
    required this.bus,
  });

  /// SPEC/ui/move-fleet-dialog.md — [UiScreenIds.moveFleetDialog].
  static const screenId = UiScreenIds.moveFleetDialog;

  final Game game;
  final MapTopology topology;
  final String humanPlayerId;
  final Fleet fleet;
  final AppEventBus bus;

  @override
  State<MoveFleetDialog> createState() => MoveFleetDialogState();
}
