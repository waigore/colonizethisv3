import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'production_recipe_affordance.dart';

/// Player-facing default copy + semantics for an Allocation recipe affordance.
/// SPEC/ui/production-panel.md § Affordance bottleneck.
final class ProductionRecipeAffordanceCopy {
  const ProductionRecipeAffordanceCopy({
    required this.displayText,
    required this.semanticsLabel,
    required this.tooltipMessage,
  });

  final String displayText;
  final String semanticsLabel;
  final String tooltipMessage;
}

bool recipeAffordanceIsLabourLimited(RecipeAffordance affordance) =>
    affordance.limitingLabel == kRecipeAffordanceLabourLabel;

/// Navigate-iff for Allocation → Development (Refs #4725).
bool recipeAffordanceOpensDevelopment(RecipeAffordance affordance) =>
    !affordance.capLimited &&
    !recipeAffordanceIsLabourLimited(affordance) &&
    affordance.limitingCommodityId != null;

ProductionRecipeAffordanceCopy formatProductionRecipeAffordanceCopy({
  required AppLocalizations l10n,
  required RecipeAffordance affordance,
  required int maxAchievable,
}) {
  final tooltipMessage = l10n.production_recipeAffordanceTooltip;
  final displayText = _displayText(
    l10n: l10n,
    affordance: affordance,
    maxAchievable: maxAchievable,
  );
  return ProductionRecipeAffordanceCopy(
    displayText: displayText,
    tooltipMessage: tooltipMessage,
    semanticsLabel: '$displayText $tooltipMessage',
  );
}

String _displayText({
  required AppLocalizations l10n,
  required RecipeAffordance affordance,
  required int maxAchievable,
}) {
  if (maxAchievable <= 0) {
    if (recipeAffordanceIsLabourLimited(affordance)) {
      return l10n.production_recipeAffordanceCannotRunNotEnoughLabour;
    }
    return l10n.production_recipeAffordanceCannotRunShortOfCommodity(
      affordance.limitingLabel,
    );
  }
  if (affordance.capLimited) {
    return l10n.production_recipeAffordanceUpToLimitedByPanelCap(maxAchievable);
  }
  if (recipeAffordanceIsLabourLimited(affordance)) {
    return l10n.production_recipeAffordanceUpToLimitedByLabour(maxAchievable);
  }
  return l10n.production_recipeAffordanceUpToLimitedByCommodity(
    maxAchievable,
    affordance.limitingLabel,
  );
}
