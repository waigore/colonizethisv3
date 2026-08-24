import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../../providers/home_fleet_cargo_provider.dart';
import 'naval_mission_fleet_picker_dialog.dart';
import 'transfer_to_home_fleet_dialog.dart';

/// Opens DLG31003 when several sources qualify, then DLG40001 (Refs #4625).
Future<void> showOverlayTransferToHomeFleetFlow({
  required BuildContext context,
  required Game game,
  required String humanPlayerId,
  required AppEventBus bus,
  required Fleet homeFleet,
  required List<Fleet> sourceFleets,
  required HomeFleetCargoSummary cargo,
}) async {
  if (sourceFleets.isEmpty) return;
  var source = sourceFleets.first;
  if (sourceFleets.length > 1) {
    final ids = [for (final f in sourceFleets) f.id];
    final chosen = await showDialog<String>(
      context: context,
      builder: (_) => NavalMissionFleetPickerDialog(
        game: game,
        humanPlayerId: humanPlayerId,
        fleetIds: ids,
      ),
    );
    if (chosen == null || !context.mounted) return;
    Fleet? picked;
    for (final fleet in sourceFleets) {
      if (fleet.id == chosen) {
        picked = fleet;
        break;
      }
    }
    if (picked == null) return;
    source = picked;
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (_) => TransferToHomeFleetDialog(
      sourceFleet: source,
      homeFleet: homeFleet,
      game: game,
      humanPlayerId: humanPlayerId,
      bus: bus,
      overseasCargoUsed: cargo.used,
      isCargoUsedReliable: cargo.isCargoUsedReliable,
      cargoNotDefined: cargo.notDefined,
    ),
  );
}
