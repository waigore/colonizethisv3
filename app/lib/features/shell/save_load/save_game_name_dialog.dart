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

/// Prompts for a save display name, sanitizes to Hive id, confirms overwrite.
class SaveGameNameDialog extends ConsumerStatefulWidget {
  const SaveGameNameDialog({super.key});

  /// SPEC/ui/save-game-name-dialog.md — [UiScreenIds.saveGameNameDialog].
  static const screenId = UiScreenIds.saveGameNameDialog;

  static const Key nameFieldKey = ValueKey<String>('saveGameNameDialog.nameField');
  static const Key cancelButtonKey = ValueKey<String>(
    'saveGameNameDialog.cancelButton',
  );
  static const Key saveButtonKey = ValueKey<String>(
    'saveGameNameDialog.saveButton',
  );
  static const Key errorTextKey = ValueKey<String>(
    'saveGameNameDialog.errorText',
  );
  static const Key overwriteConfirmKey = ValueKey<String>(
    'saveGameNameDialog.overwriteConfirm',
  );
  static const Key overwriteCancelButtonKey = ValueKey<String>(
    'saveGameNameDialog.overwriteCancel',
  );
  static const Key overwriteConfirmButtonKey = ValueKey<String>(
    'saveGameNameDialog.overwriteConfirmButton',
  );

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

  void _onCancel() {
    Navigator.of(context).pop();
  }

  void _onSavePressed() {
    final typed = _controller.text;
    final sanitized = sanitizeGameId(typed);
    if (sanitized == null) {
      setState(() {
        _errorText = appL10n(context).saveGameName_invalidName;
        _awaitingOverwrite = false;
        _pendingSanitizedId = null;
        _pendingDisplayName = null;
      });
      return;
    }
    final service = ref.read(gameServiceProvider);
    final existing = service.listGameIds();
    if (existing.contains(sanitized)) {
      setState(() {
        _errorText = null;
        _awaitingOverwrite = true;
        _pendingSanitizedId = sanitized;
        _pendingDisplayName = typed.trim();
      });
      return;
    }
    _persist(sanitized, typed.trim());
  }

  void _onOverwriteConfirm() {
    final id = _pendingSanitizedId;
    final name = _pendingDisplayName;
    if (id == null || name == null) {
      return;
    }
    _persist(id, name);
  }

  void _onOverwriteCancel() {
    setState(() {
      _awaitingOverwrite = false;
      _pendingSanitizedId = null;
      _pendingDisplayName = null;
    });
  }

  void _persist(String saveGameId, String displayName) {
    final game = ref.read(currentGameProvider);
    if (game == null) {
      return;
    }
    final service = ref.read(gameServiceProvider);
    final orders = ref.read(currentOrdersProvider);
    final desired = ref.read(productionDesiredOutputProvider);
    service.saveGameSession(
      sessionGame: game,
      saveGameId: saveGameId,
      draftOrders: orders,
      productionDesiredOutputByRecipe: desired,
      displayName: displayName,
    );
    ref.read(appEventBusProvider).emit(
      ShowSnackBarEvent(message: appL10n(context).saveGameName_gameSaved),
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    final titleStyle = (theme.textTheme.titleMedium ?? const TextStyle())
        .copyWith(
          color: EditorialMonoclePalette.accent,
          fontWeight: FontWeight.w700,
        );
    final bodyStyle = (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: EditorialMonoclePalette.fg,
    );
    final errorStyle = bodyStyle.copyWith(color: EditorialMonoclePalette.danger);
    final idleBorder = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: EditorialMonoclePalette.border),
    );

    return CtDialogShell(
      maxWidth: 420,
      maxHeight: 360,
      padding: const EdgeInsets.all(CtSpacing.l),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.saveGameName_title, style: titleStyle),
          CtGap.ml,
          TextField(
            key: SaveGameNameDialog.nameFieldKey,
            controller: _controller,
            style: bodyStyle,
            decoration: InputDecoration(
              isDense: true,
              border: idleBorder,
              enabledBorder: idleBorder,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(
                  color: EditorialMonoclePalette.accent,
                  width: 2,
                ),
              ),
            ),
            onChanged: (_) {
              if (_errorText != null || _awaitingOverwrite) {
                setState(() {
                  _errorText = null;
                  _awaitingOverwrite = false;
                  _pendingSanitizedId = null;
                  _pendingDisplayName = null;
                });
              }
            },
          ),
          if (_errorText != null) ...[
            CtGap.m,
            Text(
              _errorText!,
              key: SaveGameNameDialog.errorTextKey,
              style: errorStyle,
            ),
          ],
          if (_awaitingOverwrite) ...[
            CtGap.m,
            Text(
              l10n.saveGameName_overwriteConfirm,
              key: SaveGameNameDialog.overwriteConfirmKey,
              style: bodyStyle,
            ),
            CtGap.m,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CtNinePatchButton(
                  key: SaveGameNameDialog.overwriteCancelButtonKey,
                  onPressed: _onOverwriteCancel,
                  child: Text(l10n.common_cancel),
                ),
                const SizedBox(width: CtSpacing.m),
                CtNinePatchButton(
                  key: SaveGameNameDialog.overwriteConfirmButtonKey,
                  onPressed: _onOverwriteConfirm,
                  child: Text(l10n.saveGameName_overwrite),
                ),
              ],
            ),
          ] else ...[
            CtGap.l,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CtNinePatchButton(
                  key: SaveGameNameDialog.cancelButtonKey,
                  onPressed: _onCancel,
                  child: Text(l10n.common_cancel),
                ),
                const SizedBox(width: CtSpacing.m),
                CtNinePatchButton(
                  key: SaveGameNameDialog.saveButtonKey,
                  onPressed: _onSavePressed,
                  child: Text(l10n.saveGameName_save),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
