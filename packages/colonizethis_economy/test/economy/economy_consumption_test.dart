// Table-driven unit tests for resolveConsumption (Refs #3856, #3979).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// --- Slice C runners (Refs #4108) ---
// dart format off
final _grainId = 'grain';
final _meatId = 'meat';
final _sugarId = 'refinedSugar';
final _cigarsId = 'cigars';
final _furHatsId = 'furHats';

void runResolveConsumption({required Stockpile stockpile, required WorkerPool workers, int? militaryUnits, Map<String, int>? shipCountsById, required ResolveConsumptionPins pins, bool expectUnknownShipThrows = false}) {
  if (expectUnknownShipThrows) {
    expect(() => resolveConsumption(stockpile: stockpile, workers: workers, foodCounts: MilitaryNavyFoodCounts(shipCountsById: shipCountsById ?? const {})), throwsA(isA<ConsumptionUnknownShipTypeException>()));
    return;
  }
  final result = resolveConsumption(stockpile: stockpile, workers: workers, foodCounts: MilitaryNavyFoodCounts(militaryUnits: militaryUnits ?? 0, shipCountsById: shipCountsById ?? const {}));
  if (pins.workerPool != null) {
    expect(result.workerPool, pins.workerPool);
  }
  if (pins.idleLabour != null) {
    expect(result.idleLabour, pins.idleLabour);
  }
  if (pins.grainRemaining != null) {
    expect(result.stockpile.quantityOf(_grainId), pins.grainRemaining);
  }
  if (pins.meatRemaining != null) {
    expect(result.stockpile.quantityOf(_meatId), pins.meatRemaining);
  }
  if (pins.combinedFoodRemaining != null) {
    expect(result.stockpile.quantityOf(_grainId) + result.stockpile.quantityOf(_meatId), pins.combinedFoodRemaining);
  }
  if (pins.sugarRemaining != null) {
    expect(result.stockpile.quantityOf(_sugarId), pins.sugarRemaining);
  }
  if (pins.cigarsRemaining != null) {
    expect(result.stockpile.quantityOf(_cigarsId), pins.cigarsRemaining);
  }
  if (pins.furHatsRemaining != null) {
    expect(result.stockpile.quantityOf(_furHatsId), pins.furHatsRemaining);
  }
  if (pins.totalRegiments != null) {
    expect(result.totalRegiments, pins.totalRegiments);
  }
  if (pins.fullyFedRegiments != null) {
    expect(result.fullyFedRegiments, pins.fullyFedRegiments);
  }
  if (pins.totalShips != null) {
    expect(result.totalShips, pins.totalShips);
  }
  if (pins.fullyFedShips != null) {
    expect(result.fullyFedShips, pins.fullyFedShips);
  }
}

void runResolveConsumptionScenario(ResolveConsumptionScenario scenario) {
  runResolveConsumption(stockpile: scenario.stockpile, workers: scenario.workers, militaryUnits: scenario.militaryUnits, shipCountsById: scenario.shipCountsById, pins: scenario.pins, expectUnknownShipThrows: scenario.expectUnknownShipThrows);
}
// dart format on

/// Tests for economy_consumption.dart. SPEC/game/workers-and-population.md.
void main() {
  group('resolveConsumption', () {
    runLabeledScenarios(resolveConsumptionScenarios(), (scenario) {
      runResolveConsumptionScenario(scenario);
    }, labelOf: (s) => s.label);
  });
}
