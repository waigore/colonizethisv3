import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'commodity_ui_helpers.dart';
import 'production_allocation_row.dart';
import 'production_allocation_row_chrome.dart';
import 'industry_counsel_l10n.dart';
import 'production_industry_counsel_star.dart';

typedef ProductionOpenCounselCallback =
    void Function({String? highlightRecommendationId});

Widget productionAllocationRecipeLabel({
  required ProductionRecipe recipe,
  required ThemeData theme,
  required bool locked,
  required AppLocalizations l10n,
}) {
  final outputCommodity = CommodityCatalog.byId[recipe.outputCommodityId];
  final outputName = commodityDisplayName(l10n, recipe.outputCommodityId);
  final inputParts = recipe.inputQuantities.entries
      .map((e) {
        final name = commodityDisplayName(l10n, e.key);
        return '$name ×${e.value}';
      })
      .join(', ');
  final label = '$outputName ($inputParts)';

  final hasOutputIcon =
      outputCommodity != null && ResourceIcon.hasIcon(outputCommodity.id);

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (hasOutputIcon) ...[
        ResourceIcon(commodityId: recipe.outputCommodityId, size: 14),
        const SizedBox(width: 4),
      ],
      Flexible(
        child: Text(
          label,
          style: theme.textTheme.labelMedium,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      if (locked) ...[
        const SizedBox(width: 4),
        Text(
          l10n.production_recipeLocked,
          style: theme.textTheme.labelMedium?.copyWith(
            color: EditorialMonoclePalette.muted,
          ),
        ),
      ],
    ],
  );
}

/// Builds the recipe rows interleaved with `CtBrassDivider`s per
/// `SPEC/ui/production-panel.md` § Allocation row chrome — exactly
/// `N - 1` dividers between consecutive rows, none at the leading or
/// trailing edges (`Refs #2862` S3 / R13).
List<Widget> productionAllocationRows({
  required Player player,
  required int effectiveLabour,
  required Map<String, int> desiredOutputByRecipe,
  required ValueChanged<Map<String, int>> onDesiredOutputChanged,
  required AppLocalizations l10n,
  required bool canEditLabour,
  required Map<String, IndustryCounselRecommendation>
  starredProduceRecommendationsByRecipeId,
  required ProductionOpenCounselCallback? onOpenCounsel,
  required ThemeData theme,
}) {
  final recipes = ProductionRecipesCatalog.all;
  if (recipes.isEmpty) {
    return const <Widget>[];
  }
  final widgets = <Widget>[];
  for (int i = 0; i < recipes.length; i++) {
    if (i > 0) {
      widgets.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: CtBrassDivider(),
        ),
      );
    }
    final recipe = recipes[i];
    final locked = !ProductionRecipesCatalog.isRecipeAvailableForPlayer(
      recipe,
      player.techUnlocked,
    );
    final counselRecommendation =
        starredProduceRecommendationsByRecipeId[recipe.id];
    ProductionIndustryCounselStar? counselStar;
    if (counselRecommendation != null && onOpenCounsel != null && !locked) {
      final brief = industryCounselBriefForReason(
        l10n,
        counselRecommendation.briefReasonKey,
      );
      counselStar = ProductionIndustryCounselStar(
        briefMessage: brief,
        semanticLabel: l10n.production_industryCounselStarSemantic(brief),
        onOpenCounsel: () => onOpenCounsel(
          highlightRecommendationId: counselRecommendation.recommendationId,
        ),
      );
    }
    widgets.add(
      ProductionAllocationRowChrome(
        key: ValueKey<String>('production_alloc_row_chrome_${recipe.id}'),
        child: ProductionAllocationRow(
          key: ValueKey<String>('production_alloc_row_${recipe.id}'),
          recipe: recipe,
          player: player,
          effectiveLabour: effectiveLabour,
          desiredOutputByRecipe: desiredOutputByRecipe,
          onDesiredOutputChanged: onDesiredOutputChanged,
          buildRecipeLabel: (value, isLocked) =>
              productionAllocationRecipeLabel(
                recipe: value,
                theme: theme,
                locked: isLocked,
                l10n: l10n,
              ),
          l10n: l10n,
          theme: theme,
          locked: locked,
          canEditLabour: canEditLabour,
          counselStar: counselStar,
        ),
      ),
    );
  }
  return widgets;
}
