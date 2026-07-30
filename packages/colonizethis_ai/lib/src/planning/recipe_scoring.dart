// Recipe feasibility and scoring for economy planning. SPEC/ai/economy-planner.md.
//
// Re-exports shared industry counsel scoring from colonizethis_economy so AI
// and human counsel stay aligned on core signals (Refs #4189 / #4190).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'growth_stage.dart' show GrowthStage;
import 'scored_candidate.dart';

/// Shortage target below which we consider a commodity "needed".
const int kShortageThreshold = kIndustryCounselShortageThreshold;

/// Weight for shortage component in recipe score.
const double kShortageWeight = kIndustryCounselShortageWeight;

/// Weight for chain/luxury value.
const double kChainWeight = kIndustryCounselChainWeight;

/// Weight for agenda/personality modifier.
const double kAgendaWeight = kIndustryCounselAgendaWeight;

const int kVeryLargeRuns = kIndustryCounselVeryLargeRuns;

typedef ScoredRecipe = ScoredCandidate<ProductionRecipe>;

/// Max full runs of [recipe] allowed by [stockpile] inputs and [remainingLabour].
int feasibleRuns({
  required ProductionRecipe recipe,
  required Stockpile stockpile,
  required int remainingLabour,
}) {
  return industryCounselFeasibleRuns(
    recipe: recipe,
    stockpile: stockpile,
    remainingLabour: remainingLabour,
  );
}

/// Deterministic score for ranking recipe candidates.
double scoreRecipe({
  required ProductionRecipe recipe,
  required Stockpile stockpile,
  required WorkerPool workers,
  required String agendaId,
}) {
  return industryCounselScoreRecipe(
    recipe: recipe,
    stockpile: stockpile,
    workers: workers,
    agendaId: agendaId,
  );
}

/// Growth-stage dampen-and-bias score. SPEC/ai/growth-stage-planner.md.
double stageScaledRecipeScore({
  required ProductionRecipe recipe,
  required Stockpile stockpile,
  required WorkerPool workers,
  required String agendaId,
  required GrowthStage stage,
}) {
  final counselStage = IndustryCounselGrowthStage(
    workerGrowthPriority: stage.workerGrowthPriority,
    infrastructurePriority: stage.infrastructurePriority,
    resourceProductionPriority: stage.resourceProductionPriority,
    militaryPriority: stage.militaryPriority,
  );
  return industryCounselStageScaledRecipeScore(
    recipe: recipe,
    stockpile: stockpile,
    workers: workers,
    agendaId: agendaId,
    stage: counselStage,
  );
}
