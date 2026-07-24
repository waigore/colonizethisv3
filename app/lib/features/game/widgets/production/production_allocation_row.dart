import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'production_recipe_affordance.dart';
import 'production_allocation_row_controls.dart';

/// Opacity applied to a tech-locked recipe row's slider sub-row (slider plus
/// the four step/action controls) so it reads as grayed/disabled per
/// `SPEC/ui/production-panel.md` § Behaviour — Tech-gated recipe rows.
const double kProductionRecipeLockedOpacity = 0.4;

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
    this.locked = false,
  });

  final ProductionRecipe recipe;
  final Player player;
  final int effectiveLabour;
  final Map<String, int> desiredOutputByRecipe;
  final ValueChanged<Map<String, int>> onDesiredOutputChanged;
  final Widget Function(ProductionRecipe recipe, bool locked) buildRecipeLabel;
  final AppLocalizations l10n;
  final ThemeData theme;

  /// When `true`, the recipe's `requiredTechId` is not unlocked for [player]
  /// so the row renders visible-but-grayed and the slider/steppers are
  /// non-interactive per `SPEC/ui/production-panel.md` § Tech-gated recipe rows.
  final bool locked;

  int get desiredOutput => desiredOutputByRecipe[recipe.id] ?? 0;

  RecipeAffordance get affordance => computeRecipeAffordance(
    recipe: recipe,
    stockpile: player.stockpile,
    desiredOutputByRecipe: desiredOutputByRecipe,
    effectiveLabour: effectiveLabour,
    l10n: l10n,
  );

  bool get comfortHeadroom => recipeAllocationComfortHeadroomActive(
    recipe: recipe,
    desiredOutput: desiredOutput,
    maxDesiredOutput: affordance.maxDesiredOutput,
    stockpile: player.stockpile,
    desiredOutputByRecipe: desiredOutputByRecipe,
    effectiveLabour: effectiveLabour,
  );

  Widget buildHeader(RecipeAffordance rowAffordance, int maxAchievable) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: buildRecipeLabel(recipe, locked)),
        Expanded(
          flex: 1,
          child: Text(
            l10n.production_recipeAffordance(
              maxAchievable,
              rowAffordance.limitingLabel,
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
    final rowAffordance = affordance;
    // A locked recipe (its requiredTechId not unlocked for the player) cannot
    // be allocated, so its affordance reads 0 and the controls are disabled.
    final maxAchievable = locked ? 0 : rowAffordance.maxDesiredOutput;
    final sliderRow = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: buildAllocationSlider(maxAchievable)),
        buildAllocationActionButtons(maxAchievable),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        buildHeader(rowAffordance, maxAchievable),
        if (locked)
          IgnorePointer(
            child: Opacity(
              opacity: kProductionRecipeLockedOpacity,
              child: sliderRow,
            ),
          )
        else
          sliderRow,
      ],
    );
  }
}
