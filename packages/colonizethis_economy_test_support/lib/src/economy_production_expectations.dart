// dart format off
// Compact economy production assertions (Refs #3939 phase 3 slice 37, #3979).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'core_economy_test_support.dart';
import 'economy_production_scenarios.dart';

/// Pins for [resolveProduction] recipe rows.
typedef ResolveProductionPins = ({Map<String, int> stockpileDeltas, WorkerPool workers, WorkerIdleCounts idleLabour, List<AssignedRecipe> assignments, Map<String, int> expectedQuantities, WorkerPool? expectedWorkers});

void runResolveProductionExpectation(ResolveProductionPins pins) {
  final stockpile = pins.stockpileDeltas.isEmpty ? const Stockpile() : stockpileWithDeltas(pins.stockpileDeltas);

  final result = resolveProduction(stockpile: stockpile, workers: pins.workers, idleLabour: pins.idleLabour, assignments: pins.assignments);

  for (final entry in pins.expectedQuantities.entries) {
    expect(result.stockpile.quantityOf(entry.key), entry.value);
  }
  final expectedWorkers = pins.expectedWorkers;
  if (expectedWorkers != null) {
    expect(result.workerPool.peasants, expectedWorkers.peasants);
    expect(result.workerPool.apprentices, expectedWorkers.apprentices);
    expect(result.workerPool.journeymen, expectedWorkers.journeymen);
    expect(result.workerPool.masters, expectedWorkers.masters);
  }
}

ResolveProductionScenario resolveProductionScenario({required String label, required ResolveProductionPins pins, String? refs}) => (label: label, pins: pins, refs: refs);

/// Pins for production [effectiveLabourForWorkers] rows (Refs #3979).
typedef ProductionEffectiveLabourPins = ({WorkerPool workers, Map<String, int> stockpileDeltas, int expectedLabour});

void runProductionEffectiveLabourExpectation(ProductionEffectiveLabourPins pins) {
  final stockpile = stockpileWithDeltas(pins.stockpileDeltas);
  expect(effectiveLabourForWorkers(workers: pins.workers, stockpile: stockpile), pins.expectedLabour);
}

ProductionEffectiveLabourScenario productionEffectiveLabourScenario({required String label, required ProductionEffectiveLabourPins pins, String? refs}) => (label: label, pins: pins, refs: refs);
// dart format on
