part of 'research_slot_turn_preview_view.dart';

/// Opens the research-funding breakdown dialog explaining the anticipated RP
/// (base funding RP, the +20% industrial bonus when applicable, the effective
/// total, the treasury cost, and a debt-block note when the spend is blocked).
///
/// SPEC/ui/technology-panel.md § Slot turn preview.
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
          _BreakdownRow(
            label: l10n.technologyPanel_rpBreakdownEffectiveLabel,
            value: l10n.technologyPanel_rpValue(preview.effectiveRpPerTurn),
            emphasised: true,
          ),
          _BreakdownRow(
            label: l10n.technologyPanel_rpBreakdownTreasuryLabel,
            value: l10n.technologyPanel_goldValue(preview.goldCostPerTurn),
          ),
          if (preview.debtBlocked) ...[
            const SizedBox(height: CtSpacing.s),
            Text(
              l10n.technologyPanel_rpBreakdownDebtBlocked,
              style: theme.textTheme.bodySmall?.copyWith(
                color: EditorialMonoclePalette.danger,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
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
            style: _monoStyle(
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
