// Compact economy production assertions (Refs #3939 phase 3 slice 37).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'core_economy_test_support.dart';
import 'economy_production_scenarios.dart';

/// Pins for [resolveProduction] recipe rows.
typedef ResolveProductionPins = ({
  Map<String, int> stockpileDeltas,
  WorkerPool workers,
  WorkerIdleCounts idleLabour,
  List<AssignedRecipe> assignments,
  Map<String, int> expectedQuantities,
  WorkerPool? expectedWorkers,
});

void runResolveProductionExpectation(ResolveProductionPins pins) {
  final stockpile = pins.stockpileDeltas.isEmpty
      ? const Stockpile()
      : stockpileWithDeltas(pins.stockpileDeltas);

  final result = resolveProduction(
    stockpile: stockpile,
    workers: pins.workers,
    idleLabour: pins.idleLabour,
    assignments: pins.assignments,
  );

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

EconomyProductionScenario resolveProductionScenario({
  required String label,
  required ResolveProductionPins pins,
  String? refs,
}) =>
    EconomyProductionScenario(
      label: label,
      run: () => runResolveProductionExpectation(pins),
      refs: refs,
    );

/// Pins for [effectiveLabourForWorkers] rows.
typedef EffectiveLabourPins = ({
  WorkerPool workers,
  Map<String, int> stockpileDeltas,
  int expectedLabour,
});

void runEffectiveLabourExpectation(EffectiveLabourPins pins) {
  final stockpile = stockpileWithDeltas(pins.stockpileDeltas);
  expect(
    effectiveLabourForWorkers(workers: pins.workers, stockpile: stockpile),
    pins.expectedLabour,
  );
}

EconomyProductionScenario effectiveLabourScenario({
  required String label,
  required EffectiveLabourPins pins,
  String? refs,
}) =>
    EconomyProductionScenario(
      label: label,
      run: () => runEffectiveLabourExpectation(pins),
      refs: refs,
    );
