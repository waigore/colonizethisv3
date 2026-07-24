import 'package:colonizethis_app/features/shell/save_load/default_save_display_name.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'save_game_name_dialog.dart';
import 'save_game_name_dialog_body.dart';
import 'save_game_name_dialog_state_base.dart';

/// Stateful implementation for [SaveGameNameDialog] (Refs #4117 de-part).
class SaveGameNameDialogState extends ConsumerState<SaveGameNameDialog>
    with SaveGameNameDialogStateBase, SaveGameNameDialogBody {
  @override
  void initState() {
    super.initState();
    final game = ref.read(currentGameProvider);
    controller = TextEditingController(
      text: game == null ? '' : defaultSaveDisplayName(game),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

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
