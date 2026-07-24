import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_gap.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';

import 'save_game_name_dialog.dart';
import 'save_game_name_dialog_state_base.dart';

/// Dialog body layout for [SaveGameNameDialog] (Refs #4117 de-part).
mixin SaveGameNameDialogBody on ConsumerState<SaveGameNameDialog>, SaveGameNameDialogStateBase {
  Widget actionRow({
    required Key cancelKey,
    required Key confirmKey,
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
    required String cancelLabel,
    required String confirmLabel,
  }) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CtNinePatchButton(
            key: cancelKey,
            onPressed: onCancel,
            child: Text(cancelLabel),
          ),
          const SizedBox(width: CtSpacing.m),
          CtNinePatchButton(
            key: confirmKey,
            onPressed: onConfirm,
            child: Text(confirmLabel),
          ),
        ],
      );

  Widget dialogBody(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final titleStyle = (theme.textTheme.titleMedium ?? const TextStyle())
        .copyWith(
          color: EditorialMonoclePalette.accent,
          fontWeight: FontWeight.w700,
        );
    final bodyStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(color: EditorialMonoclePalette.fg);
    final idleBorder = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: EditorialMonoclePalette.border),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.saveGameName_title, style: titleStyle),
        CtGap.ml,
        TextField(
          key: SaveGameNameDialog.nameFieldKey,
          controller: controller,
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
            if (errorText != null || awaitingOverwrite) setFeedback();
          },
        ),
        if (errorText != null) ...[
          CtGap.m,
          Text(
            errorText!,
            key: SaveGameNameDialog.errorTextKey,
            style: bodyStyle.copyWith(color: EditorialMonoclePalette.danger),
          ),
        ],
        if (awaitingOverwrite) ...[
          CtGap.m,
          Text(
            l10n.saveGameName_overwriteConfirm,
            key: SaveGameNameDialog.overwriteConfirmKey,
            style: bodyStyle,
          ),
          CtGap.m,
          actionRow(
            cancelKey: SaveGameNameDialog.overwriteCancelButtonKey,
            confirmKey: SaveGameNameDialog.overwriteConfirmButtonKey,
            onCancel: onOverwriteCancel,
            onConfirm: onOverwriteConfirm,
            cancelLabel: l10n.common_cancel,
            confirmLabel: l10n.saveGameName_overwrite,
          ),
        ] else ...[
          CtGap.l,
          actionRow(
            cancelKey: SaveGameNameDialog.cancelButtonKey,
            confirmKey: SaveGameNameDialog.saveButtonKey,
            onCancel: onCancel,
            onConfirm: onSavePressed,
            cancelLabel: l10n.common_cancel,
            confirmLabel: l10n.saveGameName_save,
          ),
        ],
      ],
    );
  }
}
