// Table-driven unit tests for worker labour primitives (Refs #3939).

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

/// Dedicated unit tests for the worker-economy labour primitives.
/// SPEC/program/economy-models.md, SPEC/game/workers-and-population.md.
void main() {
  group('effectiveLabourFromIdleCounts', () {
    for (final scenario in workerEconomyLabourFromIdleCountsScenarios()) {
      test(scenario.label, () {
        runWorkerEconomyScenario(scenario);
      });
    }
  });

  group('effectiveLabourForWorkers', () {
    for (final scenario in workerEconomyLabourForWorkersScenarios()) {
      test(scenario.label, () {
        runWorkerEconomyScenario(scenario);
      });
    }
  });
}
