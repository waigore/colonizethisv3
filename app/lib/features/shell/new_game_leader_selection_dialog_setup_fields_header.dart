part of 'new_game_leader_selection_dialog.dart';

/// Header and seed field for [NewGameLeaderSelectionDialog] (Refs #3878).
mixin _NewGameLeaderSelectionDialogSetupFieldsHeader
    on State<NewGameLeaderSelectionDialog>, _NewGameLeaderSelectionDialogStateBase {
  Widget _buildHeader(AppLocalizations l10n, _LeaderDialogTextStyles styles) {
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

  Widget _buildSeedField(
    ThemeData theme,
    AppLocalizations l10n,
    _LeaderDialogTextStyles styles,
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
          controller: _seedController,
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
