import 'package:flutter/material.dart';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';

import 'package:colonizethis_app/widgets/ct_spacing.dart';

import 'new_game_leader_selection_dialog.dart';
import 'new_game_leader_selection_dialog_layout.dart';
import 'new_game_leader_selection_dialog_state_base.dart';

/// Header and seed field for [NewGameLeaderSelectionDialog] (Refs #4117).
mixin NewGameLeaderSelectionDialogSetupFieldsHeader
    on
        State<NewGameLeaderSelectionDialog>,
        NewGameLeaderSelectionDialogStateBase {
  Widget buildHeader(
    AppLocalizations l10n,
    NewGameLeaderDialogTextStyles styles,
  ) {
    // Mockup header order (DLG10001 `.dialog-body`): centered title, centered
    // italic intro, then the brass divider beneath both.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          l10n.shell_leaderDialog_title,
          key: const ValueKey<String>('leaderSelectionDialogTitle'),
          style: styles.title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: CtSpacing.xs),
        Text(
          l10n.shell_leaderDialog_intro,
          key: const ValueKey<String>('leaderSelectionDialogIntro'),
          style: styles.intro,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: CtSpacing.ml),
        const CtBrassDivider(
          key: ValueKey<String>('leaderSelectionDialogBrassDivider'),
        ),
      ],
    );
  }

  Widget buildSeedField(
    ThemeData theme,
    AppLocalizations l10n,
    NewGameLeaderDialogTextStyles styles,
  ) {
    final OutlineInputBorder idleBorder = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: EditorialMonoclePalette.border),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.shell_leaderDialog_seedLabel, style: styles.fieldLabel),
        const SizedBox(height: CtSpacing.m / 2),
        TextField(
          controller: seedController,
          keyboardType: TextInputType.number,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: EditorialMonoclePalette.fg,
          ),
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
        ),
        const SizedBox(height: CtSpacing.s),
        Text(l10n.shell_leaderDialog_seedHelper, style: styles.helper),
      ],
    );
  }
}
