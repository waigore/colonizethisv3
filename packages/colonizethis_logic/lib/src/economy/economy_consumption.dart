import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

final _log = logicLogger();

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
  });

  final Stockpile stockpile;

  /// Headcounts unchanged by consumption (workers are not removed).
  final WorkerPool workerPool;

  /// Idle workers for Production this turn (fed + luxury when required).
  final WorkerIdleCounts idleLabour;

  final int totalRegiments;
  final int fullyFedRegiments;
}

/// Same allocation rules as [resolveConsumption]; returns only [WorkerIdleCounts]
/// (e.g. UI / AI preview). Does not mutate [stockpile].
WorkerIdleCounts previewWorkerIdleLabour({
  required Stockpile stockpile,
  required WorkerPool workers,
  int militaryUnits = 0,
  Map<String, int> regimentCountsById = const {},
}) {
  return _allocateConsumption(
    stockpile: stockpile,
    workers: workers,
    militaryUnits: militaryUnits,
    regimentCountsById: regimentCountsById,
  ).idleLabour;
}

/// Applies worker and basic military food consumption for one turn.
///
/// Food rules (per SPEC/game/workers-and-population.md):
/// - Peasant: 1 grain or meat
/// - Apprentice/Journeyman/Master: 2 food units (implementation: grain then meat)
/// - Military: per [RegimentEconomyCatalog.foodUpkeep] or 2 food units per regiment stub
///
/// Worker food priority: **Masters → Journeymen → Apprentices → Peasants**.
/// Insufficient food: worker **stays in pool** but is **on strike** (no labour).
/// Luxury is deducted only for food-fed trained workers who receive a unit;
/// food-unfed trained workers consume **no** luxury.
ConsumptionResult resolveConsumption({
  required Stockpile stockpile,
  required WorkerPool workers,
  int militaryUnits = 0,
  Map<String, int> regimentCountsById = const {},
}) {
  final alloc = _allocateConsumption(
    stockpile: stockpile,
    workers: workers,
    militaryUnits: militaryUnits,
    regimentCountsById: regimentCountsById,
  );
  _log.d(
    'logic: consumption totalRegiments=${alloc.totalRegiments} '
    'fullyFedRegiments=${alloc.fullyFedRegiments} '
    'idlePeasants=${alloc.idleLabour.peasants}',
  );
  return ConsumptionResult(
    stockpile: alloc.stockpile,
    workerPool: workers,
    idleLabour: alloc.idleLabour,
    totalRegiments: alloc.totalRegiments,
    fullyFedRegiments: alloc.fullyFedRegiments,
  );
}

({Stockpile stockpile, WorkerIdleCounts idleLabour, int totalRegiments, int fullyFedRegiments})
_allocateConsumption({
  required Stockpile stockpile,
  required WorkerPool workers,
  int militaryUnits = 0,
  Map<String, int> regimentCountsById = const {},
}) {
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

  // Masters → Journeymen → Apprentices → Peasants
  final fedMasters = feedGroup(count: workers.masters, foodPerUnit: 2);
  final fedJourneymen = feedGroup(count: workers.journeymen, foodPerUnit: 2);
  final fedApprentices = feedGroup(count: workers.apprentices, foodPerUnit: 2);
  final fedPeasants = feedGroup(count: workers.peasants, foodPerUnit: 1);

  final furHatsId = CommodityCatalog.furHats.id;
  final cigarsId = CommodityCatalog.cigars.id;
  final sugarId = CommodityCatalog.refinedSugar.id;

  final (s1, idleMasters) = _assignLuxuryForFoodFedTier(
    stockpile: current,
    foodFedCount: fedMasters,
    luxuryId: furHatsId,
  );
  current = s1;

  final (s2, idleJourneymen) = _assignLuxuryForFoodFedTier(
    stockpile: current,
    foodFedCount: fedJourneymen,
    luxuryId: cigarsId,
  );
  current = s2;

  final (s3, idleApprentices) = _assignLuxuryForFoodFedTier(
    stockpile: current,
    foodFedCount: fedApprentices,
    luxuryId: sugarId,
  );
  current = s3;

  final idleLabour = WorkerIdleCounts(
    peasants: fedPeasants,
    apprentices: idleApprentices,
    journeymen: idleJourneymen,
    masters: idleMasters,
  );

  return (
    stockpile: current,
    idleLabour: idleLabour,
    totalRegiments: totalRegiments,
    fullyFedRegiments: fullyFedRegiments,
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
  final assign = foodFedCount < available ? foodFedCount : available;
  if (assign <= 0) {
    return (stockpile, 0);
  }
  return (stockpile.applyDelta(luxuryId, -assign), assign);
}
