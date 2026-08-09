// Named save dialog. OpenDialogEvent id `save_game_name`.
// SPEC/ui/save-game-name-dialog.md.

import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'save_game_name_dialog_state.dart';

export 'save_game_name_dialog_state.dart' show SaveGameNameDialogState;

/// Prompts for a save display name, sanitizes to Hive id, confirms overwrite.
class SaveGameNameDialog extends ConsumerStatefulWidget {
  const SaveGameNameDialog({super.key});

  /// SPEC/ui/save-game-name-dialog.md — [UiScreenIds.saveGameNameDialog].
  static const screenId = UiScreenIds.saveGameNameDialog;
  static const Key nameFieldKey = ValueKey('saveGameNameDialog.nameField');
  static const Key cancelButtonKey = ValueKey('saveGameNameDialog.cancelButton');
  static const Key saveButtonKey = ValueKey('saveGameNameDialog.saveButton');
  static const Key errorTextKey = ValueKey('saveGameNameDialog.errorText');
  static const Key overwriteConfirmKey =
      ValueKey('saveGameNameDialog.overwriteConfirm');
  static const Key overwriteCancelButtonKey =
      ValueKey('saveGameNameDialog.overwriteCancel');
  static const Key overwriteConfirmButtonKey =
      ValueKey('saveGameNameDialog.overwriteConfirmButton');

  @override
  ConsumerState<SaveGameNameDialog> createState() => SaveGameNameDialogState();
}
