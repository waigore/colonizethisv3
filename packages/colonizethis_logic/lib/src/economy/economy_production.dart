import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Production resolution helpers.
/// SPEC/game/production-recipes.md
/// SPEC/game/workers-and-population.md

class AssignedRecipe {
  const AssignedRecipe({
    required this.recipeId,
    required this.assignedLabour,
  }) : assert(assignedLabour >= 0, 'assignedLabour must be non-negative');

  final String recipeId;
  final int assignedLabour;
}

class ProductionResult {
  const ProductionResult({
    required this.stockpile,
    required this.workerPool,
  });

  final Stockpile stockpile;
  final WorkerPool workerPool;
}

/// Resolves production for a single player for one turn.
///
/// - [stockpile]: starting stockpile.
/// - [workers]: starting WorkerPool (unchanged by production itself).
/// - [assignments]: per-recipe labour assignments for this turn.
///
/// For each assignment, the number of runs is limited by:
/// - assigned labour (labourPerOutput per unit), and
/// - available input commodities in [stockpile].
ProductionResult resolveProduction({
  required Stockpile stockpile,
  required WorkerPool workers,
  required List<AssignedRecipe> assignments,
}) {
  Stockpile current = stockpile;

  for (final assignment in assignments) {
    final recipe = ProductionRecipesCatalog.byId[assignment.recipeId];
    if (recipe == null) {
      continue; // unknown recipe id; ignore
    }
    if (assignment.assignedLabour <= 0) continue;

    final maxByLabour = assignment.assignedLabour ~/ recipe.labourPerOutput;
    if (maxByLabour <= 0) continue;

    // Compute maximum runs allowed by inputs.
    int maxByInputs = maxByLabour;
    for (final entry in recipe.inputQuantities.entries) {
      final have = current.quantityOf(entry.key);
      final neededPerRun = entry.value;
      if (neededPerRun <= 0) continue;
      final possible = have ~/ neededPerRun;
      if (possible < maxByInputs) {
        maxByInputs = possible;
      }
      if (maxByInputs == 0) break;
    }

    final runs = maxByInputs;
    if (runs <= 0) continue;

    // Deduct inputs.
    for (final entry in recipe.inputQuantities.entries) {
      final totalNeeded = entry.value * runs;
      current = current.applyDelta(entry.key, -totalNeeded);
    }

    // Add outputs.
    final totalOutput = recipe.outputQuantity * runs;
    current = current.applyDelta(recipe.outputCommodityId, totalOutput);
  }

  return ProductionResult(
    stockpile: current,
    workerPool: workers,
  );
}

