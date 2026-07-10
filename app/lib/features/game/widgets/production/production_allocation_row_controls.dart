part of 'production_allocation_row.dart';

extension _ProductionAllocationRowControls on ProductionAllocationRow {
  Widget buildAllocationActionButtons(int maxAchievable) {
    final canDecrement = !locked && desiredOutput > 0;
    final canIncrement =
        !locked && maxAchievable > 0 && desiredOutput < maxAchievable;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 30,
          child: Text(
            desiredOutput.toString(),
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall,
          ),
        ),
        const SizedBox(width: 4),
        ProductionAllocationStepButton(
          enabled: canDecrement,
          readDesired: () => desiredOutputByRecipe,
          tryStepFromCurrent: (cur) => applyProductionRecipeDecrement(
            recipe: recipe,
            player: player,
            effectiveLabour: effectiveLabour,
            current: cur,
            onDesiredOutputChanged: onDesiredOutputChanged,
          ),
          semanticLabel: l10n.production_allocationDecrementRecipe,
          tooltip: l10n.production_allocationDecrementRecipe,
          assetFileName: _uiIconProductionAllocDecrement,
        ),
        const SizedBox(width: 4),
        ProductionAllocationStepButton(
          enabled: canIncrement,
          readDesired: () => desiredOutputByRecipe,
          tryStepFromCurrent: (cur) => applyProductionRecipeIncrement(
            recipe: recipe,
            player: player,
            effectiveLabour: effectiveLabour,
            current: cur,
            onDesiredOutputChanged: onDesiredOutputChanged,
          ),
          semanticLabel: l10n.production_allocationIncrementRecipe,
          tooltip: l10n.production_allocationIncrementRecipe,
          assetFileName: _uiIconProductionAllocIncrement,
        ),
        const SizedBox(width: 4),
        ProductionAllocationActionIconButton(
          enabled: canIncrement,
          readDesired: () => desiredOutputByRecipe,
          onPressedFromCurrent: (cur) => applyProductionRecipeMaximize(
            recipe: recipe,
            player: player,
            effectiveLabour: effectiveLabour,
            current: cur,
            onDesiredOutputChanged: onDesiredOutputChanged,
          ),
          semanticLabel: l10n.production_allocationMaximizeRecipe,
          tooltip: l10n.production_allocationMaximizeRecipe,
          assetFileName: _uiIconProductionAllocMaximize,
        ),
        const SizedBox(width: 4),
        ProductionAllocationActionIconButton(
          enabled: !locked && desiredOutput > 0,
          readDesired: () => desiredOutputByRecipe,
          onPressedFromCurrent: (cur) => applyProductionRecipeClear(
            recipe: recipe,
            current: cur,
            onDesiredOutputChanged: onDesiredOutputChanged,
          ),
          semanticLabel: l10n.production_allocationClearRecipe,
          tooltip: l10n.production_allocationClearRecipe,
          assetFileName: _uiIconProductionAllocClear,
        ),
      ],
    );
  }
}
