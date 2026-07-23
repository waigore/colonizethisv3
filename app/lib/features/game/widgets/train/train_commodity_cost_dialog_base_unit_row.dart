part of 'train_commodity_cost_dialog_base.dart';

/// A single commodity-cost trainable unit row (name over a cost wrap, with the
/// shared [TrainDialogStepper] on the right) shared by the military and naval
/// train dialogs.
class _CommodityCostUnitRow extends StatelessWidget {
  const _CommodityCostUnitRow({
    required this.displayName,
    required this.buildTreasuryCost,
    required this.buildInputs,
    required this.count,
    required this.isLocked,
    required this.techRequiredLabel,
    required this.canIncrement,
    required this.canDecrement,
    required this.treasuryInsufficient,
    required this.peasantInsufficient,
    required this.insufficientCommodityIds,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String displayName;
  final int buildTreasuryCost;
  final Map<String, int> buildInputs;
  final int count;
  final bool isLocked;
  final String techRequiredLabel;
  final bool canIncrement;
  final bool canDecrement;

  /// Whether remaining treasury cannot cover one more of this unit.
  final bool treasuryInsufficient;

  /// Whether remaining peasants cannot cover one more of this unit.
  final bool peasantInsufficient;

  /// Commodity ids whose remaining stockpile cannot cover one more of this
  /// unit (each rendered in the danger colour).
  final Set<String> insufficientCommodityIds;

  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = appL10n(context);
    return Opacity(
      opacity: isLocked ? kTrainDialogLockedOpacity : 1.0,
      child: TrainDialogUnitRowSurface(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _buildInfo(theme, l10n)),
            CtGap.wm,
            TrainDialogStepper(
              count: count,
              isLocked: isLocked,
              canIncrement: canIncrement,
              canDecrement: canDecrement,
              onIncrement: onIncrement,
              onDecrement: onDecrement,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfo(ThemeData theme, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TrainDialogUnitNameLine(name: displayName, isLocked: isLocked),
        const SizedBox(height: 2),
        _buildCostWrap(l10n),
        TrainDialogLockedHint(
          isLocked: isLocked,
          techRequiredLabel: techRequiredLabel,
        ),
      ],
    );
  }

  Widget _buildCostWrap(AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        TrainDialogInlineCost(
          icon: const Icon(
            Icons.payments_outlined,
            size: kTrainDialogCostIconSize,
          ),
          label: buildTreasuryCost.toString(),
          tooltipMessage: l10n.trainDialog_costTreasuryTooltip,
          isInsufficient: treasuryInsufficient,
        ),
        TrainDialogInlineCost(
          icon: const WorkerIcon(
            workerType: 'peasant',
            size: kTrainDialogCostIconSize,
          ),
          label: 1.toString(),
          tooltipMessage: l10n.trainDialog_costPeasantsTooltip,
          isInsufficient: peasantInsufficient,
        ),
        for (final input in buildInputs.entries)
          TrainDialogInlineCost(
            icon: ResourceIcon(
              commodityId: input.key,
              size: kTrainDialogCostIconSize,
            ),
            label: input.value.toString(),
            tooltipMessage: commodityIconTooltip(l10n, input.key),
            isInsufficient: insufficientCommodityIds.contains(input.key),
          ),
      ],
    );
  }
}
