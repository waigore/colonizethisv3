// Allocation subpanel for production screen. SPEC/ui/production-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_danger_text_button.dart';
import '../../../../widgets/ct_gap.dart';
import '../../../../widgets/ct_panel.dart';
import 'production_panel_support_allocation_rows.dart';

export 'production_panel_support_allocation_rows.dart'
    show ProductionOpenCounselCallback;

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
            ...productionAllocationRows(
              player: player,
              effectiveLabour: effectiveLabour,
              desiredOutputByRecipe: desiredOutputByRecipe,
              onDesiredOutputChanged: onDesiredOutputChanged,
              l10n: l10n,
              canEditLabour: canEditLabour,
              starredProduceRecommendationsByRecipeId:
                  starredProduceRecommendationsByRecipeId,
              onOpenCounsel: onOpenCounsel,
              theme: theme,
            ),
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
