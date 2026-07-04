// Table-driven unit tests for per-phase consumption helpers (Refs #3856).

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

/// Dedicated unit tests for the per-phase consumption helpers extracted from
/// `economy_consumption.dart`. SPEC/game/workers-and-population.md.
void main() {
  group('consumeMilitaryFood', () {
    for (final scenario in consumeMilitaryFoodScenarios()) {
      test(scenario.label, () {
        runConsumptionPhaseScenario(scenario);
      });
    }
  });

  group('consumeNavyFood', () {
    for (final scenario in consumeNavyFoodScenarios()) {
      test(scenario.label, () {
        runConsumptionPhaseScenario(scenario);
      });
    }
  });

  group('consumeWorkerFood', () {
    for (final scenario in consumeWorkerFoodScenarios()) {
      test(scenario.label, () {
        runConsumptionPhaseScenario(scenario);
      });
    }
  });

  group('assignWorkerLuxury', () {
    for (final scenario in assignWorkerLuxuryScenarios()) {
      test(scenario.label, () {
        runConsumptionPhaseScenario(scenario);
      });
    }
  });

  group('consumeFoodUnits', () {
    for (final scenario in consumeFoodUnitsScenarios()) {
      test(scenario.label, () {
        runConsumptionPhaseScenario(scenario);
      });
    }
  });
}
