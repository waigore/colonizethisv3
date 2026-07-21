// dart format off
// Table-driven per-phase consumption helper scenarios (Refs #3856, #3939 slice 7, #3979).
import 'package:colonizethis_models/colonizethis_models.dart';

/// Pins for military/navy food consumption rows.
typedef FoodConsumptionPins = ({int? total, int? fullyFed, int? grainRemaining});

MilitaryFoodScenario militaryFoodScenario({required String label, required int stockpileGrain, Map<String, int>? regimentCountsById, int? militaryUnits, required FoodConsumptionPins pins}) => (label: label, stockpileGrain: stockpileGrain, regimentCountsById: regimentCountsById, militaryUnits: militaryUnits, pins: pins, refs: null);

/// Military-food consumption scenario row (Refs #3979).
typedef MilitaryFoodScenario = ({
  String label,
  int stockpileGrain,
  Map<String, int>? regimentCountsById,
  int? militaryUnits,
  FoodConsumptionPins pins,
  String? refs,
});

NavyFoodScenario navyFoodScenario({required String label, required int stockpileGrain, Map<String, int>? shipCountsById, FoodConsumptionPins? pins, bool expectUnknownShipThrows = false}) => (label: label, stockpileGrain: stockpileGrain, shipCountsById: shipCountsById, pins: pins, expectUnknownShipThrows: expectUnknownShipThrows, refs: null);

/// Navy-food consumption scenario row (Refs #3979).
typedef NavyFoodScenario = ({
  String label,
  int stockpileGrain,
  Map<String, int>? shipCountsById,
  FoodConsumptionPins? pins,
  bool expectUnknownShipThrows,
  String? refs,
});

/// Data-driven expectations for [consumeWorkerFood] rows.
class WorkerFoodConsumptionExpectation {
  const WorkerFoodConsumptionExpectation({this.fedMasters, this.fedJourneymen, this.fedApprentices, this.fedPeasants, this.grainRemaining, this.meatRemaining});
  final int? fedMasters;
  final int? fedJourneymen;
  final int? fedApprentices;
  final int? fedPeasants;
  final int? grainRemaining;
  final int? meatRemaining;
}

WorkerFoodScenario workerFoodScenario({required String label, required Stockpile stockpile, required WorkerPool workers, required WorkerFoodConsumptionExpectation expectation}) => (label: label, stockpile: stockpile, workers: workers, expectation: expectation, refs: null);

/// Worker-food consumption scenario row (Refs #3979).
typedef WorkerFoodScenario = ({
  String label,
  Stockpile stockpile,
  WorkerPool workers,
  WorkerFoodConsumptionExpectation expectation,
  String? refs,
});

/// Pins for [assignWorkerLuxury] rows.
typedef WorkerLuxuryPins = ({int withLuxury, int sugarRemaining});

WorkerLuxuryScenario workerLuxuryScenario({required String label, required Stockpile stockpile, required int foodFedCount, required WorkerLuxuryPins pins}) => (label: label, stockpile: stockpile, foodFedCount: foodFedCount, pins: pins, refs: null);

/// Worker-luxury assignment scenario row (Refs #3979).
typedef WorkerLuxuryScenario = ({
  String label,
  Stockpile stockpile,
  int foodFedCount,
  WorkerLuxuryPins pins,
  String? refs,
});

/// Pins for [consumeFoodUnits] rows.
typedef FoodUnitsPins = ({int consumed, int grainRemaining, int? meatRemaining});

FoodUnitsScenario foodUnitsScenario({required String label, required Stockpile stockpile, required int required, required FoodUnitsPins pins}) => (label: label, stockpile: stockpile, required: required, pins: pins, refs: null);

/// Food-units consumption scenario row (Refs #3979).
typedef FoodUnitsScenario = ({
  String label,
  Stockpile stockpile,
  int required,
  FoodUnitsPins pins,
  String? refs,
});

/// Canonical scenarios for [consumeMilitaryFood].
List<MilitaryFoodScenario> consumeMilitaryFoodScenarios() => [
  militaryFoodScenario(label: 'per-type foodUpkeep fully feeds regiments from catalog', stockpileGrain: 10, regimentCountsById: const {'pikemen': 2}, pins: (total: 2, fullyFed: 2, grainRemaining: 6)),
  militaryFoodScenario(label: 'militaryUnits fallback consumes 2 food per regiment', stockpileGrain: 10, militaryUnits: 3, pins: (total: 3, fullyFed: 3, grainRemaining: 4)),
  militaryFoodScenario(label: 'insufficient food partially feeds regiments', stockpileGrain: 2, regimentCountsById: const {'pikemen': 3}, pins: (total: 3, fullyFed: 1, grainRemaining: 0)),
  militaryFoodScenario(label: 'no regiments and no military leaves stockpile unchanged', stockpileGrain: 5, pins: (total: 0, fullyFed: 0, grainRemaining: 5)),
  militaryFoodScenario(label: 'unknown regiment id contributes count but no food demand', stockpileGrain: 5, regimentCountsById: const {'not_a_real_regiment': 2}, pins: (total: 2, fullyFed: 0, grainRemaining: 5)),
];
/// Canonical scenarios for [consumeNavyFood].
List<NavyFoodScenario> consumeNavyFoodScenarios() => [
  navyFoodScenario(label: 'feeds ships from catalog foodUpkeep', stockpileGrain: 10, shipCountsById: const {'carrack': 2}, pins: (total: 2, fullyFed: 2, grainRemaining: 6)),
  navyFoodScenario(label: 'insufficient food partially feeds ships', stockpileGrain: 2, shipCountsById: const {'carrack': 2}, pins: (total: 2, fullyFed: 1, grainRemaining: 0)),
  navyFoodScenario(label: 'unknown ship id throws before any food is deducted', stockpileGrain: 5, shipCountsById: const {'not_a_real_ship': 1}, expectUnknownShipThrows: true),
  navyFoodScenario(label: 'empty fleet leaves stockpile unchanged', stockpileGrain: 5, pins: (total: 0, fullyFed: 0, grainRemaining: 5)),
];
/// Canonical scenarios for [consumeWorkerFood].
List<WorkerFoodScenario> consumeWorkerFoodScenarios() => [
  workerFoodScenario(label: 'feeds trained tiers (2 food) and peasants (1 food)', stockpile: const Stockpile().applyDelta('grain', 100), workers: const WorkerPool(masters: 1, journeymen: 1, apprentices: 1, peasants: 2), expectation: const WorkerFoodConsumptionExpectation(fedMasters: 1, fedJourneymen: 1, fedApprentices: 1, fedPeasants: 2, grainRemaining: 92)),
  workerFoodScenario(label: 'priority Masters→...→Peasants: masters fed before peasants', stockpile: const Stockpile().applyDelta('grain', 2), workers: const WorkerPool(masters: 1, peasants: 5), expectation: const WorkerFoodConsumptionExpectation(fedMasters: 1, fedPeasants: 0, grainRemaining: 0)),
  workerFoodScenario(label: 'grain consumed before meat', stockpile: const Stockpile().applyDelta('grain', 2).applyDelta('meat', 10), workers: const WorkerPool(apprentices: 2), expectation: const WorkerFoodConsumptionExpectation(fedApprentices: 2, grainRemaining: 0, meatRemaining: 8)),
  workerFoodScenario(label: 'no food leaves all tiers on strike', stockpile: const Stockpile(), workers: const WorkerPool(masters: 1, peasants: 2), expectation: const WorkerFoodConsumptionExpectation(fedMasters: 0, fedPeasants: 0)),
];
/// Canonical scenarios for [assignWorkerLuxury].
List<WorkerLuxuryScenario> assignWorkerLuxuryScenarios() => [workerLuxuryScenario(label: 'assigns one luxury per food-fed worker when supply suffices', stockpile: const Stockpile().applyDelta('refinedSugar', 5), foodFedCount: 3, pins: (withLuxury: 3, sugarRemaining: 2)), workerLuxuryScenario(label: 'luxury strike: short supply caps count and deducts what exists', stockpile: const Stockpile().applyDelta('refinedSugar', 1), foodFedCount: 3, pins: (withLuxury: 1, sugarRemaining: 0)), workerLuxuryScenario(label: 'no food-fed workers deducts nothing', stockpile: const Stockpile().applyDelta('refinedSugar', 5), foodFedCount: 0, pins: (withLuxury: 0, sugarRemaining: 5)), workerLuxuryScenario(label: 'no luxury available deducts nothing', stockpile: const Stockpile(), foodFedCount: 3, pins: (withLuxury: 0, sugarRemaining: 0))];
/// Canonical scenarios for [consumeFoodUnits].
List<FoodUnitsScenario> consumeFoodUnitsScenarios() => [foodUnitsScenario(label: 'grain then meat, returns consumed amount', stockpile: const Stockpile().applyDelta('grain', 3).applyDelta('meat', 5), required: 6, pins: (consumed: 6, grainRemaining: 0, meatRemaining: 2)), foodUnitsScenario(label: 'caps consumed at available when demand exceeds supply', stockpile: const Stockpile().applyDelta('grain', 2), required: 9, pins: (consumed: 2, grainRemaining: 0, meatRemaining: null))];
// dart format on
