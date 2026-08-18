import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:flutter/material.dart';

import '../../../../widgets/ct_dialog_shell.dart';
import '../../../../widgets/ct_nine_patch_button.dart';
import '../../../../widgets/ct_spacing.dart';
import 'research_slot_finish_estimate.dart';
import 'research_slot_preview.dart';
import 'research_slot_turn_preview_view_styles.dart';
import 'technology_slot_funding_toggles.dart';

/// Opens the research-funding breakdown dialog (Refs #4117 de-part).
void showResearchFundingBreakdownDialog({
  required BuildContext context,
  required ResearchSlotTurnPreview preview,
}) {
  showDialog<void>(
    context: context,
    barrierColor: EditorialMonoclePalette.dialogScrim,
    builder: (ctx) => ResearchFundingBreakdownDialog(preview: preview),
  );
}

/// Read-only research-funding breakdown modal. SPEC/ui/technology-panel.md
/// § Slot turn preview.
@visibleForTesting
class ResearchFundingBreakdownDialog extends StatelessWidget {
  const ResearchFundingBreakdownDialog({super.key, required this.preview});

  final ResearchSlotTurnPreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final theme = Theme.of(context);
    return CtDialogShell(
      maxWidth: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.technologyPanel_rpBreakdownTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: EditorialMonoclePalette.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: CtSpacing.m),
          _BreakdownMetrics(preview: preview, l10n: l10n),
          _BreakdownBlockedNotice(preview: preview, l10n: l10n, theme: theme),
          const SizedBox(height: CtSpacing.ml),
          CtNinePatchButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.common_close),
          ),
        ],
      ),
    );
  }
}

class _BreakdownMetrics extends StatelessWidget {
  const _BreakdownMetrics({required this.preview, required this.l10n});

  final ResearchSlotTurnPreview preview;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BreakdownRow(
          label: l10n.technologyPanel_rpBreakdownBaseLabel(
            fundingLevelLabel(l10n, preview.funding),
          ),
          value: l10n.technologyPanel_rpValue(preview.baseRpPerTurn),
        ),
        if (preview.hasIndustrialBonus)
          _BreakdownRow(
            label: l10n.technologyPanel_rpBreakdownIndustrialLabel,
            value: l10n.technologyPanel_rpValue(
              preview.industrialBonusRpPerTurn,
            ),
          ),
        if (preview.hasSpyInsight)
          _BreakdownRow(
            label: spyInsightBreakdownLabel(l10n, preview),
            value: l10n.technologyPanel_rpValue(preview.spyInsightRpPerTurn),
          ),
        _BreakdownRow(
          label: l10n.technologyPanel_rpBreakdownEffectiveLabel,
          value: l10n.technologyPanel_rpValue(preview.effectiveRpPerTurn),
          emphasised: true,
        ),
        _BreakdownRow(
          label: l10n.technologyPanel_rpBreakdownTreasuryLabel,
          value: l10n.technologyPanel_goldValue(preview.goldCostPerTurn),
        ),
        ..._finishRestatementRows(l10n),
      ],
    );
  }

  List<Widget> _finishRestatementRows(AppLocalizations l10n) {
    final estimate = researchFinishEstimate(preview);
    if (estimate == null) {
      return const <Widget>[];
    }
    final style = TextStyle(
      color: EditorialMonoclePalette.muted,
      fontSize: 11,
      fontStyle: FontStyle.italic,
    );
    return <Widget>[
      const SizedBox(height: 4),
      Text(
        l10n.technologyPanel_rpBreakdownRemaining(estimate.remainingRp),
        style: style,
      ),
      Text(
        l10n.technologyPanel_rpBreakdownTurns(estimate.turnsRemaining),
        style: style,
      ),
    ];
  }
}

/// Plain-language Spy insight breakdown label (Refs #4457).
@visibleForTesting
String spyInsightBreakdownLabel(
  AppLocalizations l10n,
  ResearchSlotTurnPreview preview,
) {
  final names = preview.spyInsightRivalNames;
  final percent = preview.spyInsightRivalCount * 15;
  if (names.length <= 1) {
    return l10n.technologyPanel_rpBreakdownSpyInsightOne(
      names.isEmpty ? '' : names.first,
    );
  }
  return l10n.technologyPanel_rpBreakdownSpyInsightMany(
    _joinCourtDisplayNames(names),
    percent,
  );
}

String _joinCourtDisplayNames(List<String> names) {
  if (names.length == 2) {
    return '${names[0]} and ${names[1]}';
  }
  final head = names.sublist(0, names.length - 1).join(', ');
  return '$head, and ${names.last}';
}

class _BreakdownBlockedNotice extends StatelessWidget {
  const _BreakdownBlockedNotice({
    required this.preview,
    required this.l10n,
    required this.theme,
  });

  final ResearchSlotTurnPreview preview;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (preview.sequentialBlocked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: CtSpacing.s),
          Text(
            l10n.technologyPanel_rpBreakdownSequentialBlocked,
            style: theme.textTheme.bodySmall?.copyWith(
              color: EditorialMonoclePalette.danger,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (preview.treasuryBeforeSlot != null)
            Text(
              l10n.technologyPanel_rpBreakdownResidualTreasury(
                preview.treasuryBeforeSlot!,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: EditorialMonoclePalette.muted,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      );
    }
    if (preview.debtBlocked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: CtSpacing.s),
          Text(
            l10n.technologyPanel_rpBreakdownDebtBlocked,
            style: theme.textTheme.bodySmall?.copyWith(
              color: EditorialMonoclePalette.danger,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.emphasised = false,
  });

  final String label;
  final String value;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final Color labelColor = emphasised
        ? EditorialMonoclePalette.fg
        : EditorialMonoclePalette.muted;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 11,
                fontWeight: emphasised ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: CtSpacing.m),
          Text(
            value,
            style: researchSlotTurnPreviewMonoStyle(
              emphasised
                  ? EditorialMonoclePalette.accentBright
                  : EditorialMonoclePalette.accentDim,
            ).copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
