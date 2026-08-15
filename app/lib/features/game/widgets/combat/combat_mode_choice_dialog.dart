import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../../../widgets/ct_action_text_button.dart';
import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import 'combat_mode_choice_intel.dart';
import 'combat_mode_choice_intel_labels.dart';

/// Dialog for choosing combat mode (Auto-Resolve vs Quick Battle).
///
/// Open via `OpenDialogEvent('combat_mode_choice', params)` registered in
/// `app_event_handler_scope.dart`. SPEC/ui/combat-mode-choice-dialog.md.
/// Capital sieges force Quick Battle. Force/fort/Details: Refs #4438.
class CombatModeChoiceDialog extends StatefulWidget {
  const CombatModeChoiceDialog({
    super.key,
    required this.bus,
    required this.provinceName,
    required this.isCapitalSiege,
    this.landForceFeedingWarning,
    this.intel,
    this.detailsInitiallyOpen = false,
  });

  static const screenId = UiScreenIds.combatModeChoiceDialog;
  static const double _titleLetterSpacing = 0.05;

  final AppEventBus bus;
  final String provinceName;
  final bool isCapitalSiege;
  final String? landForceFeedingWarning;
  final CombatModeChoiceIntel? intel;
  final bool detailsInitiallyOpen;

  @override
  State<CombatModeChoiceDialog> createState() => _CombatModeChoiceDialogState();
}

class _CombatModeChoiceDialogState extends State<CombatModeChoiceDialog> {
  late bool _detailsOpen = widget.detailsInitiallyOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    return CtDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(theme, l10n),
          CtGap.m,
          ..._body(theme, l10n),
          CtGap.l,
          _actionRow(context, theme, l10n),
        ],
      ),
    );
  }

  Widget _title(ThemeData theme, AppLocalizations l10n) {
    final style = (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
      color: EditorialMonoclePalette.accent,
      letterSpacing: CombatModeChoiceDialog._titleLetterSpacing,
    );
    return Text(l10n.quickBattle_combatAt(widget.provinceName), style: style);
  }

  List<Widget> _body(ThemeData theme, AppLocalizations l10n) {
    final muted = (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
      color: EditorialMonoclePalette.muted,
    );
    final smallMuted = (theme.textTheme.bodySmall ?? const TextStyle())
        .copyWith(
          color: EditorialMonoclePalette.muted,
          fontStyle: FontStyle.italic,
        );
    final prompt = widget.isCapitalSiege
        ? l10n.quickBattle_capitalSiegeQuickBattleOnly
        : l10n.quickBattle_chooseCombatMode;
    final children = <Widget>[Text(prompt, style: muted)];
    final intel = widget.intel;
    if (intel != null) {
      for (final line in combatModeChoiceDefaultForceLines(l10n, intel)) {
        children.add(Text(line, style: muted));
      }
    }
    if (!widget.isCapitalSiege) {
      children.add(Text(l10n.quickBattle_autoResolveMeaning, style: muted));
    }
    children.add(Text(l10n.quickBattle_quickBattleMeaning, style: muted));
    final warning = widget.landForceFeedingWarning;
    if (warning != null && warning.isNotEmpty) {
      children.add(const SizedBox(height: 4));
      children.add(Text(warning, style: smallMuted));
    }
    if (intel != null) {
      children.add(CtGap.m);
      children.add(
        CtActionTextButton(
          onPressed: () => setState(() => _detailsOpen = !_detailsOpen),
          label: _detailsOpen
              ? l10n.combatMode_hideDetails
              : l10n.combatMode_details,
        ),
      );
      if (_detailsOpen) {
        for (final line in combatModeChoiceDetailTypeLines(l10n, intel)) {
          children.add(Text(line, style: muted));
        }
      }
    }
    return children;
  }

  Widget _actionRow(
    BuildContext context,
    ThemeData theme,
    AppLocalizations l10n,
  ) {
    final primaryLabelStyle = (theme.textTheme.titleSmall ?? const TextStyle())
        .copyWith(color: EditorialMonoclePalette.accent);
    final secondaryLabelStyle =
        (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
          color: EditorialMonoclePalette.muted,
        );
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      runSpacing: 8,
      children: [
        if (!widget.isCapitalSiege)
          CtNinePatchButton(
            onPressed: () => _onModeChosen(context, CombatMode.autoResolve),
            child: Text(
              l10n.quickBattle_autoResolve,
              style: secondaryLabelStyle,
            ),
          ),
        CtNinePatchButton(
          onPressed: () => _onModeChosen(context, CombatMode.quickBattle),
          child: Text(l10n.quickBattle_quickBattle, style: primaryLabelStyle),
        ),
      ],
    );
  }

  void _onModeChosen(BuildContext context, CombatMode mode) {
    widget.bus.emit(CombatModeChosenEvent(mode));
    Navigator.of(context).pop();
  }
}
