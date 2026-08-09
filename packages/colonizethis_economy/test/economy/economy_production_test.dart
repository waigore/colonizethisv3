// Table-driven unit tests for economy_production (Refs #3856 / #3979).
// SPEC/game/stockpiles-and-production.md.

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// --- Slice C runners (Refs #4108) ---
// dart format off
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

void runResolveProductionScenario(ResolveProductionScenario scenario) {
  runResolveProductionExpectation(scenario.pins);
}

void runProductionEffectiveLabourExpectation(ProductionEffectiveLabourPins pins) {
  final stockpile = stockpileWithDeltas(pins.stockpileDeltas);
  expect(effectiveLabourForWorkers(workers: pins.workers, stockpile: stockpile), pins.expectedLabour);
}

void runProductionEffectiveLabourScenario(ProductionEffectiveLabourScenario scenario) {
  runProductionEffectiveLabourExpectation(scenario.pins);
}
// dart format on

void main() {
  group('resolveProduction', () {
    runLabeledScenarios(resolveProductionScenarios(), (scenario) {
      runResolveProductionScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('effectiveLabourForWorkers', () {
    runLabeledScenarios(effectiveLabourForWorkersScenarios(), (scenario) {
      runProductionEffectiveLabourScenario(scenario);
    }, labelOf: (s) => s.label);
  });
}
