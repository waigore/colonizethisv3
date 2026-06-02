import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/editorial_monocle_palette.dart';
import '../../../config/ui_screen_ids.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_dialog_shell.dart';
import '../../../widgets/ct_nine_patch_button.dart';

/// Dialog for choosing combat mode (Auto-Resolve vs Quick Battle).
///
/// Open via `OpenDialogEvent('combat_mode_choice', params)` registered in
/// `app_event_handler_scope.dart`. SPEC/program/quick-battle-resolution.
/// Capital sieges force Quick Battle.
///
/// Dark editorial-monocle chrome (Refs #2869 S2 / R1–R5,
/// `SPEC/ui/combat-mode-choice-dialog.md` § Dark-theme treatment):
/// title resolved to `--accent` with `0.05` letter-spacing on the display
/// font, body text resolved to `--muted`, Quick Battle's label text resolved
/// to `--accent` (primary), Auto-Resolve's label text resolved to `--muted`
/// (secondary). All colors source from [EditorialMonoclePalette]; no hex
/// literals.
class CombatModeChoiceDialog extends StatelessWidget {
  const CombatModeChoiceDialog({
    super.key,
    required this.bus,
    required this.provinceName,
    required this.isCapitalSiege,
  });

  static const screenId = UiScreenIds.combatModeChoiceDialog;

  /// Letter-spacing applied to the dialog title in the dark editorial-monocle
  /// theme. Matches the `0.05` value used by `CtTopBar._titleStyle`.
  static const double _titleLetterSpacing = 0.05;

  final AppEventBus bus;
  final String provinceName;
  final bool isCapitalSiege;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    return CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(theme, l10n),
          const SizedBox(height: 8),
          _buildBody(theme, l10n),
          const SizedBox(height: 16),
          _buildActionRow(context, theme, l10n),
        ],
      ),
    );
  }

  Widget _buildTitle(ThemeData theme, AppLocalizations l10n) {
    final style = (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
      color: EditorialMonoclePalette.accent,
      letterSpacing: _titleLetterSpacing,
    );
    return Text(l10n.quickBattle_combatAt(provinceName), style: style);
  }

  Widget _buildBody(ThemeData theme, AppLocalizations l10n) {
    final style = (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: EditorialMonoclePalette.muted,
    );
    final text = isCapitalSiege
        ? l10n.quickBattle_capitalSiegeQuickBattleOnly
        : l10n.quickBattle_chooseCombatMode;
    return Text(text, style: style);
  }

  Widget _buildActionRow(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final primaryLabelStyle = (theme.textTheme.titleSmall ?? const TextStyle())
        .copyWith(color: EditorialMonoclePalette.accent);
    final secondaryLabelStyle =
        (theme.textTheme.titleSmall ?? const TextStyle())
            .copyWith(color: EditorialMonoclePalette.muted);
    // Wrap mirrors CMPT10001 `.actions { flex-wrap: wrap }` so both buttons
    // stay within the CtDialogShell content column at kMinViewportWidth.
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [
        if (!isCapitalSiege)
          CtNinePatchButton(
            onPressed: () => _onModeChosen(context, CombatMode.autoResolve),
            child: Text(
              l10n.quickBattle_autoResolve,
              style: secondaryLabelStyle,
            ),
          ),
        CtNinePatchButton(
          onPressed: () => _onModeChosen(context, CombatMode.quickBattle),
          child: Text(
            l10n.quickBattle_quickBattle,
            style: primaryLabelStyle,
          ),
        ),
      ],
    );
  }

  void _onModeChosen(BuildContext context, CombatMode mode) {
    bus.emit(CombatModeChosenEvent(mode));
    Navigator.of(context).pop();
  }
}
