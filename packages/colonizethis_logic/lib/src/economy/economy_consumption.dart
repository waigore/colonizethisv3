import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'worker_economy.dart';

final _log = logicLogger();

/// Thrown when [resolveConsumption] sees a ship type id not in [ShipEconomyCatalog].
/// SPEC/game/workers-and-population.md (invalid fleet data).
class ConsumptionUnknownShipTypeException implements Exception {
  ConsumptionUnknownShipTypeException(this.shipTypeId);
  final String shipTypeId;

  @override
  String toString() =>
      'ConsumptionUnknownShipTypeException: unknown ship type $shipTypeId';
}

/// Consumption resolution helpers.
/// SPEC/game/workers-and-population.md
/// SPEC/game/stockpiles-and-production.md

class ConsumptionResult {
  const ConsumptionResult({
    required this.stockpile,
    required this.workerPool,
    required this.totalRegiments,
    required this.fullyFedRegiments,
    required this.totalShips,
    required this.fullyFedShips,
  });

  final Stockpile stockpile;
  final WorkerPool workerPool;
  final int totalRegiments;
  final int fullyFedRegiments;
  final int totalShips;
  final int fullyFedShips;
}

/// Applies land military, navy, and worker food consumption for one turn.
///
/// Food rules (per SPEC/game/workers-and-population.md):
/// - Peasant: 1 grain or meat
/// - Apprentice/Journeyman/Master: 1 grain + 1 meat (2 food units total)
/// - Land military: per-type `foodUpkeep` from [RegimentEconomyCatalog], or 2/regiment
///   when only [militaryUnits] is set
/// - Navy: per-type `foodUpkeep` from [ShipEconomyCatalog] (2 per ship in default catalog)
///
/// Order: land military → navy → workers. If food is insufficient, workers **starve**
/// (removed from WorkerPool). Peasants first, then apprentices, journeymen, masters.
/// After food and starvation, trained workers consume tier luxuries
/// (refinedSugar/cigars/furHats) per SPEC/game/workers-and-population.md.
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
  for (final id in shipCountsById.keys) {
    if (!ShipEconomyCatalog.byId.containsKey(id)) {
      throw ConsumptionUnknownShipTypeException(id);
    }
  }

  Stockpile current = stockpile;

  int feedGroup({required int count, required int foodPerUnit}) {
    if (count <= 0 || foodPerUnit <= 0) return count;
    final requiredFood = count * foodPerUnit;
    final (nextStockpile, consumed) = consumeFoodUnits(
      stockpile: current,
      required: requiredFood,
    );
    current = nextStockpile;
    final fed = consumed ~/ foodPerUnit;
    return fed;
  }

  // --- Land military feeding ---
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

  // --- Navy (after land military, before workers) ---
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

  // --- Workers: fed from remaining food ---
  final fedPeasants = feedGroup(count: workers.peasants, foodPerUnit: 1);
  final fedApprentices = feedGroup(count: workers.apprentices, foodPerUnit: 2);
  final fedJourneymen = feedGroup(count: workers.journeymen, foodPerUnit: 2);
  final fedMasters = feedGroup(count: workers.masters, foodPerUnit: 2);

  final updatedWorkers = WorkerPool(
    peasants: fedPeasants,
    apprentices: fedApprentices,
    journeymen: fedJourneymen,
    masters: fedMasters,
  );

  current = deductLuxuryForWorkers(stockpile: current, workers: updatedWorkers);

  _log.d(
    'logic: consumption totalRegiments=$totalRegiments fullyFedRegiments=$fullyFedRegiments '
    'totalShips=$totalShips fullyFedShips=$fullyFedShips',
  );
  return ConsumptionResult(
    stockpile: current,
    workerPool: updatedWorkers,
    totalRegiments: totalRegiments,
    fullyFedRegiments: fullyFedRegiments,
    totalShips: totalShips,
    fullyFedShips: fullyFedShips,
  );
}
