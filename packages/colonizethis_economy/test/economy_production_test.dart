// Table-driven unit tests for economy_production (Refs #3856).
// SPEC/game/stockpiles-and-production.md.

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('resolveProduction', () {
    for (final scenario in resolveProductionScenarios()) {
      test(scenario.label, () {
        runEconomyProductionScenario(scenario);
      });
    }
  });

  group('effectiveLabourForWorkers', () {
    for (final scenario in effectiveLabourForWorkersScenarios()) {
      test(scenario.label, () {
        runEconomyProductionScenario(scenario);
      });
    }
  });
}
