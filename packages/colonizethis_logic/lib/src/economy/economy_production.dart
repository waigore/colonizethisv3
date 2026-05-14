import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Production resolution helpers.
/// SPEC/game/production-recipes.md
/// SPEC/game/workers-and-population.md

/// Builds production assignments from the production panel’s desired output
/// per recipe (units of output). SPEC/ui/production-panel.md.
List<AssignedRecipe> assignedRecipesFromDesiredOutput(
  Map<String, int> desiredByRecipe,
) {
  final list = <AssignedRecipe>[];
  for (final entry in desiredByRecipe.entries) {
    if (entry.value <= 0) continue;
    final recipe = ProductionRecipesCatalog.byId[entry.key];
    if (recipe == null) continue;
    final labour = entry.value * recipe.labourPerOutput;
    if (labour <= 0) continue;
    list.add(AssignedRecipe(recipeId: entry.key, assignedLabour: labour));
  }
  return list;
}

class ProductionResult {
  const ProductionResult({
    required this.stockpile,
    required this.workerPool,
    this.productionByRecipe = const {},
  });

  final Stockpile stockpile;
  final WorkerPool workerPool;

  /// Recipe id → quantity produced (output units). For projection API. SPEC/program/order-projections.md.
  final Map<String, int> productionByRecipe;
}

/// Resolves production for a single player for one turn.
///
/// - [stockpile]: starting stockpile (after Consumption for a normal turn).
/// - [workers]: starting WorkerPool (unchanged by production itself).
/// - [idleLabour]: idle worker headcounts from Consumption (fed + luxury when required).
/// - [assignments]: per-recipe labour assignments for this turn.
///
/// For each assignment, the number of runs is limited by:
/// - assigned labour (labourPerOutput per unit), and
/// - available input commodities in [stockpile].
ProductionResult resolveProduction({
  required Stockpile stockpile,
  required WorkerPool workers,
  required WorkerIdleCounts idleLabour,
  required List<AssignedRecipe> assignments,
}) {
  Stockpile current = stockpile;
  final productionByRecipe = <String, int>{};

  final effectiveLabour = idleLabour.effectiveLabour;
  var remainingEffectiveLabour = effectiveLabour;

  for (final assignment in assignments) {
    final recipe = ProductionRecipesCatalog.byId[assignment.recipeId];
    if (recipe == null) {
      logicLog.w('production skip unknown recipe id ${assignment.recipeId}');
      continue;
    }
    if (assignment.assignedLabour <= 0) continue;
    if (remainingEffectiveLabour <= 0) break;

    final labourPerOutput = recipe.labourPerOutput;
    if (labourPerOutput <= 0) {
      logicLog.w(
        'production recipe ${recipe.id} has non-positive labourPerOutput; skipping',
      );
      continue;
    }

    final labourBudgetForAssignment =
        assignment.assignedLabour <= remainingEffectiveLabour
        ? assignment.assignedLabour
        : remainingEffectiveLabour;
    if (labourBudgetForAssignment <= 0) continue;

    final maxByLabour = labourBudgetForAssignment ~/ labourPerOutput;
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

    remainingEffectiveLabour -= runs * labourPerOutput;
    if (remainingEffectiveLabour < 0) {
      remainingEffectiveLabour = 0;
    }

    productionByRecipe[assignment.recipeId] =
        (productionByRecipe[assignment.recipeId] ?? 0) + runs;

    // Deduct inputs.
    for (final entry in recipe.inputQuantities.entries) {
      final totalNeeded = entry.value * runs;
      current = current.applyDelta(entry.key, -totalNeeded);
    }

    // Add outputs.
    final totalOutput = recipe.outputQuantity * runs;
    current = current.applyDelta(recipe.outputCommodityId, totalOutput);
  }

  logicLog.d(
    'production assignments=${assignments.length} effectiveLabour=$effectiveLabour',
  );
  return ProductionResult(
    stockpile: current,
    workerPool: workers,
    productionByRecipe: productionByRecipe,
  );
}
