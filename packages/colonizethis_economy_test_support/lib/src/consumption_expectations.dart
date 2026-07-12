// dart format off
// Compact resolveConsumption integration assertions (Refs #3939 phase 3
// slices 34 / 45).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'consumption_scenarios.dart';
import 'core_economy_test_support.dart';

final _grainId = 'grain';
final _meatId = 'meat';
final _sugarId = 'refinedSugar';
final _cigarsId = 'cigars';
final _furHatsId = 'furHats';

/// Pins for [resolveConsumption] integration rows.
///
/// Optional fields default to `null` (no assertion) so scenario tables omit
/// unused keys (Refs #3939 slice 45 LOC compaction).
class ResolveConsumptionPins {
  const ResolveConsumptionPins({this.workerPool, this.idleLabour, this.grainRemaining, this.meatRemaining, this.combinedFoodRemaining, this.sugarRemaining, this.cigarsRemaining, this.furHatsRemaining, this.totalRegiments, this.fullyFedRegiments, this.totalShips, this.fullyFedShips});

  final WorkerPool? workerPool;
  final WorkerIdleCounts? idleLabour;
  final int? grainRemaining;
  final int? meatRemaining;
  final int? combinedFoodRemaining;
  final int? sugarRemaining;
  final int? cigarsRemaining;
  final int? furHatsRemaining;
  final int? totalRegiments;
  final int? fullyFedRegiments;
  final int? totalShips;
  final int? fullyFedShips;
}

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

ConsumptionScenario resolveConsumptionScenario({required String label, Map<String, int>? stockpileDeltas, Stockpile? stockpile, required WorkerPool workers, int? militaryUnits, Map<String, int>? shipCountsById, required ResolveConsumptionPins pins, bool expectUnknownShipThrows = false}) {
  final resolvedStockpile = stockpile ?? (stockpileDeltas == null ? const Stockpile() : stockpileWithDeltas(stockpileDeltas));
  return (label: label, run: () => runResolveConsumption(stockpile: resolvedStockpile, workers: workers, militaryUnits: militaryUnits, shipCountsById: shipCountsById, pins: pins, expectUnknownShipThrows: expectUnknownShipThrows), refs: null);
}
// dart format on
