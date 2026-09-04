import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'production_affordance_development_cell.dart';
import 'production_recipe_affordance.dart';
import 'production_recipe_affordance_copy.dart';
import 'production_allocation_row_controls.dart';
import 'production_industry_counsel_star.dart';

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
    this.canEditLabour = true,
    this.counselStar,
    this.onOpenDevelopment,
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
  final bool canEditLabour;

  /// Optional industry counsel star for this recipe row.
  final ProductionIndustryCounselStar? counselStar;

  /// When set, commodity-navigable affordance lines open Development (Refs #4725).
  final void Function(String commodityId)? onOpenDevelopment;

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

  Widget buildHeader(
    RecipeAffordance rowAffordance,
    int maxAchievable, {
    ProductionIndustryCounselStar? headerCounselStar,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: buildRecipeLabel(recipe, locked)),
        ?headerCounselStar,
        if (!locked)
          Expanded(
            flex: 1,
            child: _buildAffordanceReadout(rowAffordance, maxAchievable),
          ),
      ],
    );
  }

  Widget _buildAffordanceReadout(
    RecipeAffordance rowAffordance,
    int maxAchievable,
  ) {
    final copy = formatProductionRecipeAffordanceCopy(
      l10n: l10n,
      affordance: rowAffordance,
      maxAchievable: maxAchievable,
    );
    final text = Text(
      copy.displayText,
      textAlign: TextAlign.right,
      style: theme.textTheme.labelSmall,
      semanticsLabel: copy.semanticsLabel,
    );
    final openDevelopment = onOpenDevelopment;
    final commodityId = rowAffordance.limitingCommodityId;
    if (openDevelopment != null &&
        recipeAffordanceOpensDevelopment(rowAffordance) &&
        commodityId != null) {
      final openSemantic = l10n.production_affordanceOpenDevelopmentSemantic(
        rowAffordance.limitingLabel,
      );
      return ProductionAffordanceDevelopmentCell(
        key: ValueKey<String>('production_affordance_${recipe.id}'),
        onOpenDevelopment: () => openDevelopment(commodityId),
        tooltip: '${copy.tooltipMessage} $openSemantic',
        semanticLabel: '${copy.semanticsLabel} $openSemantic',
        child: text,
      );
    }
    return Tooltip(
      message: copy.tooltipMessage,
      child: text,
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
        buildHeader(
          rowAffordance,
          maxAchievable,
          headerCounselStar: counselStar,
        ),
        if (locked || !canEditLabour)
          IgnorePointer(
            child: Opacity(
              opacity: locked ? kProductionRecipeLockedOpacity : 1,
              child: sliderRow,
            ),
          )
        else
          sliderRow,
      ],
    );
  }
}
