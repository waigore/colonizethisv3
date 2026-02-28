import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

final Logger _log = Logger();

/// Computes effective available labour for production, capped by luxury
/// availability per SPEC/program/economy-models.md and
/// SPEC/game/workers-and-population.md.
/// Public for use by AI economy planner. SPEC/ai/economy-planner.md.
int effectiveLabourForWorkers({
  required WorkerPool workers,
  required Stockpile stockpile,
}) {
  final peasantsLabour = workers.peasants * 1;

  final refinedSugar = stockpile.quantityOf(CommodityCatalog.refinedSugar.id);
  final cigars = stockpile.quantityOf(CommodityCatalog.cigars.id);
  final furHats = stockpile.quantityOf(CommodityCatalog.furHats.id);

  final apprenticesWithLuxury = workers.apprentices <= 0
      ? 0
      : (refinedSugar < workers.apprentices ? refinedSugar : workers.apprentices);
  final journeymenWithLuxury = workers.journeymen <= 0
      ? 0
      : (cigars < workers.journeymen ? cigars : workers.journeymen);
  final mastersWithLuxury = workers.masters <= 0
      ? 0
      : (furHats < workers.masters ? furHats : workers.masters);

  return peasantsLabour +
      apprenticesWithLuxury * 4 +
      journeymenWithLuxury * 6 +
      mastersWithLuxury * 8;
}

int _effectiveLabourForWorkers({
  required WorkerPool workers,
  required Stockpile stockpile,
}) =>
    effectiveLabourForWorkers(workers: workers, stockpile: stockpile);

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
    this.productionByRecipe = const {},
  });

  final Stockpile stockpile;
  final WorkerPool workerPool;

  /// Recipe id → quantity produced (output units). For projection API. SPEC/program/order-projections.md.
  final Map<String, int> productionByRecipe;
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
  final productionByRecipe = <String, int>{};

  final effectiveLabour = _effectiveLabourForWorkers(
    workers: workers,
    stockpile: stockpile,
  );
  var remainingEffectiveLabour = effectiveLabour;

  for (final assignment in assignments) {
    final recipe = ProductionRecipesCatalog.byId[assignment.recipeId];
    if (recipe == null) {
      _log.w('logic: production skip unknown recipe id ${assignment.recipeId}');
      continue;
    }
    if (assignment.assignedLabour <= 0) continue;
    if (remainingEffectiveLabour <= 0) break;

    final labourPerOutput = recipe.labourPerOutput;
    if (labourPerOutput <= 0) {
      _log.w(
        'logic: production recipe ${recipe.id} has non-positive labourPerOutput; skipping',
      );
      continue;
    }

    final labourBudgetForAssignment = assignment.assignedLabour <= remainingEffectiveLabour
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

  _log.d(
    'logic: production assignments=${assignments.length} effectiveLabour=$effectiveLabour',
  );
  return ProductionResult(
    stockpile: current,
    workerPool: workers,
    productionByRecipe: productionByRecipe,
  );
}

