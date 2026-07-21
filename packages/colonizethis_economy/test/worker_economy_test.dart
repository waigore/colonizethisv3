// Table-driven unit tests for worker labour primitives (Refs #3939, #3979).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

// --- Slice C runners (Refs #4108) ---
// dart format off
void runIdleLabourExpectation(IdleLabourPins pins) {
  expect(effectiveLabourFromIdleCounts(pins.idle), pins.expected);
}

void runEffectiveLabourExpectation(EffectiveLabourPins pins) {
  final labour = effectiveLabourForWorkers(
    workers: pins.workers,
    stockpile: pins.stockpile,
    foodCounts: MilitaryNavyFoodCounts(militaryUnits: pins.militaryUnits),
  );
  expect(labour, pins.expected);
}

void runIdleLabourScenario(IdleLabourScenario scenario) {
  runIdleLabourExpectation(scenario.pins);
}

void runEffectiveLabourScenario(EffectiveLabourScenario scenario) {
  runEffectiveLabourExpectation(scenario.pins);
}
// dart format on

/// Dedicated unit tests for the worker-economy labour primitives.
/// SPEC/program/economy-models.md, SPEC/game/workers-and-population.md.
void main() {
  group('effectiveLabourFromIdleCounts', () {
    runLabeledScenarios(workerEconomyLabourFromIdleCountsScenarios(), (scenario) {
      runIdleLabourScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('effectiveLabourForWorkers', () {
    runLabeledScenarios(workerEconomyLabourForWorkersScenarios(), (scenario) {
      runEffectiveLabourScenario(scenario);
    }, labelOf: (s) => s.label);
  });
}
