import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../widgets/ct_slider.dart';
import '../production_recipe_affordance.dart';
import 'production_allocation_mutations.dart';
import 'production_allocation_row_buttons.dart';

const _uiIconProductionAllocDecrement =
    'ui_icon_production_alloc_decrement.png';
const _uiIconProductionAllocIncrement =
    'ui_icon_production_alloc_increment.png';
const _uiIconProductionAllocMaximize = 'ui_icon_production_alloc_maximize.png';
const _uiIconProductionAllocClear = 'ui_icon_production_alloc_clear.png';

/// One row in the Production allocation list: recipe label + affordance,
/// slider, and the four step/action buttons. Extracted from
/// `production_panel.dart` so `_AvailableSubpanel` and `_AllocationSubpanel`
/// stay within the `app/lib/features/game/widgets` file-size budget.
class ProductionAllocationRow extends StatelessWidget {
  const ProductionAllocationRow({
    super.key,
    required this.recipe,
    required this.player,
    required this.effectiveLabour,
    required this.desiredOutputByRecipe,
    required this.onDesiredOutputChanged,
    required this.buildRecipeLabel,
    required this.l10n,
    required this.theme,
  });

  final ProductionRecipe recipe;
  final Player player;
  final int effectiveLabour;
  final Map<String, int> desiredOutputByRecipe;
  final ValueChanged<Map<String, int>> onDesiredOutputChanged;
  final Widget Function(ProductionRecipe recipe) buildRecipeLabel;
  final AppLocalizations l10n;
  final ThemeData theme;

  int get _desired => desiredOutputByRecipe[recipe.id] ?? 0;

  RecipeAffordance get _affordance => computeRecipeAffordance(
    recipe: recipe,
    stockpile: player.stockpile,
    desiredOutputByRecipe: desiredOutputByRecipe,
    effectiveLabour: effectiveLabour,
  );

  bool get _comfortHeadroom => recipeAllocationComfortHeadroomActive(
    recipe: recipe,
    desiredOutput: _desired,
    maxDesiredOutput: _affordance.maxDesiredOutput,
    stockpile: player.stockpile,
    desiredOutputByRecipe: desiredOutputByRecipe,
    effectiveLabour: effectiveLabour,
  );

  Widget _buildSlider(int maxAchievable) {
    final sliderMax = maxAchievable == 0
        ? 0.0
        : maxAchievable.clamp(1, kProductionAllocationSliderCap).toDouble();
    return CtSlider(
      value: _desired.clamp(0, maxAchievable).toDouble(),
      min: 0,
      max: sliderMax,
      divisions: maxAchievable == 0
          ? 1
          : maxAchievable.clamp(1, kProductionAllocationSliderCap),
      comfortHeadroomActive: _comfortHeadroom,
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

  Widget _buildActionButtons(int maxAchievable) {
    final canDecrement = _desired > 0;
    final canIncrement = maxAchievable > 0 && _desired < maxAchievable;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 30,
          child: Text(
            _desired.toString(),
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
          enabled: _desired > 0,
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

  Widget _buildHeader(RecipeAffordance affordance) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: buildRecipeLabel(recipe)),
        Expanded(
          flex: 1,
          child: Text(
            l10n.production_recipeAffordance(
              affordance.maxDesiredOutput,
              affordance.limitingLabel,
            ),
            textAlign: TextAlign.right,
            style: theme.textTheme.labelSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final affordance = _affordance;
    final maxAchievable = affordance.maxDesiredOutput;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(affordance),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _buildSlider(maxAchievable)),
            _buildActionButtons(maxAchievable),
          ],
        ),
      ],
    );
  }
}
