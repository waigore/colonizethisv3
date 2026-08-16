// Split Home Fleet then open DLG30001 for the new sea-going fleet (Refs #4448).
// SPEC/ui/naval-units-fleet-management.md, SPEC/ui/move-fleet-dialog.md.

import 'dart:async';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import 'naval_mission_flow.dart';
import 'split_fleet_dialog.dart';

/// New non-Home fleet created by a split, read from post-split [after].
Fleet? newSeaGoingFleetAfterSplit({required Game before, required Game after}) {
  final beforeIds = <String>{
    for (final fleet in before.worldState.fleets) fleet.id,
  };
  for (final fleet in after.worldState.fleets) {
    if (!beforeIds.contains(fleet.id) &&
        fleet.id != homeFleetIdFor(fleet.ownerId)) {
      return fleet;
    }
  }
  return null;
}

/// Opens Split Fleet for the Home Fleet, then `DLG30001` for the new fleet.
Future<void> showHomeFleetDetachThenSailFlow({
  required BuildContext context,
  required Game game,
  required MapTopology topology,
  required String humanPlayerId,
  required AppEventBus bus,
  int overseasCargoUsed = 0,
  bool isCargoUsedReliable = true,
  bool cargoNotDefined = false,
}) async {
  final home = game.fleetById(homeFleetIdFor(humanPlayerId));
  if (home == null ||
      home.ownerId != humanPlayerId ||
      home.ships.isEmpty ||
      !context.mounted) {
    return;
  }

  final pending = Completer<NavalFleetsUpdatedEvent>();
  final sub = bus.on<NavalFleetsUpdatedEvent>().listen((event) {
    if (!pending.isCompleted) pending.complete(event);
  });
  try {
    final l10n = appL10n(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => SplitFleetDialog(
        originalFleet: home,
        game: game,
        humanPlayerId: humanPlayerId,
        bus: bus,
        isHomeFleet: true,
        title: l10n.splitFleet_detachTitle,
        confirmLabel: l10n.splitFleet_detachConfirm,
        overseasCargoUsed: overseasCargoUsed,
        isCargoUsedReliable: isCargoUsedReliable,
        cargoNotDefined: cargoNotDefined,
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final updated = await pending.future;
    final created = newSeaGoingFleetAfterSplit(
      before: game,
      after: updated.game,
    );
    if (created == null || !context.mounted) return;

    await showMoveFleetDialogForFleet(
      context: context,
      game: updated.game,
      topology: topology,
      humanPlayerId: humanPlayerId,
      fleet: created,
      bus: bus,
    );
  } finally {
    await sub.cancel();
  }
}
