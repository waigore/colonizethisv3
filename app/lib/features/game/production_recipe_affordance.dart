import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Maximum desired output the production panel slider allows per recipe.
/// SPEC/ui/production-panel.md
const int kProductionAllocationSliderCap = 50;

/// Stock- and labour-based affordance for one recipe row (panel slider cap).
/// SPEC/ui/production-panel.md
final class RecipeAffordance {
  const RecipeAffordance({
    required this.maxDesiredOutput,
    required this.limitingLabel,
  });

  /// Desired output units allowed for this recipe (same cap as the slider).
  final int maxDesiredOutput;

  /// Commodity display name or `Labour` for the tightest constraint before
  /// [kProductionAllocationSliderCap] (ties: first recipe input in catalog
  /// map order, then labour).
  final String limitingLabel;
}

int _remainingLabourForRecipe({
  required String recipeId,
  required int effectiveLabour,
  required Map<String, int> desiredOutputByRecipe,
}) {
  var used = 0;
  for (final entry in desiredOutputByRecipe.entries) {
    if (entry.key == recipeId) continue;
    final recipe = ProductionRecipesCatalog.byId[entry.key];
    if (recipe != null) {
      used += entry.value * recipe.labourPerOutput;
    }
  }
  return (effectiveLabour - used).clamp(0, effectiveLabour);
}

Map<String, int> _remainingStockByCommodity({
  required String recipeId,
  required Stockpile stockpile,
  required Map<String, int> desiredOutputByRecipe,
}) {
  final remaining = <String, int>{};
  for (final comm in CommodityCatalog.all) {
    remaining[comm.id] = stockpile.quantityOf(comm.id);
  }
  for (final entry in desiredOutputByRecipe.entries) {
    if (entry.key == recipeId) continue;
    final recipe = ProductionRecipesCatalog.byId[entry.key];
    if (recipe != null) {
      for (final input in recipe.inputQuantities.entries) {
        remaining[input.key] =
            (remaining[input.key] ?? 0) - (input.value * entry.value);
      }
    }
  }
  for (final key in remaining.keys.toList()) {
    if (remaining[key]! < 0) {
      remaining[key] = 0;
    }
  }
  return remaining;
}

String _commodityDisplayName(String commodityId) {
  final c = CommodityCatalog.byId[commodityId];
  return c?.displayName ?? commodityId;
}

/// Computes max desired output and bottleneck label for [recipe].
///
/// Uses current stockpile minus inputs committed by **other** recipes'
/// desired outputs, and effective labour minus labour assigned to **other**
/// recipes — matching the allocation slider rules.
RecipeAffordance computeRecipeAffordance({
  required ProductionRecipe recipe,
  required Stockpile stockpile,
  required Map<String, int> desiredOutputByRecipe,
  required int effectiveLabour,
  int sliderCap = kProductionAllocationSliderCap,
}) {
  final labourPerOutput = recipe.labourPerOutput;
  final remainingLabour = _remainingLabourForRecipe(
    recipeId: recipe.id,
    effectiveLabour: effectiveLabour,
    desiredOutputByRecipe: desiredOutputByRecipe,
  );

  if (labourPerOutput <= 0) {
    return const RecipeAffordance(maxDesiredOutput: 0, limitingLabel: 'Labour');
  }

  var maxByLabour = remainingLabour ~/ labourPerOutput;
  if (maxByLabour <= 0) {
    return const RecipeAffordance(maxDesiredOutput: 0, limitingLabel: 'Labour');
  }

  final remainingStock = _remainingStockByCommodity(
    recipeId: recipe.id,
    stockpile: stockpile,
    desiredOutputByRecipe: desiredOutputByRecipe,
  );

  var trueMax = maxByLabour;
  final runsPerInput = <String, int>{};
  for (final entry in recipe.inputQuantities.entries) {
    final perUnit = entry.value;
    if (perUnit <= 0) {
      continue;
    }
    final have = remainingStock[entry.key] ?? 0;
    final runs = have ~/ perUnit;
    runsPerInput[entry.key] = runs;
    if (runs < trueMax) {
      trueMax = runs;
    }
  }

  String? limitingLabel;
  for (final entry in recipe.inputQuantities.entries) {
    final perUnit = entry.value;
    if (perUnit <= 0) {
      continue;
    }
    final runs = runsPerInput[entry.key] ?? 0;
    if (runs == trueMax) {
      limitingLabel = _commodityDisplayName(entry.key);
      break;
    }
  }
  limitingLabel ??= 'Labour';

  final capped = trueMax.clamp(0, sliderCap);
  return RecipeAffordance(
    maxDesiredOutput: capped,
    limitingLabel: limitingLabel,
  );
}
