// Allocation subpanel for production screen. SPEC/ui/production-panel.md.

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_danger_text_button.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_panel.dart';
import '../../../../widgets/resource_icon.dart';
import 'commodity_ui_helpers.dart';
import 'production_allocation_row.dart';
import 'production_allocation_row_chrome.dart';
import 'industry_counsel_l10n.dart';
import 'production_industry_counsel_star.dart';

typedef ProductionOpenCounselCallback =
    void Function({String? highlightRecommendationId});

/// Right-hand Allocation subpanel on the production screen.
class ProductionPanelAllocationSubpanel extends StatelessWidget {
  const ProductionPanelAllocationSubpanel({
    required this.player,
    required this.effectiveLabour,
    required this.desiredOutputByRecipe,
    required this.onDesiredOutputChanged,
    required this.l10n,
    this.canEditLabour = true,
    this.starredProduceRecommendationsByRecipeId = const {},
    this.onOpenCounsel,
    super.key,
  });

  final Player player;
  final int effectiveLabour;
  final Map<String, int> desiredOutputByRecipe;
  final ValueChanged<Map<String, int>> onDesiredOutputChanged;
  final AppLocalizations l10n;
  final bool canEditLabour;
  final Map<String, IndustryCounselRecommendation>
  starredProduceRecommendationsByRecipeId;
  final ProductionOpenCounselCallback? onOpenCounsel;

  int _computeTotalRequiredLabour() {
    return desiredOutputByRecipe.entries.fold<int>(0, (sum, entry) {
      final recipe = ProductionRecipesCatalog.byId[entry.key];
      if (recipe == null) {
        return sum;
      }
      return sum + entry.value * recipe.labourPerOutput;
    });
  }

  Widget _buildAllocationHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            l10n.production_allocation,
            style: theme.textTheme.titleSmall,
          ),
        ),
        if (onOpenCounsel != null)
          CtActionTextButton(
            key: const ValueKey<String>('production_allocation_counsel_button'),
            onPressed: onOpenCounsel,
            label: l10n.production_counsel,
          ),
        CtDangerTextButton(
          key: const ValueKey<String>('production_allocation_reset_button'),
          onPressed: canEditLabour ? () => onDesiredOutputChanged({}) : null,
          label: l10n.common_reset,
          tooltip: l10n.common_reset,
        ),
      ],
    );
  }

  Widget _buildRecipeLabel(
    ProductionRecipe recipe,
    ThemeData theme,
    bool locked,
  ) {
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
  List<Widget> _buildAllocationRows(ThemeData theme) {
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
          onOpenCounsel: () => onOpenCounsel!(
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
                _buildRecipeLabel(value, theme, isLocked),
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

  List<Widget> _buildLabourSummary(
    ThemeData theme,
    int totalRequiredLabour,
    bool labourInsufficient,
  ) {
    return <Widget>[
      CtGap.m,
      Text(
        l10n.production_totalLabour(totalRequiredLabour, effectiveLabour),
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: labourInsufficient ? theme.colorScheme.error : null,
        ),
      ),
      if (labourInsufficient)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            l10n.production_labourInsufficient,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalRequiredLabour = _computeTotalRequiredLabour();
    final labourInsufficient = totalRequiredLabour > effectiveLabour;

    return CtPanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAllocationHeader(theme),
            CtGap.m,
            ..._buildAllocationRows(theme),
            ..._buildLabourSummary(
              theme,
              totalRequiredLabour,
              labourInsufficient,
            ),
          ],
        ),
      ),
    );
  }
}
