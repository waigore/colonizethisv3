import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared worker food and luxury rates used by consumption phases and UI gists.
/// SPEC/game/workers-and-population.md

/// Food units each peasant consumes per turn in [consumeWorkerFood].
const int kWorkerFoodPerPeasant = 1;

/// Food units each trained worker consumes per turn in [consumeWorkerFood].
const int kWorkerFoodPerTrainedTier = 2;

/// Grain then meat — the same order [consumeFoodUnits] deducts.
List<String> get workerFoodCommodityIdsInConsumeOrder => [
  CommodityCatalog.grain.id,
  CommodityCatalog.meat.id,
];

/// Per-tier food units used by [consumeWorkerFood].
int workerFoodPerUnitForTier(WorkerTier tier) {
  switch (tier) {
    case WorkerTier.peasant:
      return kWorkerFoodPerPeasant;
    case WorkerTier.apprentice:
    case WorkerTier.journeyman:
    case WorkerTier.master:
      return kWorkerFoodPerTrainedTier;
  }
}

/// Labour units per turn for one worker at [tier].
int workerLabourPerTurnForTier(WorkerTier tier) {
  switch (tier) {
    case WorkerTier.peasant:
      return WorkerPool.labourPerPeasantTurn;
    case WorkerTier.apprentice:
      return WorkerPool.labourPerApprenticeTurn;
    case WorkerTier.journeyman:
      return WorkerPool.labourPerJourneymanTurn;
    case WorkerTier.master:
      return WorkerPool.labourPerMasterTurn;
  }
}

/// Headcount in [pool] for [tier].
int workerPoolCountForTier(WorkerPool pool, WorkerTier tier) {
  switch (tier) {
    case WorkerTier.peasant:
      return pool.peasants;
    case WorkerTier.apprentice:
      return pool.apprentices;
    case WorkerTier.journeyman:
      return pool.journeymen;
    case WorkerTier.master:
      return pool.masters;
  }
}

/// Working (idle-labour) count for [tier] in [idle].
int workerIdleCountForTier(WorkerIdleCounts idle, WorkerTier tier) {
  switch (tier) {
    case WorkerTier.peasant:
      return idle.peasants;
    case WorkerTier.apprentice:
      return idle.apprentices;
    case WorkerTier.journeyman:
      return idle.journeymen;
    case WorkerTier.master:
      return idle.masters;
  }
}

/// Luxury commodity id consumed by [assignWorkerLuxury] for [tier].
///
/// Peasant has no luxury. Trained ids match [allocateConsumption].
String? workerLuxuryCommodityIdForTier(WorkerTier tier) {
  switch (tier) {
    case WorkerTier.peasant:
      return null;
    case WorkerTier.apprentice:
      return CommodityCatalog.refinedSugar.id;
    case WorkerTier.journeyman:
      return CommodityCatalog.cigars.id;
    case WorkerTier.master:
      return CommodityCatalog.furHats.id;
  }
}
