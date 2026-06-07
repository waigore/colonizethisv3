import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Thrown when [resolveConsumption] sees a ship type id not in [ShipEconomyCatalog].
/// SPEC/game/workers-and-population.md (invalid fleet data).
class ConsumptionUnknownShipTypeException implements Exception {
  ConsumptionUnknownShipTypeException(this.shipTypeId);
  final String shipTypeId;

  @override
  String toString() =>
      'ConsumptionUnknownShipTypeException: unknown ship type $shipTypeId';
}

/// Consumes up to [required] food units (grain/meat) from [stockpile].
/// Returns a record of (updatedStockpile, unitsConsumed).
(Stockpile, int) consumeFoodUnits({
  required Stockpile stockpile,
  required int required,
}) {
  var current = stockpile;
  var remaining = required;
  final grainId = CommodityCatalog.grain.id;
  final meatId = CommodityCatalog.meat.id;

  final grainAvailable = current.quantityOf(grainId);
  final meatAvailable = current.quantityOf(meatId);

  final grainToUse = remaining <= 0
      ? 0
      : remaining <= grainAvailable
      ? remaining
      : grainAvailable;
  if (grainToUse > 0) {
    current = current.applyDelta(grainId, -grainToUse);
    remaining -= grainToUse;
  }

  final meatToUse = remaining <= 0
      ? 0
      : remaining <= meatAvailable
      ? remaining
      : meatAvailable;
  if (meatToUse > 0) {
    current = current.applyDelta(meatId, -meatToUse);
    remaining -= meatToUse;
  }

  return (current, required - remaining);
}

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
  for (final id in shipCountsById.keys) {
    if (!ShipEconomyCatalog.byId.containsKey(id)) {
      throw ConsumptionUnknownShipTypeException(id);
    }
  }

  Stockpile current = stockpile;

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

  int totalRegiments = 0;
  int totalFoodDemand = 0;

  if (regimentCountsById.isNotEmpty) {
    for (final entry in regimentCountsById.entries) {
      final count = entry.value;
      if (count <= 0) continue;
      totalRegiments += count;
      final econ = RegimentEconomyCatalog.byId[entry.key];
      final perRegimentFood = econ?.foodUpkeep ?? 0;
      if (perRegimentFood > 0) {
        totalFoodDemand += perRegimentFood * count;
      }
    }
  } else if (militaryUnits > 0) {
    totalRegiments = militaryUnits;
    totalFoodDemand = militaryUnits * 2;
  }

  int fullyFedRegiments = 0;
  if (totalFoodDemand > 0 && totalRegiments > 0) {
    final (nextStockpile, consumedForMilitary) = consumeFoodUnits(
      stockpile: current,
      required: totalFoodDemand,
    );
    current = nextStockpile;
    final avgFoodPerRegiment =
        (totalFoodDemand + totalRegiments - 1) ~/ totalRegiments;
    if (avgFoodPerRegiment > 0) {
      fullyFedRegiments = consumedForMilitary ~/ avgFoodPerRegiment;
      if (fullyFedRegiments > totalRegiments) {
        fullyFedRegiments = totalRegiments;
      }
    }
  }

  int totalShips = 0;
  int totalNavyFoodDemand = 0;
  for (final entry in shipCountsById.entries) {
    final count = entry.value;
    if (count <= 0) continue;
    totalShips += count;
    final upkeep = ShipEconomyCatalog.byId[entry.key]!.foodUpkeep;
    if (upkeep > 0) {
      totalNavyFoodDemand += upkeep * count;
    }
  }

  int fullyFedShips = 0;
  if (totalNavyFoodDemand > 0 && totalShips > 0) {
    final (nextStockpile, consumedForNavy) = consumeFoodUnits(
      stockpile: current,
      required: totalNavyFoodDemand,
    );
    current = nextStockpile;
    final avgFoodPerShip = (totalNavyFoodDemand + totalShips - 1) ~/ totalShips;
    if (avgFoodPerShip > 0) {
      fullyFedShips = consumedForNavy ~/ avgFoodPerShip;
      if (fullyFedShips > totalShips) fullyFedShips = totalShips;
    }
  }

  // Masters → Journeymen → Apprentices → Peasants
  final fedMasters = feedGroup(count: workers.masters, foodPerUnit: 2);
  final fedJourneymen = feedGroup(count: workers.journeymen, foodPerUnit: 2);
  final fedApprentices = feedGroup(count: workers.apprentices, foodPerUnit: 2);
  final fedPeasants = feedGroup(count: workers.peasants, foodPerUnit: 1);

  final furHatsId = CommodityCatalog.furHats.id;
  final cigarsId = CommodityCatalog.cigars.id;
  final sugarId = CommodityCatalog.refinedSugar.id;

  final (s1, mastersWithLuxury) = _assignLuxuryForFoodFedTier(
    stockpile: current,
    foodFedCount: fedMasters,
    luxuryId: furHatsId,
  );
  current = s1;

  final (s2, journeymenWithLuxury) = _assignLuxuryForFoodFedTier(
    stockpile: current,
    foodFedCount: fedJourneymen,
    luxuryId: cigarsId,
  );
  current = s2;

  final (s3, apprenticesWithLuxury) = _assignLuxuryForFoodFedTier(
    stockpile: current,
    foodFedCount: fedApprentices,
    luxuryId: sugarId,
  );
  current = s3;

  final idleLabour = WorkerIdleCounts(
    peasants: fedPeasants,
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

(Stockpile, int) _assignLuxuryForFoodFedTier({
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
