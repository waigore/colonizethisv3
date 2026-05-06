import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/constants.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_panel.dart';
import '../../../widgets/ct_slider.dart';
import '../../../widgets/resource_icon.dart';
import '../production_recipe_affordance.dart';
import 'production_allocation_mutations.dart';
import 'production_allocation_row_buttons.dart';

const _uiIconProductionAllocDecrement =
    'ui_icon_production_alloc_decrement.png';
const _uiIconProductionAllocIncrement =
    'ui_icon_production_alloc_increment.png';
const _uiIconProductionAllocMaximize = 'ui_icon_production_alloc_maximize.png';
const _uiIconProductionAllocClear = 'ui_icon_production_alloc_clear.png';

class ProductionPanel extends StatelessWidget {
  const ProductionPanel({
    super.key,
    required this.game,
    required this.player,
    required this.desiredOutputByRecipe,
    required this.netDeltasByCommodity,
    required this.onDesiredOutputChanged,
    this.onOpenCommodityBreakdown,
  });

  final Game game;
  final Player player;
  final Map<String, int> desiredOutputByRecipe;
  final Map<String, int> netDeltasByCommodity;
  final ValueChanged<Map<String, int>> onDesiredOutputChanged;

  /// When set, Available header shows a text button that opens the breakdown dialog.
  final VoidCallback? onOpenCommodityBreakdown;

  static Set<String> get _inputCommodityIds {
    final inputIds = <String>{};
    for (final recipe in ProductionRecipesCatalog.all) {
      inputIds.addAll(recipe.inputQuantities.keys);
    }
    return inputIds;
  }

  static Set<String> get _outputCommodityIds {
    return ProductionRecipesCatalog.all.map((r) => r.outputCommodityId).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = appL10n(context);
    final regimentCounts = regimentTypeCountsForPlayer(
      game.worldState,
      player.id,
    );
    final shipCounts = shipTypeCountsForPlayer(game.worldState, player.id);
    final effectiveLabour = effectiveLabourForWorkers(
      workers: player.workerPool,
      stockpile: player.stockpile,
      regimentCountsById: regimentCounts,
      shipCountsById: shipCounts,
    );
    final inputCommodityIds = _inputCommodityIds;
    final outputCommodityIds = _outputCommodityIds;
    final isNarrow = MediaQuery.sizeOf(context).width < kNarrowBreakpoint;
    final availableSubpanel = _AvailableSubpanel(
      player: player,
      effectiveLabour: effectiveLabour,
      inputCommodityIds: inputCommodityIds,
      outputCommodityIds: outputCommodityIds,
      netDeltasByCommodity: netDeltasByCommodity,
      l10n: l10n,
      onOpenCommodityBreakdown: onOpenCommodityBreakdown,
    );
    final allocationSubpanel = _AllocationSubpanel(
      player: player,
      effectiveLabour: effectiveLabour,
      desiredOutputByRecipe: desiredOutputByRecipe,
      onDesiredOutputChanged: onDesiredOutputChanged,
      l10n: l10n,
    );

    if (isNarrow) {
      return _ProductionPanelNarrowLayout(
        availableSubpanel: availableSubpanel,
        allocationSubpanel: allocationSubpanel,
      );
    }

    return _ProductionPanelWideLayout(
      availableSubpanel: availableSubpanel,
      allocationSubpanel: allocationSubpanel,
    );
  }
}

class _ProductionPanelNarrowLayout extends StatelessWidget {
  const _ProductionPanelNarrowLayout({
    required this.availableSubpanel,
    required this.allocationSubpanel,
  });

  final Widget availableSubpanel;
  final Widget allocationSubpanel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          availableSubpanel,
          const SizedBox(height: 24),
          allocationSubpanel,
        ],
      ),
    );
  }
}

class _ProductionPanelWideLayout extends StatelessWidget {
  const _ProductionPanelWideLayout({
    required this.availableSubpanel,
    required this.allocationSubpanel,
  });

  final Widget availableSubpanel;
  final Widget allocationSubpanel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 1, child: availableSubpanel),
          const SizedBox(width: 24),
          Expanded(flex: 2, child: allocationSubpanel),
        ],
      ),
    );
  }
}

class _AvailableSubpanel extends StatelessWidget {
  const _AvailableSubpanel({
    required this.player,
    required this.effectiveLabour,
    required this.inputCommodityIds,
    required this.outputCommodityIds,
    required this.netDeltasByCommodity,
    required this.l10n,
    this.onOpenCommodityBreakdown,
  });

  final Player player;
  final int effectiveLabour;
  final Set<String> inputCommodityIds;
  final Set<String> outputCommodityIds;
  final Map<String, int> netDeltasByCommodity;
  final AppLocalizations l10n;
  final VoidCallback? onOpenCommodityBreakdown;

  Widget _buildCommodityRow(Commodity c, int qty, int change, ThemeData theme) {
    final name = c.displayName ?? c.id;
    final changeSeg = change == 0 ? '' : ' (${change > 0 ? '+' : ''}$change)';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ResourceIcon(commodityId: c.id, size: 16),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            l10n.production_commodityStock(name, qty, changeSeg),
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCommodityGrid(
    List<Commodity> commodities,
    Map<String, int> netChanges,
    ThemeData theme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 8,
        runSpacing: 4,
        children: commodities.map((c) {
          final qty = player.stockpile.quantityOf(c.id);
          final change = netChanges[c.id] ?? 0;
          return SizedBox(
            width: constraints.maxWidth,
            child: _buildCommodityRow(c, qty, change, theme),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWorkerRow(String workerType, int count, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        WorkerIcon(workerType: workerType, size: 16),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            l10n.production_workerCount(_workerDisplayName(workerType), count),
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _workerDisplayName(String workerType) {
    switch (workerType) {
      case 'peasant':
        return l10n.production_workers_peasants;
      case 'apprentice':
        return l10n.production_workers_apprentices;
      case 'journeyman':
        return l10n.production_workers_journeymen;
      case 'master':
        return l10n.production_workers_masters;
      default:
        return workerType;
    }
  }

  List<Widget> _buildFoodSection(
    List<Commodity> availableFood,
    Map<String, int> netChanges,
    ThemeData theme,
  ) {
    if (availableFood.isEmpty) {
      return const <Widget>[];
    }
    return <Widget>[
      Text(l10n.production_food, style: theme.textTheme.labelMedium),
      const SizedBox(height: 4),
      _buildCommodityGrid(availableFood, netChanges, theme),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _buildMaterialsSection(
    List<Commodity> rawMaterials,
    List<Commodity> manufactured,
    Map<String, int> netChanges,
    ThemeData theme,
  ) {
    final children = <Widget>[
      Text(l10n.production_rawMaterials, style: theme.textTheme.labelMedium),
      const SizedBox(height: 4),
      _buildCommodityGrid(rawMaterials, netChanges, theme),
    ];
    if (manufactured.isNotEmpty) {
      children.addAll([
        const SizedBox(height: 12),
        Text(l10n.production_manufactured, style: theme.textTheme.labelMedium),
        const SizedBox(height: 4),
        _buildCommodityGrid(manufactured, netChanges, theme),
      ]);
    }
    return children;
  }

  List<Widget> _buildWorkerSection(ThemeData theme) {
    return <Widget>[
      const SizedBox(height: 12),
      Text(l10n.production_workers, style: theme.textTheme.labelMedium),
      const SizedBox(height: 4),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWorkerRow('peasant', player.workerPool.peasants, theme),
          const SizedBox(height: 4),
          _buildWorkerRow('apprentice', player.workerPool.apprentices, theme),
          const SizedBox(height: 4),
          _buildWorkerRow('journeyman', player.workerPool.journeymen, theme),
          const SizedBox(height: 4),
          _buildWorkerRow('master', player.workerPool.masters, theme),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        l10n.production_effectiveLabour(effectiveLabour),
        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final netChanges = netDeltasByCommodity;

    final rawMaterials = CommodityCatalog.all
        .where(
          (c) =>
              c.category == CommodityCategory.rawMaterial &&
              inputCommodityIds.contains(c.id),
        )
        .toList();
    final manufactured = CommodityCatalog.all
        .where((c) => c.category == CommodityCategory.manufactured)
        .toList();
    final availableFood = CommodityCatalog.all
        .where((c) => c.category == CommodityCategory.food)
        .toList();

    return CtPanel(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.production_available,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (onOpenCommodityBreakdown != null)
                  CtNinePatchButton(
                    onPressed: onOpenCommodityBreakdown,
                    child: Text(l10n.production_breakdown),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ..._buildFoodSection(availableFood, netChanges, theme),
            ..._buildMaterialsSection(
              rawMaterials,
              manufactured,
              netChanges,
              theme,
            ),
            ..._buildWorkerSection(theme),
          ],
        ),
      ),
    );
  }
}

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

  Widget _buildRecipeLabel(ProductionRecipe recipe, ThemeData theme) {
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
        CtNinePatchButton(
          onPressed: () => onDesiredOutputChanged({}),
          child: Text(l10n.common_reset),
        ),
      ],
    );
  }

  Iterable<Widget> _buildAllocationRows(ThemeData theme) {
    return ProductionRecipesCatalog.all.map(
      (recipe) => _ProductionAllocationRow(
        key: ValueKey<String>('production_alloc_row_${recipe.id}'),
        recipe: recipe,
        player: player,
        effectiveLabour: effectiveLabour,
        desiredOutputByRecipe: desiredOutputByRecipe,
        onDesiredOutputChanged: onDesiredOutputChanged,
        buildRecipeLabel: (value) => _buildRecipeLabel(value, theme),
        l10n: l10n,
        theme: theme,
      ),
    );
  }

  List<Widget> _buildLabourSummary(
    ThemeData theme,
    int totalRequiredLabour,
    bool labourInsufficient,
  ) {
    return <Widget>[
      const SizedBox(height: 8),
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
            const SizedBox(height: 8),
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

class _ProductionAllocationRow extends StatelessWidget {
  const _ProductionAllocationRow({
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
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
      ),
    );
  }
}
