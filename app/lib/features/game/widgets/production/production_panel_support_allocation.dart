/// Allocation subpanel for production screen. SPEC/ui/production-panel.md.

part of 'production_panel.dart';

class _AllocationSubpanel extends StatelessWidget {
  const _AllocationSubpanel({
    required this.player,
    required this.effectiveLabour,
    required this.desiredOutputByRecipe,
    required this.onDesiredOutputChanged,
    required this.l10n,
  });

  final Player player;
  final int effectiveLabour;
  final Map<String, int> desiredOutputByRecipe;
  final ValueChanged<Map<String, int>> onDesiredOutputChanged;
  final AppLocalizations l10n;

  Widget _buildRecipeLabel(
    ProductionRecipe recipe,
    ThemeData theme,
    bool locked,
  ) {
    final outputCommodity = CommodityCatalog.byId[recipe.outputCommodityId];
    final outputName = outputCommodity?.displayName ?? recipe.outputCommodityId;
    final inputParts = recipe.inputQuantities.entries
        .map((e) {
          final comm = CommodityCatalog.byId[e.key];
          final name = comm?.displayName ?? e.key;
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

  int _computeTotalRequiredLabour() {
    return desiredOutputByRecipe.entries.fold<int>(0, (sum, entry) {
      final recipe = ProductionRecipesCatalog.byId[entry.key];
      if (recipe == null) {
        return sum;
      }
      return sum + entry.value * recipe.labourPerOutput;
    });
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            l10n.production_allocation,
            style: theme.textTheme.titleSmall,
          ),
        ),
        CtDangerTextButton(
          key: const ValueKey<String>('production_allocation_reset_button'),
          onPressed: () => onDesiredOutputChanged({}),
          label: l10n.common_reset,
          tooltip: l10n.common_reset,
        ),
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
            _buildHeader(theme),
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
