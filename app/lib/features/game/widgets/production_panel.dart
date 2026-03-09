import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final effectiveLabour = effectiveLabourForWorkers(
      workers: player.workerPool,
      stockpile: player.stockpile,
    );
    // SPEC/ui/production-panel.md: narrow viewport = vertically stacked, scrollable.
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
  });

  final Player player;
  final int effectiveLabour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Stockpile',
              style: theme.textTheme.labelMedium,
            ),
            const SizedBox(height: 4),
            ...CommodityCatalog.all.map((c) {
              final qty = player.stockpile.quantityOf(c.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  '${c.displayName ?? c.id}: $qty',
                  style: theme.textTheme.bodySmall,
                ),
              );
            }),
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

  /// Max runs achievable for this recipe alone (inputs and labour). Used to cap slider.
  int _achievableRunsForRecipe(ProductionRecipe recipe) {
    var maxByLabour = effectiveLabour ~/ recipe.labourPerOutput;
    if (maxByLabour <= 0) return 0;
    var maxByInputs = maxByLabour;
    for (final entry in recipe.inputQuantities.entries) {
      final have = player.stockpile.quantityOf(entry.key);
      final perRun = entry.value;
      if (perRun <= 0) continue;
      final runs = have ~/ perRun;
      if (runs < maxByInputs) maxByInputs = runs;
    }
    final cap = maxByInputs < maxByLabour ? maxByInputs : maxByLabour;
    return cap.clamp(0, _absoluteMaxSliderOutput);
  }

  /// Whether required inputs for [desired] runs exceed stockpile.
  bool _hasInsufficientInputs(ProductionRecipe recipe, int desired) {
    if (desired <= 0) return false;
    for (final entry in recipe.inputQuantities.entries) {
      final have = player.stockpile.quantityOf(entry.key);
      final need = entry.value * desired;
      if (need > have) return true;
    }
    return false;
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

    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Allocation',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            ...ProductionRecipesCatalog.all.map((recipe) {
              final outputCommodity = CommodityCatalog.byId[recipe.outputCommodityId];
              final label = outputCommodity?.displayName ?? recipe.outputCommodityId;
              final desired = desiredOutputByRecipe[recipe.id] ?? 0;
              final maxAchievable = _achievableRunsForRecipe(recipe);
              final sliderMax = maxAchievable == 0
                  ? 0.0
                  : maxAchievable.clamp(1, _absoluteMaxSliderOutput).toDouble();
              final requiredLabour = desired * recipe.labourPerOutput;
              final inputsInsufficient = _hasInsufficientInputs(recipe, desired);

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
                          child: Slider(
                            value: desired.clamp(0, maxAchievable).toDouble(),
                            min: 0,
                            max: sliderMax,
                            divisions: maxAchievable == 0
                                ? 1
                                : maxAchievable.clamp(1, _absoluteMaxSliderOutput),
                            label: '$desired',
                            onChanged: (v) {
                              final next = Map<String, int>.from(desiredOutputByRecipe);
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
                    if (desired > 0) ...[
                      Text(
                        'Labour: $requiredLabour',
                        style: theme.textTheme.bodySmall,
                      ),
                      ...recipe.inputQuantities.entries.map(
                        (e) {
                          final comm = CommodityCatalog.byId[e.key];
                          final name = comm?.displayName ?? e.key;
                          final need = e.value * desired;
                          final have = player.stockpile.quantityOf(e.key);
                          final insufficient = need > have;
                          return Text(
                            '  $name: $need${insufficient ? ' (have $have)' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: insufficient
                                  ? theme.colorScheme.error
                                  : null,
                            ),
                          );
                        },
                      ),
                      if (inputsInsufficient)
                        Text(
                          'Insufficient inputs',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
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
