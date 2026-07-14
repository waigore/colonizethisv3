// Table-driven unit tests for economy_production (Refs #3856 / #3979).
// SPEC/game/stockpiles-and-production.md.

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

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
