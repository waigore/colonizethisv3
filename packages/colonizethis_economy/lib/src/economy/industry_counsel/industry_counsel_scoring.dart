/// Recipe feasibility and scoring for industry counsel (AI core path).
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'industry_counsel_constants.dart';
import 'industry_counsel_growth_stage.dart';
import 'industry_counsel_types.dart';

int industryCounselFeasibleRuns({
  required ProductionRecipe recipe,
  required Stockpile stockpile,
  required int remainingLabour,
}) {
  if (recipe.labourPerOutput <= 0) return 0;
  var maxByInputs = kIndustryCounselVeryLargeRuns;
  for (final entry in recipe.inputQuantities.entries) {
    final have = stockpile.quantityOf(entry.key);
    final need = entry.value;
    if (need <= 0) continue;
    final runs = have ~/ need;
    if (runs < maxByInputs) maxByInputs = runs;
  }
  if (maxByInputs <= 0) return 0;
  final maxByLabour = remainingLabour ~/ recipe.labourPerOutput;
  if (maxByLabour <= 0) return 0;
  return maxByInputs < maxByLabour ? maxByInputs : maxByLabour;
}

double industryCounselScoreRecipe({
  required ProductionRecipe recipe,
  required Stockpile stockpile,
  required WorkerPool workers,
  required String agendaId,
}) {
  final outputId = recipe.outputCommodityId;
  final have = stockpile.quantityOf(outputId);

  final shortage = have < kIndustryCounselShortageThreshold
      ? (kIndustryCounselShortageThreshold - have).toDouble()
      : 0.0;

  final chain = _recipeChainScore(outputId, workers);
  final agenda = _recipeAgendaScore(agendaId, outputId);

  return shortage * kIndustryCounselShortageWeight +
      chain * kIndustryCounselChainWeight +
      agenda * kIndustryCounselAgendaWeight;
}

double industryCounselStageScaledRecipeScore({
  required ProductionRecipe recipe,
  required Stockpile stockpile,
  required WorkerPool workers,
  required String agendaId,
  required IndustryCounselGrowthStage stage,
}) {
  final base = industryCounselScoreRecipe(
    recipe: recipe,
    stockpile: stockpile,
    workers: workers,
    agendaId: agendaId,
  );
  final categoryPriority = industryCounselCategoryPriorityForOutput(
    recipe.outputCommodityId,
    stage,
  );
  return categoryPriority *
      (base + kIndustryCounselGrowthStagePriorityBias);
}

double _recipeChainScore(String outputId, WorkerPool workers) {
  if (outputId == CommodityCatalog.refinedSugar.id) {
    return workers.apprentices > 0 ? 2.0 : 1.0;
  }
  if (outputId == CommodityCatalog.cigars.id) {
    return workers.journeymen > 0 ? 2.0 : 1.0;
  }
  if (outputId == CommodityCatalog.furHats.id) {
    return workers.masters > 0 ? 2.0 : 1.0;
  }
  if (outputId == CommodityCatalog.fabric.id ||
      outputId == CommodityCatalog.castIron.id) {
    return outputId == CommodityCatalog.fabric.id ? 0.5 : 0.8;
  }
  if (outputId == CommodityCatalog.lumber.id) {
    return 0.8;
  }
  return 0.0;
}

double _recipeAgendaScore(String agendaId, String outputId) {
  if (agendaId.isEmpty) return 0.0;
  if (agendaId == 'warmonger' &&
      (outputId == CommodityCatalog.castIron.id ||
          outputId == CommodityCatalog.lumber.id)) {
    return 1.0;
  }
  if (agendaId != 'industrial_trader' && agendaId != 'merchant') {
    return 0.0;
  }
  if (outputId == CommodityCatalog.fabric.id ||
      outputId == CommodityCatalog.refinedSugar.id ||
      outputId == CommodityCatalog.cigars.id ||
      outputId == CommodityCatalog.furHats.id) {
    return 0.5;
  }
  return 0.0;
}

IndustryCounselReasonKey industryCounselPrimaryReasonForRecipeScore({
  required ProductionRecipe recipe,
  required Stockpile stockpile,
  required WorkerPool workers,
}) {
  final outputId = recipe.outputCommodityId;
  final have = stockpile.quantityOf(outputId);
  if (have < kIndustryCounselShortageThreshold) {
    return IndustryCounselReasonKey.outputShortage;
  }
  if (_recipeChainScore(outputId, workers) > 0) {
    return IndustryCounselReasonKey.chainLuxury;
  }
  return IndustryCounselReasonKey.outputShortage;
}
