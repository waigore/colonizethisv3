import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Consumption resolution helpers.
/// SPEC/game/workers-and-population.md
/// SPEC/game/stockpiles-and-production.md

class ConsumptionResult {
  const ConsumptionResult({
    required this.stockpile,
    required this.workerPool,
    required this.totalRegiments,
    required this.fullyFedRegiments,
  });

  final Stockpile stockpile;
  final WorkerPool workerPool;
  final int totalRegiments;
  final int fullyFedRegiments;
}

/// Applies worker and basic military food consumption for one turn.
///
/// Food rules (per SPEC/game/workers-and-population.md):
/// - Peasant: 1 grain or meat
/// - Apprentice/Journeyman/Master: 1 grain + 1 meat (2 food units total)
/// - Military: treated as 2 food units per regiment (simple stub)
///
/// If food is insufficient, workers **starve** (removed from WorkerPool).
/// Peasants are removed first, then apprentices, then journeymen, then masters.
/// Luxury consumption and \"zero labour without luxuries\" are not yet
/// modelled; they can be layered on top of this food resolution.
ConsumptionResult resolveConsumption({
  required Stockpile stockpile,
  required WorkerPool workers,
  int militaryUnits = 0,
  Map<String, int> regimentCountsById = const {},
}) {
  Stockpile current = stockpile;

  int consumeFood(int required) {
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

    return required - remaining;
  }

  int feedGroup({
    required int count,
    required int foodPerUnit,
  }) {
    if (count <= 0 || foodPerUnit <= 0) return count;
    final requiredFood = count * foodPerUnit;
    final consumed = consumeFood(requiredFood);
    final fed = consumed ~/ foodPerUnit;
    return fed;
  }

  // --- Military-first feeding ---
  // Derive total regiment count and food demand. If detailed regiment counts
  // are provided, use per-type foodUpkeep from RegimentEconomyCatalog; fall
  // back to 2 food units per regiment when only [militaryUnits] is known.
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
    final consumedForMilitary = consumeFood(totalFoodDemand);
    // Approximate fully-fed regiments using average food per regiment.
    final avgFoodPerRegiment =
        (totalFoodDemand + totalRegiments - 1) ~/ totalRegiments; // ceil
    if (avgFoodPerRegiment > 0) {
      fullyFedRegiments = consumedForMilitary ~/ avgFoodPerRegiment;
      if (fullyFedRegiments > totalRegiments) {
        fullyFedRegiments = totalRegiments;
      }
    }
  }

  // --- Workers: fed from remaining food ---
  // Peasants: feed first, 1 food each.
  final fedPeasants = feedGroup(count: workers.peasants, foodPerUnit: 1);

  // Apprentices: 2 food each.
  final fedApprentices = feedGroup(count: workers.apprentices, foodPerUnit: 2);

  // Journeymen: 2 food each.
  final fedJourneymen = feedGroup(count: workers.journeymen, foodPerUnit: 2);

  // Masters: 2 food each.
  final fedMasters = feedGroup(count: workers.masters, foodPerUnit: 2);

  final updatedWorkers = WorkerPool(
    peasants: fedPeasants,
    apprentices: fedApprentices,
    journeymen: fedJourneymen,
    masters: fedMasters,
  );

  return ConsumptionResult(
    stockpile: current,
    workerPool: updatedWorkers,
    totalRegiments: totalRegiments,
    fullyFedRegiments: fullyFedRegiments,
  );
}

