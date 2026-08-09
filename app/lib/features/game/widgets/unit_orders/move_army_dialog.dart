// Move army dialog. SPEC/ui/move-army-dialog.md, SPEC/program/app-ui-wiring.md.

import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show ArmyMovePickerDestination, IncrementalCandidateValidator;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import '../../../../config/ui_screen_ids.dart';
import 'move_army_dialog_state.dart';

String moveArmyFactionGroupHeaderLabel(
  Game game,
  ArmyMovePickerDestination entry,
  AppLocalizations l10n,
) {
  if (entry.isPlayerOwned) return l10n.moveArmy_groupYourProvinces;
  if (entry.ownerFactionId == '__unowned__') return l10n.moveArmy_groupUnowned;
  final gp = game.playerById(entry.ownerFactionId);
  if (gp != null) return gp.displayName;
  for (final m in game.minorNations) {
    if (m.id == entry.ownerFactionId) {
      return m.displayName ?? m.id;
    }
  }
  for (final t in game.tribes) {
    if (t.id == entry.ownerFactionId) {
      return t.displayName ?? t.id;
    }
  }
  return entry.ownerFactionId;
}

class MoveArmyDialog extends StatefulWidget {
  const MoveArmyDialog({
    super.key,
    required this.army,
    required this.game,
    required this.humanPlayerId,
    required this.bus,
    required this.topology,
    required this.draftOrders,
    this.playerView,
  });

  /// SPEC/ui/move-army-dialog.md — [UiScreenIds.moveArmyDialog].
  static const screenId = UiScreenIds.moveArmyDialog;

  final Army army;
  final Game game;
  final String humanPlayerId;
  final AppEventBus bus;
  final MapTopology topology;
  final Orders draftOrders;

  /// When supplied, destination probing reuses this [PlayerView] and a single
  /// per-dialog [IncrementalCandidateValidator] instead of rebuilding them on
  /// every picker call (Refs #2394, SPEC/program/order-suggestions.md).
  final PlayerView? playerView;

  @override
  State<MoveArmyDialog> createState() => MoveArmyDialogState();
}
