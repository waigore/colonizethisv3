import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'economy_consumption_phases.dart';
import 'military_navy_food_counts.dart';

/// Full turn consumption allocation: land military → navy → worker food → luxury.
/// SPEC/game/workers-and-population.md
class ConsumptionAllocation {
  const ConsumptionAllocation({
    required this.stockpile,
    required this.idleLabour,
    required this.totalRegiments,
    required this.fullyFedRegiments,
    required this.totalShips,
    required this.fullyFedShips,
    required this.fedPeasants,
    required this.fedApprentices,
    required this.fedJourneymen,
    required this.fedMasters,
    required this.apprenticesWithLuxury,
    required this.journeymenWithLuxury,
    required this.mastersWithLuxury,
    required this.militaryOrNavyConsumesFoodBeforeWorkers,
  });

  final Stockpile stockpile;
  final WorkerIdleCounts idleLabour;
  final int totalRegiments;
  final int fullyFedRegiments;
  final int totalShips;
  final int fullyFedShips;
  final int fedPeasants;
  final int fedApprentices;
  final int fedJourneymen;
  final int fedMasters;
  final int apprenticesWithLuxury;
  final int journeymenWithLuxury;
  final int mastersWithLuxury;
  final bool militaryOrNavyConsumesFoodBeforeWorkers;
}

/// Single allocation sequence for resolve, preview, and labour-readiness paths.
ConsumptionAllocation allocateConsumption({
  required Stockpile stockpile,
  required WorkerPool workers,
  MilitaryNavyFoodCounts foodCounts = const MilitaryNavyFoodCounts(),
}) {
  final grainId = CommodityCatalog.grain.id;
  final meatId = CommodityCatalog.meat.id;
  final foodBeforeMilitary =
      stockpile.quantityOf(grainId) + stockpile.quantityOf(meatId);

  final (
    afterMilitary,
    totalRegiments,
    fullyFedRegiments,
  ) = consumeMilitaryFood(
    stockpile: stockpile,
    militaryUnits: foodCounts.militaryUnits,
    regimentCountsById: foodCounts.regimentCountsById,
  );

  final (afterNavy, totalShips, fullyFedShips) = consumeNavyFood(
    stockpile: afterMilitary,
    shipCountsById: foodCounts.shipCountsById,
  );

  final foodAfterMilitaryNavy =
      afterNavy.quantityOf(grainId) + afterNavy.quantityOf(meatId);
  final militaryOrNavyConsumesFoodBeforeWorkers =
      foodBeforeMilitary > foodAfterMilitaryNavy &&
      (totalRegiments > 0 || totalShips > 0);

  final fed = consumeWorkerFood(stockpile: afterNavy, workers: workers);
  var current = fed.stockpile;

  final (s1, mastersWithLuxury) = assignWorkerLuxury(
    stockpile: current,
    foodFedCount: fed.fedMasters,
    luxuryId: workerLuxuryCommodityIdForTier(WorkerTier.master)!,
  );
  current = s1;

  final (s2, journeymenWithLuxury) = assignWorkerLuxury(
    stockpile: current,
    foodFedCount: fed.fedJourneymen,
    luxuryId: workerLuxuryCommodityIdForTier(WorkerTier.journeyman)!,
  );
  current = s2;

  final (s3, apprenticesWithLuxury) = assignWorkerLuxury(
    stockpile: current,
    foodFedCount: fed.fedApprentices,
    luxuryId: workerLuxuryCommodityIdForTier(WorkerTier.apprentice)!,
  );
  current = s3;

  final idleLabour = WorkerIdleCounts(
    peasants: fed.fedPeasants,
    apprentices: apprenticesWithLuxury,
    journeymen: journeymenWithLuxury,
    masters: mastersWithLuxury,
  );

  return ConsumptionAllocation(
    stockpile: current,
    idleLabour: idleLabour,
    totalRegiments: totalRegiments,
    fullyFedRegiments: fullyFedRegiments,
    totalShips: totalShips,
    fullyFedShips: fullyFedShips,
    fedPeasants: fed.fedPeasants,
    fedApprentices: fed.fedApprentices,
    fedJourneymen: fed.fedJourneymen,
    fedMasters: fed.fedMasters,
    apprenticesWithLuxury: apprenticesWithLuxury,
    journeymenWithLuxury: journeymenWithLuxury,
    mastersWithLuxury: mastersWithLuxury,
    militaryOrNavyConsumesFoodBeforeWorkers:
        militaryOrNavyConsumesFoodBeforeWorkers,
  );
}
