// Shared base for the train-at-capital dialogs (civilian, military, naval).
// SPEC/ui/train-civilians-dialog.md, SPEC/ui/train-military-dialog.md,
// SPEC/ui/train-naval-dialog.md, SPEC/ui/components/train-dialog-chrome.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_spacing.dart';
import 'train_dialog_chrome.dart';
import 'train_unit_dialog_helper.dart';

part 'train_dialog_base_state.dart';

/// Common widget contract for the train-at-capital dialogs. Each concrete
/// dialog (civilian / military / naval) carries the same inputs: the active
/// [game], the [humanPlayerId] whose capital the units train at, the
/// [currentOrders] used to seed stepper counts, and the [bus] that the
/// committed [BuildUnitOrder] list is emitted on when the dialog closes.
abstract class TrainDialogBase extends StatefulWidget {
  const TrainDialogBase({
    super.key,
    required this.game,
    required this.humanPlayerId,
    required this.currentOrders,
    required this.bus,
  });

  final Game game;
  final String humanPlayerId;
  final Orders currentOrders;
  final AppEventBus bus;
}
