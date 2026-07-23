/// Allocation subpanel row chrome for production screen.
/// SPEC/ui/production-panel.md.

part of 'production_panel.dart';

extension _AllocationSubpanelRows on _AllocationSubpanel {
  Widget buildRecipeLabel(
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
  List<Widget> buildAllocationRows(ThemeData theme) {
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
                buildRecipeLabel(value, theme, isLocked),
            l10n: l10n,
            theme: theme,
            locked: locked,
          ),
        ),
      );
    }
    return widgets;
  }
}
