// Consolidated partial-province-reveal runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'support/scenario_runner.dart';
import 'support/engine/partial_province_reveal_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'partiallyRevealedPrefixedProvinceIdsForPlayer',
    partialProvinceRevealPrefixedIdsScenarios(),
    runRunnableScenario,
  );
  runLabeledScenarioGroup(
    'sortedProvincesForPartialRevealPrefixedIds',
    sortedProvincesForPartialRevealScenarios(),
    runRunnableScenario,
  );
}
