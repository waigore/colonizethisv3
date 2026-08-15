/// Core greedy labour allocation (AI path without H8 / crisis boosts).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../economy_consumption_phases.dart';
import 'industry_counsel_constants.dart';
import 'industry_counsel_growth_stage.dart';
import 'industry_counsel_scored_candidate.dart';
import 'industry_counsel_scoring.dart';

/// Greedy labour allocation using core scoring only (neutral agenda, no boosts).
List<AssignedRecipe> industryCounselAllocateLabourCore({
  required Stockpile stockpile,
  required WorkerPool workers,
  required int effectiveLabour,
  required Map<String, bool>? techUnlocked,
  String agendaId = kIndustryCounselNeutralAgendaId,
  IndustryCounselGrowthStage? growthStage,
  bool growthStagePlannerEnabled = kIndustryCounselGrowthStageEnabled,
}) {
  // ignore: disallowed_ast_ai_full_recipe_catalog_scan
  final recipes = ProductionRecipesCatalog.all;
  Stockpile virtual = stockpile;
  var remainingLabour = effectiveLabour;
  final labourByRecipe = <String, int>{};

  final candidates = <IndustryCounselScoredCandidate<ProductionRecipe>>[];
  for (final recipe in recipes) {
    if (!ProductionRecipesCatalog.isRecipeAvailableForPlayer(
      recipe,
      techUnlocked,
    )) {
      continue;
    }
    if (recipe.labourPerOutput <= 0) continue;
    final runs = industryCounselFeasibleRuns(
      recipe: recipe,
      stockpile: virtual,
      remainingLabour: remainingLabour,
    );
    if (runs <= 0) continue;

    final score = growthStagePlannerEnabled && growthStage != null
        ? industryCounselStageScaledRecipeScore(
            recipe: recipe,
            stockpile: virtual,
            workers: workers,
            agendaId: agendaId,
            stage: growthStage,
          )
        : industryCounselScoreRecipe(
            recipe: recipe,
            stockpile: virtual,
            workers: workers,
            agendaId: agendaId,
          );
    if (score <= 0) continue;
    candidates.add(IndustryCounselScoredCandidate(item: recipe, score: score));
  }

  if (candidates.isEmpty) return const [];

  final rankedRecipes = sortIndustryCounselByScore(
    candidates,
    (a, b) => a.id.compareTo(b.id),
  );

  for (final recipe in rankedRecipes) {
    final runs = industryCounselFeasibleRuns(
      recipe: recipe,
      stockpile: virtual,
      remainingLabour: remainingLabour,
    );
    if (runs <= 0) continue;

    final labourUsed = runs * recipe.labourPerOutput;
    labourByRecipe[recipe.id] = (labourByRecipe[recipe.id] ?? 0) + labourUsed;
    remainingLabour -= labourUsed;
    for (final entry in recipe.inputQuantities.entries) {
      virtual = virtual.applyDelta(entry.key, -entry.value * runs);
    }
    virtual = virtual.applyDelta(
      recipe.outputCommodityId,
      recipe.outputQuantity * runs,
    );
  }

  return [
    for (final entry in labourByRecipe.entries)
      AssignedRecipe(recipeId: entry.key, assignedLabour: entry.value),
  ];
}

int industryCounselTotalAssignedLabour(List<AssignedRecipe> assignments) {
  var total = 0;
  for (final assigned in assignments) {
    total += assigned.assignedLabour;
  }
  return total;
}

int industryCounselDesiredOutputForAssignment(AssignedRecipe assignment) {
  final recipe = ProductionRecipesCatalog.byId[assignment.recipeId];
  if (recipe == null || recipe.labourPerOutput <= 0) return 0;
  return assignment.assignedLabour ~/ recipe.labourPerOutput;
}

Map<String, int> industryCounselProjectedLuxuryOutput(
  List<AssignedRecipe> assignments,
) {
  final out = <String, int>{};
  for (final assigned in assignments) {
    final recipe = ProductionRecipesCatalog.byId[assigned.recipeId];
    if (recipe == null) continue;
    final outputId = recipe.outputCommodityId;
    if (outputId != CommodityCatalog.refinedSugar.id &&
        outputId != CommodityCatalog.cigars.id &&
        outputId != CommodityCatalog.furHats.id) {
      continue;
    }
    final labourPer = recipe.labourPerOutput;
    if (labourPer <= 0) continue;
    final runs = assigned.assignedLabour ~/ labourPer;
    if (runs <= 0) continue;
    out[outputId] = (out[outputId] ?? 0) + runs * recipe.outputQuantity;
  }
  return out;
}

int industryCounselSoftLuxuryCapDeficitLimit(int sustainable) {
  if (sustainable <= 0) return 0;
  return (sustainable * 12) ~/ 10;
}

Map<WorkerTier, int> industryCounselSustainableTrainedCounts({
  required Stockpile stockpile,
  required List<AssignedRecipe> productionAssignments,
}) {
  final projected = industryCounselProjectedLuxuryOutput(productionAssignments);
  return {
    WorkerTier.apprentice:
        stockpile.quantityOf(CommodityCatalog.refinedSugar.id) +
        (projected[CommodityCatalog.refinedSugar.id] ?? 0),
    WorkerTier.journeyman:
        stockpile.quantityOf(CommodityCatalog.cigars.id) +
        (projected[CommodityCatalog.cigars.id] ?? 0),
    WorkerTier.master:
        stockpile.quantityOf(CommodityCatalog.furHats.id) +
        (projected[CommodityCatalog.furHats.id] ?? 0),
  };
}

String? industryCounselLuxuryCommodityForTier(WorkerTier tier) {
  return workerLuxuryCommodityIdForTier(tier);
}

double industryCounselScoreTrainWorker({
  required WorkerTier tier,
  required Stockpile stockpile,
  required int effectiveLabour,
  required int coreAssignedLabour,
  required Map<WorkerTier, int> sustainableTrainedCounts,
}) {
  if (tier == WorkerTier.peasant) {
    final deficit = coreAssignedLabour - effectiveLabour;
    if (deficit <= 0) return 0;
    return deficit * kIndustryCounselShortageWeight;
  }
  final luxuryId = industryCounselLuxuryCommodityForTier(tier);
  if (luxuryId == null) return 0;
  final sustainable = sustainableTrainedCounts[tier] ?? 0;
  final cap = industryCounselSoftLuxuryCapDeficitLimit(sustainable);
  final held = stockpile.quantityOf(luxuryId);
  if (held >= cap) return 0;
  final deficit = kIndustryCounselShortageThreshold - held;
  if (deficit <= 0) return 0;
  return deficit * kIndustryCounselShortageWeight;
}
