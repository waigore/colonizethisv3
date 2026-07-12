// Table-driven unit tests for per-phase consumption helpers (Refs #3856 / #3979).

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

/// Dedicated unit tests for the per-phase consumption helpers extracted from
/// `economy_consumption.dart`. SPEC/game/workers-and-population.md.
void main() {
  group('consumeMilitaryFood', () {
    runLabeledScenarios(consumeMilitaryFoodScenarios(), (scenario) {
      runMilitaryFoodScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('consumeNavyFood', () {
    runLabeledScenarios(consumeNavyFoodScenarios(), (scenario) {
      runNavyFoodScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('consumeWorkerFood', () {
    runLabeledScenarios(consumeWorkerFoodScenarios(), (scenario) {
      runWorkerFoodScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('assignWorkerLuxury', () {
    runLabeledScenarios(assignWorkerLuxuryScenarios(), (scenario) {
      runWorkerLuxuryScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('consumeFoodUnits', () {
    runLabeledScenarios(consumeFoodUnitsScenarios(), (scenario) {
      runFoodUnitsScenario(scenario);
    }, labelOf: (s) => s.label);
  });
}
