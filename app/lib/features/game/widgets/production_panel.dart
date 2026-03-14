import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../../widgets/ct_nine_patch_button.dart';
import '../../../widgets/ct_panel.dart';
import '../../../widgets/ct_slider.dart';

/// Production panel: available resources/workers and allocation sliders per recipe.
/// SPEC/ui/production-panel.md.
class ProductionPanel extends StatelessWidget {
  const ProductionPanel({
    super.key,
    required this.game,
    required this.player,
    required this.desiredOutputByRecipe,
    required this.onDesiredOutputChanged,
  });

  final Game game;
  final Player player;
  final Map<String, int> desiredOutputByRecipe;
  final ValueChanged<Map<String, int>> onDesiredOutputChanged;

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
    final effectiveLabour = effectiveLabourForWorkers(
      workers: player.workerPool,
      stockpile: player.stockpile,
    );
    final inputCommodityIds = _inputCommodityIds;
    final outputCommodityIds = _outputCommodityIds;
    const double narrowBreakpoint = 600;
    final isNarrow = MediaQuery.sizeOf(context).width < narrowBreakpoint;

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
              desiredOutputByRecipe: desiredOutputByRecipe,
            ),
            const SizedBox(height: 24),
            _AllocationSubpanel(
              player: player,
              effectiveLabour: effectiveLabour,
              desiredOutputByRecipe: desiredOutputByRecipe,
              onDesiredOutputChanged: onDesiredOutputChanged,
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
              desiredOutputByRecipe: desiredOutputByRecipe,
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
    required this.desiredOutputByRecipe,
  });

  final Player player;
  final int effectiveLabour;
  final Set<String> inputCommodityIds;
  final Set<String> outputCommodityIds;
  final Map<String, int> desiredOutputByRecipe;

  Map<String, int> _computeNetChanges() {
    final changes = <String, int>{};
    for (final entry in desiredOutputByRecipe.entries) {
      final recipe = ProductionRecipesCatalog.byId[entry.key];
      if (recipe == null) continue;
      for (final input in recipe.inputQuantities.entries) {
        changes[input.key] =
            (changes[input.key] ?? 0) - (input.value * entry.value);
      }
      changes[recipe.outputCommodityId] =
          (changes[recipe.outputCommodityId] ?? 0) +
              (recipe.outputQuantity * entry.value);
    }
    return changes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final netChanges = _computeNetChanges();

    final rawMaterials = CommodityCatalog.all
        .where((c) =>
            c.category == CommodityCategory.rawMaterial &&
            inputCommodityIds.contains(c.id))
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
                    'Available',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (availableFood.isNotEmpty) ...[
              Text(
                'Food',
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              ...availableFood.map((c) {
                final qty = player.stockpile.quantityOf(c.id);
                final change = netChanges[c.id] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${c.displayName ?? c.id}: $qty${change != 0 ? ' (${change > 0 ? '+' : ''}$change)' : ''}',
                    style: theme.textTheme.bodySmall,
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
            Text(
              'Raw Materials',
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            ...rawMaterials.map((c) {
              final qty = player.stockpile.quantityOf(c.id);
              final change = netChanges[c.id] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${c.displayName ?? c.id}: $qty${change != 0 ? ' (${change > 0 ? '+' : ''}$change)' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
              );
            }),
            if (manufactured.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Manufactured',
                style: theme.textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              ...manufactured.map((c) {
                final qty = player.stockpile.quantityOf(c.id);
                final change = netChanges[c.id] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${c.displayName ?? c.id}: $qty${change != 0 ? ' (${change > 0 ? '+' : ''}$change)' : ''}',
                    style: theme.textTheme.bodySmall,
                  ),
                );
              }),
            ],
            const SizedBox(height: 12),
            Text(
              'Workers',
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Peasants: ${player.workerPool.peasants}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'Apprentices: ${player.workerPool.apprentices}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'Journeymen: ${player.workerPool.journeymen}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'Masters: ${player.workerPool.masters}',
              style: theme.textTheme.bodySmall,
            ),
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
  });

  final Player player;
  final int effectiveLabour;
  final Map<String, int> desiredOutputByRecipe;
  final ValueChanged<Map<String, int>> onDesiredOutputChanged;

  static const int _absoluteMaxSliderOutput = 50;

  int _remainingLabour(String excludeRecipeId) {
    int used = 0;
    for (final entry in desiredOutputByRecipe.entries) {
      if (entry.key == excludeRecipeId) continue;
      final recipe = ProductionRecipesCatalog.byId[entry.key];
      if (recipe != null) {
        used += entry.value * recipe.labourPerOutput;
      }
    }
    return (effectiveLabour - used).clamp(0, effectiveLabour);
  }

  Map<String, int> _remainingInputs(String excludeRecipeId) {
    final remaining = <String, int>{};
    for (final comm in CommodityCatalog.all) {
      remaining[comm.id] = player.stockpile.quantityOf(comm.id);
    }
    for (final entry in desiredOutputByRecipe.entries) {
      if (entry.key == excludeRecipeId) continue;
      final recipe = ProductionRecipesCatalog.byId[entry.key];
      if (recipe != null) {
        for (final input in recipe.inputQuantities.entries) {
          remaining[input.key] =
              (remaining[input.key] ?? 0) - (input.value * entry.value);
        }
      }
    }
    for (final key in remaining.keys.toList()) {
      if (remaining[key]! < 0) remaining[key] = 0;
    }
    return remaining;
  }

  int _achievableRunsForRecipe(ProductionRecipe recipe) {
    final remainingLabour = _remainingLabour(recipe.id);
    var maxByLabour = remainingLabour ~/ recipe.labourPerOutput;
    if (maxByLabour <= 0) return 0;
    final remainingInputs = _remainingInputs(recipe.id);
    var maxByInputs = maxByLabour;
    for (final entry in recipe.inputQuantities.entries) {
      final remaining = remainingInputs[entry.key] ?? 0;
      final perRun = entry.value;
      if (perRun <= 0) continue;
      final runs = remaining ~/ perRun;
      if (runs < maxByInputs) maxByInputs = runs;
    }
    final cap = maxByInputs < maxByLabour ? maxByInputs : maxByLabour;
    return cap.clamp(0, _absoluteMaxSliderOutput);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalRequiredLabour = desiredOutputByRecipe.entries.fold<int>(
      0,
      (sum, e) {
        final recipe = ProductionRecipesCatalog.byId[e.key];
        if (recipe == null) return sum;
        return sum + e.value * recipe.labourPerOutput;
      },
    );
    final labourInsufficient = totalRequiredLabour > effectiveLabour;

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
                    'Allocation',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                CtNinePatchButton(
                  onPressed: () => onDesiredOutputChanged({}),
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...ProductionRecipesCatalog.all.map((recipe) {
              final outputCommodity =
                  CommodityCatalog.byId[recipe.outputCommodityId];
              final outputName =
                  outputCommodity?.displayName ?? recipe.outputCommodityId;
              final inputNames = recipe.inputQuantities.entries.map((e) {
                final comm = CommodityCatalog.byId[e.key];
                return comm?.displayName ?? e.key;
              }).join(', ');
              final label = '$outputName ($inputNames)';
              final desired = desiredOutputByRecipe[recipe.id] ?? 0;
              final maxAchievable = _achievableRunsForRecipe(recipe);
              final sliderMax = maxAchievable == 0
                  ? 0.0
                  : maxAchievable.clamp(1, _absoluteMaxSliderOutput).toDouble();

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelMedium,
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
                                    1, _absoluteMaxSliderOutput),
                            onChanged: (v) {
                              final next =
                                  Map<String, int>.from(desiredOutputByRecipe);
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
