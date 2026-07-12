// Table-driven unit tests for per-phase consumption helpers (Refs #3856).

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

/// Dedicated unit tests for the per-phase consumption helpers extracted from
/// `economy_consumption.dart`. SPEC/game/workers-and-population.md.
void main() {
  group('consumeMilitaryFood', () {
    runLabeledScenarios(consumeMilitaryFoodScenarios(), (scenario) {
      runConsumptionPhaseScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('consumeNavyFood', () {
    runLabeledScenarios(consumeNavyFoodScenarios(), (scenario) {
      runConsumptionPhaseScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('consumeWorkerFood', () {
    runLabeledScenarios(consumeWorkerFoodScenarios(), (scenario) {
      runConsumptionPhaseScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('assignWorkerLuxury', () {
    runLabeledScenarios(assignWorkerLuxuryScenarios(), (scenario) {
      runConsumptionPhaseScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('consumeFoodUnits', () {
    runLabeledScenarios(consumeFoodUnitsScenarios(), (scenario) {
      runConsumptionPhaseScenario(scenario);
    }, labelOf: (s) => s.label);
  });
}
