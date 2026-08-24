import 'package:colonizethis_models/colonizethis_models.dart';

import 'economy_consumption_food_units.dart';
import 'economy_worker_consumption_rates.dart';

/// Worker food-fed counts per tier, in priority order
/// Masters → Journeymen → Apprentices → Peasants.
typedef WorkerFoodFedCounts = ({
  Stockpile stockpile,
  int fedMasters,
  int fedJourneymen,
  int fedApprentices,
  int fedPeasants,
});

/// Worker food phase. Feeds trained tiers (2 food) then peasants (1 food) in
/// priority order, returning how many of each tier received food. Workers that
/// cannot be fed stay in the pool (on strike) and are simply not counted here.
WorkerFoodFedCounts consumeWorkerFood({
  required Stockpile stockpile,
  required WorkerPool workers,
}) {
  var current = stockpile;

  int feedGroup({required int count, required int foodPerUnit}) {
    if (count <= 0 || foodPerUnit <= 0) return 0;
    final requiredFood = count * foodPerUnit;
    final (nextStockpile, consumed) = consumeFoodUnits(
      stockpile: current,
      required: requiredFood,
    );
    current = nextStockpile;
    return consumed ~/ foodPerUnit;
  }

  final fedMasters = feedGroup(
    count: workers.masters,
    foodPerUnit: workerFoodPerUnitForTier(WorkerTier.master),
  );
  final fedJourneymen = feedGroup(
    count: workers.journeymen,
    foodPerUnit: workerFoodPerUnitForTier(WorkerTier.journeyman),
  );
  final fedApprentices = feedGroup(
    count: workers.apprentices,
    foodPerUnit: workerFoodPerUnitForTier(WorkerTier.apprentice),
  );
  final fedPeasants = feedGroup(
    count: workers.peasants,
    foodPerUnit: workerFoodPerUnitForTier(WorkerTier.peasant),
  );

  return (
    stockpile: current,
    fedMasters: fedMasters,
    fedJourneymen: fedJourneymen,
    fedApprentices: fedApprentices,
    fedPeasants: fedPeasants,
  );
}

/// Luxury phase for a single trained tier. Deducts up to [foodFedCount] units of
/// [luxuryId] and returns (updatedStockpile, tierWorkersWithLuxury). Only
/// food-fed trained workers consume luxury; partial supply caps the luxury count
/// (luxury strike).
(Stockpile, int) assignWorkerLuxury({
  required Stockpile stockpile,
  required int foodFedCount,
  required CommodityId luxuryId,
}) {
  if (foodFedCount <= 0) {
    return (stockpile, 0);
  }
  final available = stockpile.quantityOf(luxuryId);
  final assign = foodFedCount <= available ? foodFedCount : available;
  if (assign <= 0) {
    return (stockpile, 0);
  }
  return (stockpile.applyDelta(luxuryId, -assign), assign);
}
