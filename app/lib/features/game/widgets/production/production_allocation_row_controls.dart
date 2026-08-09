import 'package:flutter/material.dart';

import '../../../../widgets/ct_slider.dart';
import 'production_allocation_mutations.dart';
import 'production_allocation_row.dart';
import 'production_allocation_row_buttons.dart';
import 'production_recipe_affordance.dart';

const kUiIconProductionAllocDecrement = 'ui_icon_production_alloc_decrement.png';
const kUiIconProductionAllocIncrement = 'ui_icon_production_alloc_increment.png';
const kUiIconProductionAllocMaximize = 'ui_icon_production_alloc_maximize.png';
const kUiIconProductionAllocClear = 'ui_icon_production_alloc_clear.png';

extension ProductionAllocationRowSlider on ProductionAllocationRow {
  Widget buildAllocationSlider(int maxAchievable) {
    final sliderMax = maxAchievable == 0
        ? 0.0
        : maxAchievable.clamp(1, kProductionAllocationSliderCap).toDouble();
    return CtSlider(
      value: desiredOutput.clamp(0, maxAchievable).toDouble(),
      min: 0,
      max: sliderMax,
      divisions: maxAchievable == 0
          ? 1
          : maxAchievable.clamp(1, kProductionAllocationSliderCap),
      comfortHeadroomActive: comfortHeadroom,
      onChanged: (value) {
        final next = Map<String, int>.from(desiredOutputByRecipe);
        final rounded = value.round().clamp(0, maxAchievable);
        if (rounded == 0) {
          next.remove(recipe.id);
        } else {
          next[recipe.id] = rounded;
        }
        onDesiredOutputChanged(next);
      },
    );
  }
}

extension ProductionAllocationRowControls on ProductionAllocationRow {
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
          assetFileName: kUiIconProductionAllocDecrement,
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
          assetFileName: kUiIconProductionAllocIncrement,
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
          assetFileName: kUiIconProductionAllocMaximize,
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
          assetFileName: kUiIconProductionAllocClear,
        ),
      ],
    );
  }
}
