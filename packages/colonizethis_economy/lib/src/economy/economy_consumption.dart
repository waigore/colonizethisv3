import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'economy_consumption_phases.dart';

export 'economy_consumption_phases.dart'
    show ConsumptionUnknownShipTypeException, consumeFoodUnits;

/// Consumption resolution helpers.
/// SPEC/game/workers-and-population.md
/// SPEC/game/stockpiles-and-production.md

class ConsumptionResult {
  const ConsumptionResult({
    required this.stockpile,
    required this.workerPool,
    required this.idleLabour,
    required this.totalRegiments,
    required this.fullyFedRegiments,
    required this.totalShips,
    required this.fullyFedShips,
  });

  final Stockpile stockpile;

  /// Headcounts unchanged by consumption (workers are not removed).
  final WorkerPool workerPool;

  /// Workers contributing labour this turn (fed + luxury when required).
  final WorkerIdleCounts idleLabour;

  final int totalRegiments;
  final int fullyFedRegiments;
  final int totalShips;
  final int fullyFedShips;
}

/// Same allocation rules as [resolveConsumption]; returns only [WorkerIdleCounts]
/// (e.g. UI / AI preview). Does not mutate [stockpile].
WorkerIdleCounts previewWorkerIdleLabour({
  required Stockpile stockpile,
  required WorkerPool workers,
  int militaryUnits = 0,
  Map<String, int> regimentCountsById = const {},
  Map<String, int> shipCountsById = const {},
}) {
  return _allocateConsumption(
    stockpile: stockpile,
    workers: workers,
    militaryUnits: militaryUnits,
    regimentCountsById: regimentCountsById,
    shipCountsById: shipCountsById,
  ).idleLabour;
}

/// Applies land military, navy, and worker food consumption for one turn.
///
/// Food rules (per SPEC/game/workers-and-population.md):
/// - Peasant: 1 grain or meat
/// - Apprentice/Journeyman/Master: 2 food units (grain then meat)
/// - Land military: per-type `foodUpkeep` from [RegimentEconomyCatalog], or 2/regiment
///   when only [militaryUnits] is set
/// - Navy: per-type `foodUpkeep` from [ShipEconomyCatalog]
///
/// Order: land military → navy → workers. Worker food priority:
/// **Masters → Journeymen → Apprentices → Peasants**. Insufficient food: worker
/// **stays in pool** but is **on strike** (no labour). Luxury is deducted only
/// for food-fed trained workers who receive a unit; food-unfed trained workers
/// consume **no** luxury.
///
/// Throws [ConsumptionUnknownShipTypeException] if [shipCountsById] contains a type
/// id not present in [ShipEconomyCatalog].
ConsumptionResult resolveConsumption({
  required Stockpile stockpile,
  required WorkerPool workers,
  int militaryUnits = 0,
  Map<String, int> regimentCountsById = const {},
  Map<String, int> shipCountsById = const {},
}) {
  final alloc = _allocateConsumption(
    stockpile: stockpile,
    workers: workers,
    militaryUnits: militaryUnits,
    regimentCountsById: regimentCountsById,
    shipCountsById: shipCountsById,
  );
  economyLog.d(
    'consumption totalRegiments=${alloc.totalRegiments} '
    'fullyFedRegiments=${alloc.fullyFedRegiments} '
    'totalShips=${alloc.totalShips} fullyFedShips=${alloc.fullyFedShips} '
    'idlePeasants=${alloc.idleLabour.peasants}',
  );
  return ConsumptionResult(
    stockpile: alloc.stockpile,
    workerPool: workers,
    idleLabour: alloc.idleLabour,
    totalRegiments: alloc.totalRegiments,
    fullyFedRegiments: alloc.fullyFedRegiments,
    totalShips: alloc.totalShips,
    fullyFedShips: alloc.fullyFedShips,
  );
}

({
  Stockpile stockpile,
  WorkerIdleCounts idleLabour,
  int totalRegiments,
  int fullyFedRegiments,
  int totalShips,
  int fullyFedShips,
})
_allocateConsumption({
  required Stockpile stockpile,
  required WorkerPool workers,
  int militaryUnits = 0,
  Map<String, int> regimentCountsById = const {},
  Map<String, int> shipCountsById = const {},
}) {
  // Order: land military → navy → workers (food), then per-tier luxury.
  final (afterMilitary, totalRegiments, fullyFedRegiments) =
      consumeMilitaryFood(
        stockpile: stockpile,
        militaryUnits: militaryUnits,
        regimentCountsById: regimentCountsById,
      );

  final (afterNavy, totalShips, fullyFedShips) = consumeNavyFood(
    stockpile: afterMilitary,
    shipCountsById: shipCountsById,
  );

  final fed = consumeWorkerFood(stockpile: afterNavy, workers: workers);
  var current = fed.stockpile;

  // Masters → Journeymen → Apprentices → Peasants
  final (s1, mastersWithLuxury) = assignWorkerLuxury(
    stockpile: current,
    foodFedCount: fed.fedMasters,
    luxuryId: CommodityCatalog.furHats.id,
  );
  current = s1;

  final (s2, journeymenWithLuxury) = assignWorkerLuxury(
    stockpile: current,
    foodFedCount: fed.fedJourneymen,
    luxuryId: CommodityCatalog.cigars.id,
  );
  current = s2;

  final (s3, apprenticesWithLuxury) = assignWorkerLuxury(
    stockpile: current,
    foodFedCount: fed.fedApprentices,
    luxuryId: CommodityCatalog.refinedSugar.id,
  );
  current = s3;

  final idleLabour = WorkerIdleCounts(
    peasants: fed.fedPeasants,
    apprentices: apprenticesWithLuxury,
    journeymen: journeymenWithLuxury,
    masters: mastersWithLuxury,
  );

  return (
    stockpile: current,
    idleLabour: idleLabour,
    totalRegiments: totalRegiments,
    fullyFedRegiments: fullyFedRegiments,
    totalShips: totalShips,
    fullyFedShips: fullyFedShips,
  );
}
