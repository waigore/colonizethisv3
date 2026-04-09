import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../config/constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n.dart';
import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_panel.dart';
import '../../../widgets/ct_slider.dart';
import '../../../widgets/resource_icon.dart';
import '../production_recipe_affordance.dart';

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

    if (isNarrow) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AvailableSubpanel(
              player: player,
              effectiveLabour: effectiveLabour,
              inputCommodityIds: inputCommodityIds,
              outputCommodityIds: outputCommodityIds,
              netDeltasByCommodity: netDeltasByCommodity,
              l10n: l10n,
              onOpenCommodityBreakdown: onOpenCommodityBreakdown,
            ),
            const SizedBox(height: 24),
            _AllocationSubpanel(
              player: player,
              effectiveLabour: effectiveLabour,
              desiredOutputByRecipe: desiredOutputByRecipe,
              onDesiredOutputChanged: onDesiredOutputChanged,
              l10n: l10n,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: _AvailableSubpanel(
              player: player,
              effectiveLabour: effectiveLabour,
              inputCommodityIds: inputCommodityIds,
              outputCommodityIds: outputCommodityIds,
              netDeltasByCommodity: netDeltasByCommodity,
              l10n: l10n,
              onOpenCommodityBreakdown: onOpenCommodityBreakdown,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 2,
            child: _AllocationSubpanel(
              player: player,
              effectiveLabour: effectiveLabour,
              desiredOutputByRecipe: desiredOutputByRecipe,
              onDesiredOutputChanged: onDesiredOutputChanged,
              l10n: l10n,
            ),
          ),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ResourceIcon(commodityId: c.id, size: 16),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${c.displayName ?? c.id}: $qty${change != 0 ? ' (${change > 0 ? '+' : ''}$change)' : ''}',
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
            '${_workerDisplayName(workerType)}: $count',
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
            if (availableFood.isNotEmpty) ...[
              Text(l10n.production_food, style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              _buildCommodityGrid(availableFood, netChanges, theme),
              const SizedBox(height: 12),
            ],
            Text(
              l10n.production_rawMaterials,
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            _buildCommodityGrid(rawMaterials, netChanges, theme),
            if (manufactured.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.production_manufactured,
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              _buildCommodityGrid(manufactured, netChanges, theme),
            ],
            const SizedBox(height: 12),
            Text(l10n.production_workers, style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWorkerRow('peasant', player.workerPool.peasants, theme),
                const SizedBox(height: 4),
                _buildWorkerRow(
                  'apprentice',
                  player.workerPool.apprentices,
                  theme,
                ),
                const SizedBox(height: 4),
                _buildWorkerRow(
                  'journeyman',
                  player.workerPool.journeymen,
                  theme,
                ),
                const SizedBox(height: 4),
                _buildWorkerRow('master', player.workerPool.masters, theme),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Effective labour: $effectiveLabour',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalRequiredLabour = desiredOutputByRecipe.entries.fold<int>(0, (
      sum,
      e,
    ) {
      final recipe = ProductionRecipesCatalog.byId[e.key];
      if (recipe == null) return sum;
      return sum + e.value * recipe.labourPerOutput;
    });
    final labourInsufficient = totalRequiredLabour > effectiveLabour;

    return CtPanel(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
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
                    l10n.production_allocation,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                CtNinePatchButton(
                  onPressed: () => onDesiredOutputChanged({}),
                  child: Text(l10n.common_reset),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...ProductionRecipesCatalog.all.map((recipe) {
              final desired = desiredOutputByRecipe[recipe.id] ?? 0;
              final affordance = computeRecipeAffordance(
                recipe: recipe,
                stockpile: player.stockpile,
                desiredOutputByRecipe: desiredOutputByRecipe,
                effectiveLabour: effectiveLabour,
              );
              final maxAchievable = affordance.maxDesiredOutput;
              final sliderMax = maxAchievable == 0
                  ? 0.0
                  : maxAchievable
                        .clamp(1, kProductionAllocationSliderCap)
                        .toDouble();
              final comfortHeadroom = recipeAllocationComfortHeadroomActive(
                recipe: recipe,
                desiredOutput: desired,
                maxDesiredOutput: maxAchievable,
                stockpile: player.stockpile,
                desiredOutputByRecipe: desiredOutputByRecipe,
                effectiveLabour: effectiveLabour,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildRecipeLabel(recipe, theme),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            '${affordance.maxDesiredOutput} · ${affordance.limitingLabel}',
                            textAlign: TextAlign.right,
                            style: theme.textTheme.labelSmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: CtSlider(
                            value: desired.clamp(0, maxAchievable).toDouble(),
                            min: 0,
                            max: sliderMax,
                            divisions: maxAchievable == 0
                                ? 1
                                : maxAchievable.clamp(
                                    1,
                                    kProductionAllocationSliderCap,
                                  ),
                            comfortHeadroomActive: comfortHeadroom,
                            onChanged: (v) {
                              final next = Map<String, int>.from(
                                desiredOutputByRecipe,
                              );
                              final val = v.round().clamp(0, maxAchievable);
                              if (val == 0) {
                                next.remove(recipe.id);
                              } else {
                                next[recipe.id] = val;
                              }
                              onDesiredOutputChanged(next);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 36,
                          child: Text(
                            '$desired',
                            textAlign: TextAlign.right,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Text(
              'Total labour: $totalRequiredLabour / $effectiveLabour',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: labourInsufficient ? theme.colorScheme.error : null,
              ),
            ),
            if (labourInsufficient)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Insufficient labour — production will be capped next turn',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
