// dart format off
// Compact per-phase consumption assertions (Refs #3939 phase 3 slice 33, #3979).
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'consumption_phases_scenarios.dart';
final _grainId = 'grain';
final _meatId = 'meat';
final _sugarId = 'refinedSugar';
/// Pins for military/navy food consumption rows.
typedef FoodConsumptionPins = ({int? total, int? fullyFed, int? grainRemaining});
void runMilitaryFoodConsumption({required int stockpileGrain, Map<String, int>? regimentCountsById, int? militaryUnits, required FoodConsumptionPins pins}) {
  final stockpile = Stockpile().applyDelta(_grainId, stockpileGrain);
  final (next, total, fullyFed) = consumeMilitaryFood(stockpile: stockpile, regimentCountsById: regimentCountsById ?? const {}, militaryUnits: militaryUnits ?? 0);
  if (pins.total != null) expect(total, pins.total);
  if (pins.fullyFed != null) expect(fullyFed, pins.fullyFed);
  if (pins.grainRemaining != null) {
    expect(next.quantityOf(_grainId), pins.grainRemaining);
  }
}
MilitaryFoodScenario militaryFoodScenario({required String label, required int stockpileGrain, Map<String, int>? regimentCountsById, int? militaryUnits, required FoodConsumptionPins pins}) => (label: label, stockpileGrain: stockpileGrain, regimentCountsById: regimentCountsById, militaryUnits: militaryUnits, pins: pins, refs: null);
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
NavyFoodScenario navyFoodScenario({required String label, required int stockpileGrain, Map<String, int>? shipCountsById, FoodConsumptionPins? pins, bool expectUnknownShipThrows = false}) => (label: label, stockpileGrain: stockpileGrain, shipCountsById: shipCountsById, pins: pins, expectUnknownShipThrows: expectUnknownShipThrows, refs: null);
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
WorkerFoodScenario workerFoodScenario({required String label, required Stockpile stockpile, required WorkerPool workers, required WorkerFoodConsumptionExpectation expectation}) => (label: label, stockpile: stockpile, workers: workers, expectation: expectation, refs: null);
/// Pins for [assignWorkerLuxury] rows.
typedef WorkerLuxuryPins = ({int withLuxury, int sugarRemaining});
void runWorkerLuxuryAssignment({required Stockpile stockpile, required int foodFedCount, required WorkerLuxuryPins pins}) {
  final (next, withLuxury) = assignWorkerLuxury(stockpile: stockpile, foodFedCount: foodFedCount, luxuryId: _sugarId);
  expect(withLuxury, pins.withLuxury);
  expect(next.quantityOf(_sugarId), pins.sugarRemaining);
}
WorkerLuxuryScenario workerLuxuryScenario({required String label, required Stockpile stockpile, required int foodFedCount, required WorkerLuxuryPins pins}) => (label: label, stockpile: stockpile, foodFedCount: foodFedCount, pins: pins, refs: null);
/// Pins for [consumeFoodUnits] rows.
typedef FoodUnitsPins = ({int consumed, int grainRemaining, int? meatRemaining});
void runFoodUnitsConsumption({required Stockpile stockpile, required int requiredUnits, required FoodUnitsPins pins}) {
  final (next, consumed) = consumeFoodUnits(stockpile: stockpile, required: requiredUnits);
  expect(consumed, pins.consumed);
  expect(next.quantityOf(_grainId), pins.grainRemaining);
  if (pins.meatRemaining != null) {
    expect(next.quantityOf(_meatId), pins.meatRemaining);
  }
}
FoodUnitsScenario foodUnitsScenario({required String label, required Stockpile stockpile, required int required, required FoodUnitsPins pins}) => (label: label, stockpile: stockpile, required: required, pins: pins, refs: null);
// dart format on
