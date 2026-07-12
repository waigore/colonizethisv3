// Table-driven unit tests for resolveConsumption (Refs #3856).

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

/// Tests for economy_consumption.dart. SPEC/game/workers-and-population.md.
void main() {
  group('resolveConsumption', () {
    runLabeledScenarios(resolveConsumptionScenarios(), (scenario) {
      runConsumptionScenario(scenario);
    }, labelOf: (s) => s.label);
  });
}
