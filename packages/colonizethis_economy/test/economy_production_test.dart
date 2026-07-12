// Table-driven unit tests for economy_production (Refs #3856).
// SPEC/game/stockpiles-and-production.md.

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('resolveProduction', () {
    runLabeledScenarios(resolveProductionScenarios(), (scenario) {
      runEconomyProductionScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('effectiveLabourForWorkers', () {
    runLabeledScenarios(effectiveLabourForWorkersScenarios(), (scenario) {
      runEconomyProductionScenario(scenario);
    }, labelOf: (s) => s.label);
  });
}
