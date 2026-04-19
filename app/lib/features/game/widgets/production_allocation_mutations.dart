import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../production_recipe_affordance.dart';

/// Applies **+1** to [recipe] using a fresh affordance pass on [current].
/// Returns **false** when no change (repeat timers should stop).
bool applyProductionRecipeIncrement({
  required ProductionRecipe recipe,
  required Player player,
  required int effectiveLabour,
  required Map<String, int> current,
  required void Function(Map<String, int> next) onDesiredOutputChanged,
}) {
  final next = Map<String, int>.from(current);
  final affordance = computeRecipeAffordance(
    recipe: recipe,
    stockpile: player.stockpile,
    desiredOutputByRecipe: next,
    effectiveLabour: effectiveLabour,
  );
  final maxA = affordance.maxDesiredOutput;
  final d = next[recipe.id] ?? 0;
  if (maxA <= 0 || d >= maxA) {
    return false;
  }
  final nv = (d + 1).clamp(0, maxA);
  if (nv == 0) {
    next.remove(recipe.id);
  } else {
    next[recipe.id] = nv;
  }
  onDesiredOutputChanged(next);
  return true;
}

/// Applies **−1** to [recipe] using a fresh affordance pass on [current].
/// Returns **false** when no change (repeat timers should stop).
bool applyProductionRecipeDecrement({
  required ProductionRecipe recipe,
  required Player player,
  required int effectiveLabour,
  required Map<String, int> current,
  required void Function(Map<String, int> next) onDesiredOutputChanged,
}) {
  final next = Map<String, int>.from(current);
  final d = next[recipe.id] ?? 0;
  if (d <= 0) {
    return false;
  }
  final affordance = computeRecipeAffordance(
    recipe: recipe,
    stockpile: player.stockpile,
    desiredOutputByRecipe: next,
    effectiveLabour: effectiveLabour,
  );
  final maxA = affordance.maxDesiredOutput;
  final nv = (d - 1).clamp(0, maxA);
  if (nv == 0) {
    next.remove(recipe.id);
  } else {
    next[recipe.id] = nv;
  }
  onDesiredOutputChanged(next);
  return true;
}

/// Sets [recipe] to **maxAchievable** for the current [current] map.
bool applyProductionRecipeMaximize({
  required ProductionRecipe recipe,
  required Player player,
  required int effectiveLabour,
  required Map<String, int> current,
  required void Function(Map<String, int> next) onDesiredOutputChanged,
}) {
  final next = Map<String, int>.from(current);
  final affordance = computeRecipeAffordance(
    recipe: recipe,
    stockpile: player.stockpile,
    desiredOutputByRecipe: next,
    effectiveLabour: effectiveLabour,
  );
  final maxA = affordance.maxDesiredOutput;
  final d = next[recipe.id] ?? 0;
  if (maxA <= 0 || d >= maxA) {
    return false;
  }
  next[recipe.id] = maxA;
  onDesiredOutputChanged(next);
  return true;
}

/// Clears [recipe] to **0** (removes key).
bool applyProductionRecipeClear({
  required ProductionRecipe recipe,
  required Map<String, int> current,
  required void Function(Map<String, int> next) onDesiredOutputChanged,
}) {
  final next = Map<String, int>.from(current);
  final d = next[recipe.id] ?? 0;
  if (d <= 0) {
    return false;
  }
  next.remove(recipe.id);
  onDesiredOutputChanged(next);
  return true;
}
