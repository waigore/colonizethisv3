// Split Home Army then open DLG20001 for the new field army (Refs #4407).
// SPEC/ui/military-units-army-management.md, SPEC/ui/move-army-dialog.md.

import 'dart:async';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import 'show_move_army_dialog.dart';
import 'split_army_dialog.dart';

/// New non-Home army created by a split, read from post-split [after].
Army? newFieldArmyAfterSplit({required Game before, required Game after}) {
  final beforeIds = <String>{
    for (final army in before.worldState.armies) army.id,
  };
  for (final army in after.worldState.armies) {
    if (!beforeIds.contains(army.id) && !army.isHomeArmy) {
      return army;
    }
  }
  return null;
}

/// Opens Split Army for the Home Army, then `DLG20001` for the new field army.
Future<void> showHomeArmyDetachThenMoveFlow({
  required BuildContext context,
  required Game game,
  required MapTopology topology,
  required String humanPlayerId,
  required Orders draftOrders,
  required AppEventBus bus,
  PlayerView? playerView,
  String? initialDestinationProvinceId,
}) async {
  Army? home;
  for (final army in game.worldState.armies) {
    if (army.ownerId == humanPlayerId && army.isHomeArmy) {
      home = army;
      break;
    }
  }
  if (home == null || home.regimentUnitIds.isEmpty || !context.mounted) {
    return;
  }
  final homeArmy = home;

  final pending = Completer<LandArmiesUpdatedEvent>();
  final sub = bus.on<LandArmiesUpdatedEvent>().listen((event) {
    if (!pending.isCompleted) pending.complete(event);
  });
  try {
    final l10n = appL10n(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => SplitArmyDialog(
        army: homeArmy,
        game: game,
        humanPlayerId: humanPlayerId,
        bus: bus,
        isHomeArmy: true,
        title: l10n.splitArmy_detachTitle,
        confirmLabel: l10n.splitArmy_detachConfirm,
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final updated = await pending.future;
    final created = newFieldArmyAfterSplit(before: game, after: updated.game);
    if (created == null || !context.mounted) return;

    await showMoveArmyDialog(
      context: context,
      army: created,
      game: updated.game,
      humanPlayerId: humanPlayerId,
      bus: bus,
      topology: topology,
      draftOrders: draftOrders,
      playerView: playerView,
      initialDestinationProvinceId: initialDestinationProvinceId,
    );
  } finally {
    await sub.cancel();
  }
}
