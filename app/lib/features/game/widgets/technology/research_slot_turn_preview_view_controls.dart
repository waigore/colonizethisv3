part of 'research_slot_turn_preview_view.dart';

/// Green `+N RP` anticipated-delta chip that opens the breakdown dialog.
class _RpDeltaControl extends StatelessWidget {
  const _RpDeltaControl({super.key, required this.preview});

  final ResearchSlotTurnPreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    return InkWell(
      onTap: () => showResearchFundingBreakdownDialog(
        context: context,
        preview: preview,
      ),
      child: Text(
        l10n.technologyPanel_rpDeltaPreview(preview.anticipatedRpPerTurn),
        style: _monoStyle(EditorialMonoclePalette.success),
      ),
    );
  }
}

/// Treasury (gold) per-turn cost row with a signed delta. When the slot is
/// debt-blocked the per-turn cost is shown greyed with a zero delta (no spend
/// will occur). SPEC/ui/technology-panel.md § Slot turn preview.
class _GoldPreviewRow extends StatelessWidget {
  const _GoldPreviewRow({super.key, required this.preview});

  final ResearchSlotTurnPreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    if (preview.isNoneFunding) {
      return const SizedBox.shrink();
    }
    final bool spends = preview.goldSpentThisTurn > 0;
    // Spending gold is a negative treasury delta (danger colour per
    // CtResourceCell rules); debt-blocked shows the cost greyed with no spend.
    final Color color = spends
        ? (CtResourceCell.deltaColor(-preview.goldSpentThisTurn) ??
              EditorialMonoclePalette.muted)
        : EditorialMonoclePalette.muted;
    final String label = spends
        ? l10n.technologyPanel_goldSpendPerTurn(preview.goldCostPerTurn)
        : l10n.technologyPanel_goldNoSpendPerTurn(preview.goldCostPerTurn);
    return Row(
      children: [
        StrictAssetIcon(
          assetPath: _kTreasuryCoinAsset,
          width: 14,
          height: 14,
        ),
        const SizedBox(width: 5),
        Text(label, style: _monoStyle(color)),
      ],
    );
  }
}
