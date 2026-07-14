// Named save dialog. OpenDialogEvent id `save_game_name`.
// SPEC/ui/save-game-name-dialog.md.

import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app/features/shell/save_load/default_save_display_name.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/production_allocation_provider.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_gap.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'save_game_name_dialog_body.dart';

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
  ConsumerState<SaveGameNameDialog> createState() => _SaveGameNameDialogState();
}

class _SaveGameNameDialogState extends ConsumerState<SaveGameNameDialog> {
  late final TextEditingController _controller;
  String? _errorText;
  bool _awaitingOverwrite = false;
  String? _pendingSanitizedId;
  String? _pendingDisplayName;

  @override
  void initState() {
    super.initState();
    final game = ref.read(currentGameProvider);
    _controller = TextEditingController(
      text: game == null ? '' : defaultSaveDisplayName(game),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onCancel() => Navigator.of(context).pop();

  void _setFeedback({String? error, bool awaiting = false, String? id, String? name}) {
    setState(() {
      _errorText = error;
      _awaitingOverwrite = awaiting;
      _pendingSanitizedId = id;
      _pendingDisplayName = name;
    });
  }

  void _onSavePressed() {
    final typed = _controller.text;
    final sanitized = sanitizeGameId(typed);
    if (sanitized == null) {
      _setFeedback(error: appL10n(context).saveGameName_invalidName);
      return;
    }
    final service = ref.read(gameServiceProvider);
    if (service.listGameIds().contains(sanitized)) {
      _setFeedback(awaiting: true, id: sanitized, name: typed.trim());
      return;
    }
    if (!service.canCreateNewManualSave()) {
      _setFeedback(error: appL10n(context).saveGameName_atCapError);
      return;
    }
    _persist(sanitized, typed.trim());
  }

  void _onOverwriteConfirm() {
    final id = _pendingSanitizedId;
    final name = _pendingDisplayName;
    if (id != null && name != null) _persist(id, name);
  }

  void _onOverwriteCancel() => _setFeedback();

  @override
  Widget build(BuildContext context) {
    return CtDialogShell(
      maxWidth: 420,
      maxHeight: 360,
      padding: const EdgeInsets.all(CtSpacing.l),
      child: _dialogBody(appL10n(context)),
    );
  }
}
