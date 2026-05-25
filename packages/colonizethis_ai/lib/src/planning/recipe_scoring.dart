// Recipe feasibility and scoring for economy planning. SPEC/ai/economy-planner.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Shortage target below which we consider a commodity "needed".
const int kShortageThreshold = 8;

/// Weight for shortage component in recipe score.
const double kShortageWeight = 2.0;

/// Weight for chain/luxury value.
const double kChainWeight = 1.0;

/// Weight for agenda/personality modifier.
const double kAgendaWeight = 0.5;

const int kVeryLargeRuns = 999999;

/// A production recipe with its computed ranking score.
class ScoredRecipe {
  const ScoredRecipe({required this.recipe, required this.score});

  final ProductionRecipe recipe;
  final double score;
}

/// Max full runs of [recipe] allowed by [stockpile] inputs and [remainingLabour].
int feasibleRuns({
  required ProductionRecipe recipe,
  required Stockpile stockpile,
  required int remainingLabour,
}) {
  if (recipe.labourPerOutput <= 0) return 0;
  var maxByInputs = kVeryLargeRuns;
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

/// Deterministic score for ranking recipe candidates.
double scoreRecipe({
  required ProductionRecipe recipe,
  required Stockpile stockpile,
  required WorkerPool workers,
  required String agendaId,
}) {
  final outputId = recipe.outputCommodityId;
  final have = stockpile.quantityOf(outputId);

  final shortage = have < kShortageThreshold
      ? (kShortageThreshold - have).toDouble()
      : 0.0;

  final chain = _recipeChainScore(outputId, workers);
  final agenda = _recipeAgendaScore(agendaId, outputId);

  return shortage * kShortageWeight +
      chain * kChainWeight +
      agenda * kAgendaWeight;
}

/// Chain value: outputs that feed other recipes or are luxuries.
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
  if (outputId == CommodityCatalog.lumber.id ||
      outputId == CommodityCatalog.castIron.id) {
    return 0.8;
  }
  if (outputId == CommodityCatalog.fabric.id) {
    return 0.5;
  }
  return 0.0;
}

/// Agenda: warmonger favours military-related; industrial_trader / merchant favour trade goods.
double _recipeAgendaScore(String agendaId, String outputId) {
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
