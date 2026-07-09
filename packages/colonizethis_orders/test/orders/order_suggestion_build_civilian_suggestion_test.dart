// Consolidated civilian build suggestion runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.
// Civilian candidates are opt-in via `includeCivilianBuilds` (Refs #3793).

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_build_civilian_suggestion_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'suggestBuildOrders civilian enumeration (Refs #3793)',
    suggestBuildOrdersCivilianEnumerationScenarios(),
    runOrderSuggestionBuildCivilianSuggestionScenario,
  );
}
