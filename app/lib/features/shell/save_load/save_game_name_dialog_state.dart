// Stateful host for [SaveGameNameDialog] (de-parted wave-9 cluster, Refs #4117).

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';

import 'save_game_name_dialog_body.dart';
import 'save_game_name_dialog_state_base.dart';
import 'save_game_name_dialog_widget.dart';

class SaveGameNameDialogState extends ConsumerState<SaveGameNameDialog>
    with SaveGameNameDialogStateBase, SaveGameNameDialogBody {
  @override
  Widget build(BuildContext context) {
    return CtDialogShell(
      maxWidth: 420,
      maxHeight: 360,
      padding: const EdgeInsets.all(CtSpacing.l),
      child: dialogBody(appL10n(context)),
    );
  }
}
