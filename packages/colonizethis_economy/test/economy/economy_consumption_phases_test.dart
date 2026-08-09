// Table-driven unit tests for per-phase consumption helpers (Refs #3856 / #3979).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// --- Slice C runners (Refs #4108) ---
// dart format off
final _grainId = 'grain';
final _meatId = 'meat';
final _sugarId = 'refinedSugar';

void runMilitaryFoodConsumption({required int stockpileGrain, Map<String, int>? regimentCountsById, int? militaryUnits, required FoodConsumptionPins pins}) {
  final stockpile = Stockpile().applyDelta(_grainId, stockpileGrain);
  final (next, total, fullyFed) = consumeMilitaryFood(stockpile: stockpile, regimentCountsById: regimentCountsById ?? const {}, militaryUnits: militaryUnits ?? 0);
  if (pins.total != null) expect(total, pins.total);
  if (pins.fullyFed != null) expect(fullyFed, pins.fullyFed);
  if (pins.grainRemaining != null) {
    expect(next.quantityOf(_grainId), pins.grainRemaining);
  }
}

void runMilitaryFoodScenario(MilitaryFoodScenario scenario) {
  runMilitaryFoodConsumption(
    stockpileGrain: scenario.stockpileGrain,
    regimentCountsById: scenario.regimentCountsById,
    militaryUnits: scenario.militaryUnits,
    pins: scenario.pins,
  );
}

void runNavyFoodConsumption({required int stockpileGrain, Map<String, int>? shipCountsById, FoodConsumptionPins? pins, bool expectUnknownShipThrows = false}) {
  final stockpile = Stockpile().applyDelta(_grainId, stockpileGrain);
  if (expectUnknownShipThrows) {
    expect(() => consumeNavyFood(stockpile: stockpile, shipCountsById: shipCountsById ?? const {}), throwsA(isA<ConsumptionUnknownShipTypeException>()));
    return;
  }
  final resolvedPins = pins!;
  final (next, total, fullyFed) = consumeNavyFood(stockpile: stockpile, shipCountsById: shipCountsById ?? const {});
  if (resolvedPins.total != null) expect(total, resolvedPins.total);
  if (resolvedPins.fullyFed != null) expect(fullyFed, resolvedPins.fullyFed);
  if (resolvedPins.grainRemaining != null) {
    expect(next.quantityOf(_grainId), resolvedPins.grainRemaining);
  }
}

void runNavyFoodScenario(NavyFoodScenario scenario) {
  runNavyFoodConsumption(
    stockpileGrain: scenario.stockpileGrain,
    shipCountsById: scenario.shipCountsById,
    pins: scenario.pins,
    expectUnknownShipThrows: scenario.expectUnknownShipThrows,
  );
}

void runWorkerFoodConsumption({required Stockpile stockpile, required WorkerPool workers, required WorkerFoodConsumptionExpectation expectation}) {
  final fed = consumeWorkerFood(stockpile: stockpile, workers: workers);
  if (expectation.fedMasters != null) {
    expect(fed.fedMasters, expectation.fedMasters);
  }
  if (expectation.fedJourneymen != null) {
    expect(fed.fedJourneymen, expectation.fedJourneymen);
  }
  if (expectation.fedApprentices != null) {
    expect(fed.fedApprentices, expectation.fedApprentices);
  }
  if (expectation.fedPeasants != null) {
    expect(fed.fedPeasants, expectation.fedPeasants);
  }
  if (expectation.grainRemaining != null) {
    expect(fed.stockpile.quantityOf(_grainId), expectation.grainRemaining);
  }
  if (expectation.meatRemaining != null) {
    expect(fed.stockpile.quantityOf(_meatId), expectation.meatRemaining);
  }
}

void runWorkerFoodScenario(WorkerFoodScenario scenario) {
  runWorkerFoodConsumption(
    stockpile: scenario.stockpile,
    workers: scenario.workers,
    expectation: scenario.expectation,
  );
}

void runWorkerLuxuryAssignment({required Stockpile stockpile, required int foodFedCount, required WorkerLuxuryPins pins}) {
  final (next, withLuxury) = assignWorkerLuxury(stockpile: stockpile, foodFedCount: foodFedCount, luxuryId: _sugarId);
  expect(withLuxury, pins.withLuxury);
  expect(next.quantityOf(_sugarId), pins.sugarRemaining);
}

void runWorkerLuxuryScenario(WorkerLuxuryScenario scenario) {
  runWorkerLuxuryAssignment(
    stockpile: scenario.stockpile,
    foodFedCount: scenario.foodFedCount,
    pins: scenario.pins,
  );
}

void runFoodUnitsConsumption({required Stockpile stockpile, required int requiredUnits, required FoodUnitsPins pins}) {
  final (next, consumed) = consumeFoodUnits(stockpile: stockpile, required: requiredUnits);
  expect(consumed, pins.consumed);
  expect(next.quantityOf(_grainId), pins.grainRemaining);
  if (pins.meatRemaining != null) {
    expect(next.quantityOf(_meatId), pins.meatRemaining);
  }
}

void runFoodUnitsScenario(FoodUnitsScenario scenario) {
  runFoodUnitsConsumption(
    stockpile: scenario.stockpile,
    requiredUnits: scenario.required,
    pins: scenario.pins,
  );
}
// dart format on

/// Dedicated unit tests for the per-phase consumption helpers extracted from
/// `economy_consumption.dart`. SPEC/game/workers-and-population.md.
void main() {
  group('consumeMilitaryFood', () {
    runLabeledScenarios(consumeMilitaryFoodScenarios(), (scenario) {
      runMilitaryFoodScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('consumeNavyFood', () {
    runLabeledScenarios(consumeNavyFoodScenarios(), (scenario) {
      runNavyFoodScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('consumeWorkerFood', () {
    runLabeledScenarios(consumeWorkerFoodScenarios(), (scenario) {
      runWorkerFoodScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('assignWorkerLuxury', () {
    runLabeledScenarios(assignWorkerLuxuryScenarios(), (scenario) {
      runWorkerLuxuryScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('consumeFoodUnits', () {
    runLabeledScenarios(consumeFoodUnitsScenarios(), (scenario) {
      runFoodUnitsScenario(scenario);
    }, labelOf: (s) => s.label);
  });
}
