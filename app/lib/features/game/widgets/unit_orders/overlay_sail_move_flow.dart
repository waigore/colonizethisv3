// Overlay Sail / Move: optional DLG31003 → DLG30001 (Refs #4735).
// Skips DLG31001 and DLG31004. SPEC/ui/province-sea-zone-detail-overlay.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;
import 'package:flutter/material.dart';

import 'naval_mission_flow_support.dart';
import 'naval_mission_move_dialog.dart';

/// Opens Move fleet for [fleetIds]; multi-fleet shows [NavalMissionFleetPickerDialog] first.
Future<void> showOverlaySailMoveFlow({
  required BuildContext context,
  required Game game,
  required MapTopology topology,
  required String humanPlayerId,
  required AppEventBus bus,
  required List<String> fleetIds,
  PlayerView? playerView,
}) async {
  if (fleetIds.isEmpty) return;

  final selectedId = await pickNavalMissionFleetId(
    context: context,
    game: game,
    humanPlayerId: humanPlayerId,
    fleetIds: fleetIds,
  );
  if (selectedId == null || !context.mounted) return;

  Fleet? fleet;
  for (final f in game.worldState.fleets) {
    if (f.id == selectedId) {
      fleet = f;
      break;
    }
  }
  if (fleet == null || !context.mounted) return;

  await showMoveFleetDialogForFleet(
    context: context,
    game: game,
    topology: topology,
    humanPlayerId: humanPlayerId,
    fleet: fleet,
    bus: bus,
    playerView: playerView,
  );
}
