import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Per-turn food consumption phases used by [resolveConsumption].
///
/// Each phase is a pure, stockpile-in/stockpile-out function so the land
/// military, navy, and worker stages can be unit-tested in isolation.
/// SPEC/game/workers-and-population.md
/// SPEC/game/stockpiles-and-production.md

/// Thrown when consumption sees a ship type id not in [ShipEconomyCatalog].
/// SPEC/game/workers-and-population.md (invalid fleet data).
class ConsumptionUnknownShipTypeException implements Exception {
  ConsumptionUnknownShipTypeException(this.shipTypeId);
  final String shipTypeId;

  @override
  String toString() =>
      'ConsumptionUnknownShipTypeException: unknown ship type $shipTypeId';
}

/// Consumes up to [required] food units (grain then meat) from [stockpile].
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

/// Land military food phase.
///
/// Demand is per-type `foodUpkeep` from [RegimentEconomyCatalog] when
/// [regimentCountsById] is set, else 2 food per regiment when only
/// [militaryUnits] is given. Returns (updatedStockpile, totalRegiments,
/// fullyFedRegiments).
(Stockpile, int, int) consumeMilitaryFood({
  required Stockpile stockpile,
  int militaryUnits = 0,
  Map<String, int> regimentCountsById = const {},
}) {
  var current = stockpile;
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
    final (nextStockpile, consumed) = consumeFoodUnits(
      stockpile: current,
      required: totalFoodDemand,
    );
    current = nextStockpile;
    final avgFoodPerRegiment =
        (totalFoodDemand + totalRegiments - 1) ~/ totalRegiments;
    if (avgFoodPerRegiment > 0) {
      fullyFedRegiments = consumed ~/ avgFoodPerRegiment;
      if (fullyFedRegiments > totalRegiments) {
        fullyFedRegiments = totalRegiments;
      }
    }
  }

  return (current, totalRegiments, fullyFedRegiments);
}

/// Navy food phase. Demand is per-type `foodUpkeep` from [ShipEconomyCatalog].
/// Returns (updatedStockpile, totalShips, fullyFedShips).
///
/// Throws [ConsumptionUnknownShipTypeException] if [shipCountsById] contains a
/// type id not present in [ShipEconomyCatalog]; validation runs before any food
/// is deducted.
(Stockpile, int, int) consumeNavyFood({
  required Stockpile stockpile,
  Map<String, int> shipCountsById = const {},
}) {
  for (final id in shipCountsById.keys) {
    if (!ShipEconomyCatalog.byId.containsKey(id)) {
      throw ConsumptionUnknownShipTypeException(id);
    }
  }

  var current = stockpile;
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
    final (nextStockpile, consumed) = consumeFoodUnits(
      stockpile: current,
      required: totalNavyFoodDemand,
    );
    current = nextStockpile;
    final avgFoodPerShip = (totalNavyFoodDemand + totalShips - 1) ~/ totalShips;
    if (avgFoodPerShip > 0) {
      fullyFedShips = consumed ~/ avgFoodPerShip;
      if (fullyFedShips > totalShips) fullyFedShips = totalShips;
    }
  }

  return (current, totalShips, fullyFedShips);
}

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

  final fedMasters = feedGroup(count: workers.masters, foodPerUnit: 2);
  final fedJourneymen = feedGroup(count: workers.journeymen, foodPerUnit: 2);
  final fedApprentices = feedGroup(count: workers.apprentices, foodPerUnit: 2);
  final fedPeasants = feedGroup(count: workers.peasants, foodPerUnit: 1);

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
