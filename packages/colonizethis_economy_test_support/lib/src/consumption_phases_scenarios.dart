// Table-driven per-phase consumption helper scenarios (Refs #3856, #3939 slice 7).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'consumption_phases_expectations.dart';
import 'consumption_scenarios.dart';

/// Back-compat alias — phase tables share [ConsumptionScenario].
typedef ConsumptionPhaseScenario = ConsumptionScenario;

/// Back-compat runner for per-phase consumption scenario tables.
void runConsumptionPhaseScenario(ConsumptionPhaseScenario scenario) =>
    runConsumptionScenario(scenario);

/// Canonical scenarios for [consumeMilitaryFood].
List<ConsumptionPhaseScenario> consumeMilitaryFoodScenarios() => [
  militaryFoodScenario(
    label: 'per-type foodUpkeep fully feeds regiments from catalog',
    stockpileGrain: 10,
    regimentCountsById: const {'pikemen': 2},
    pins: (total: 2, fullyFed: 2, grainRemaining: 6),
  ),
  militaryFoodScenario(
    label: 'militaryUnits fallback consumes 2 food per regiment',
    stockpileGrain: 10,
    militaryUnits: 3,
    pins: (total: 3, fullyFed: 3, grainRemaining: 4),
  ),
  militaryFoodScenario(
    label: 'insufficient food partially feeds regiments',
    stockpileGrain: 2,
    regimentCountsById: const {'pikemen': 3},
    pins: (total: 3, fullyFed: 1, grainRemaining: 0),
  ),
  militaryFoodScenario(
    label: 'no regiments and no military leaves stockpile unchanged',
    stockpileGrain: 5,
    pins: (total: 0, fullyFed: 0, grainRemaining: 5),
  ),
  militaryFoodScenario(
    label: 'unknown regiment id contributes count but no food demand',
    stockpileGrain: 5,
    regimentCountsById: const {'not_a_real_regiment': 2},
    pins: (total: 2, fullyFed: 0, grainRemaining: 5),
  ),
];

/// Canonical scenarios for [consumeNavyFood].
List<ConsumptionPhaseScenario> consumeNavyFoodScenarios() => [
  navyFoodScenario(
    label: 'feeds ships from catalog foodUpkeep',
    stockpileGrain: 10,
    shipCountsById: const {'carrack': 2},
    pins: (total: 2, fullyFed: 2, grainRemaining: 6),
  ),
  navyFoodScenario(
    label: 'insufficient food partially feeds ships',
    stockpileGrain: 2,
    shipCountsById: const {'carrack': 2},
    pins: (total: 2, fullyFed: 1, grainRemaining: 0),
  ),
  navyFoodScenario(
    label: 'unknown ship id throws before any food is deducted',
    stockpileGrain: 5,
    shipCountsById: const {'not_a_real_ship': 1},
    expectUnknownShipThrows: true,
  ),
  navyFoodScenario(
    label: 'empty fleet leaves stockpile unchanged',
    stockpileGrain: 5,
    pins: (total: 0, fullyFed: 0, grainRemaining: 5),
  ),
];

/// Canonical scenarios for [consumeWorkerFood].
List<ConsumptionPhaseScenario> consumeWorkerFoodScenarios() => [
  workerFoodScenario(
    label: 'feeds trained tiers (2 food) and peasants (1 food)',
    stockpile: const Stockpile().applyDelta(CommodityCatalog.grain.id, 100),
    workers: const WorkerPool(
      masters: 1,
      journeymen: 1,
      apprentices: 1,
      peasants: 2,
    ),
    expectation: const WorkerFoodConsumptionExpectation(
      fedMasters: 1,
      fedJourneymen: 1,
      fedApprentices: 1,
      fedPeasants: 2,
      grainRemaining: 92,
    ),
  ),
  workerFoodScenario(
    label: 'priority Masters→...→Peasants: masters fed before peasants',
    stockpile: const Stockpile().applyDelta(CommodityCatalog.grain.id, 2),
    workers: const WorkerPool(masters: 1, peasants: 5),
    expectation: const WorkerFoodConsumptionExpectation(
      fedMasters: 1,
      fedPeasants: 0,
      grainRemaining: 0,
    ),
  ),
  workerFoodScenario(
    label: 'grain consumed before meat',
    stockpile: const Stockpile()
        .applyDelta(CommodityCatalog.grain.id, 2)
        .applyDelta(CommodityCatalog.meat.id, 10),
    workers: const WorkerPool(apprentices: 2),
    expectation: const WorkerFoodConsumptionExpectation(
      fedApprentices: 2,
      grainRemaining: 0,
      meatRemaining: 8,
    ),
  ),
  workerFoodScenario(
    label: 'no food leaves all tiers on strike',
    stockpile: const Stockpile(),
    workers: const WorkerPool(masters: 1, peasants: 2),
    expectation: const WorkerFoodConsumptionExpectation(
      fedMasters: 0,
      fedPeasants: 0,
    ),
  ),
];

/// Canonical scenarios for [assignWorkerLuxury].
List<ConsumptionPhaseScenario> assignWorkerLuxuryScenarios() => [
  workerLuxuryScenario(
    label: 'assigns one luxury per food-fed worker when supply suffices',
    stockpile: const Stockpile().applyDelta(
      CommodityCatalog.refinedSugar.id,
      5,
    ),
    foodFedCount: 3,
    pins: (withLuxury: 3, sugarRemaining: 2),
  ),
  workerLuxuryScenario(
    label: 'luxury strike: short supply caps count and deducts what exists',
    stockpile: const Stockpile().applyDelta(
      CommodityCatalog.refinedSugar.id,
      1,
    ),
    foodFedCount: 3,
    pins: (withLuxury: 1, sugarRemaining: 0),
  ),
  workerLuxuryScenario(
    label: 'no food-fed workers deducts nothing',
    stockpile: const Stockpile().applyDelta(
      CommodityCatalog.refinedSugar.id,
      5,
    ),
    foodFedCount: 0,
    pins: (withLuxury: 0, sugarRemaining: 5),
  ),
  workerLuxuryScenario(
    label: 'no luxury available deducts nothing',
    stockpile: const Stockpile(),
    foodFedCount: 3,
    pins: (withLuxury: 0, sugarRemaining: 0),
  ),
];

/// Canonical scenarios for [consumeFoodUnits].
List<ConsumptionPhaseScenario> consumeFoodUnitsScenarios() => [
  foodUnitsScenario(
    label: 'grain then meat, returns consumed amount',
    stockpile: const Stockpile()
        .applyDelta(CommodityCatalog.grain.id, 3)
        .applyDelta(CommodityCatalog.meat.id, 5),
    required: 6,
    pins: (consumed: 6, grainRemaining: 0, meatRemaining: 2),
  ),
  foodUnitsScenario(
    label: 'caps consumed at available when demand exceeds supply',
    stockpile: const Stockpile().applyDelta(CommodityCatalog.grain.id, 2),
    required: 9,
    pins: (consumed: 2, grainRemaining: 0, meatRemaining: null),
  ),
];
