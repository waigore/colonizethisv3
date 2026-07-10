// Pins colonial acquisition candidate emission (#2509). See file header in
// REFACTOR_TRACE.md slice 89 for full AC context and companion tests.

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_colonial_acquisition_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'colonial acquisition suggestions (Refs #2509)',
    orderSuggestionColonialAcquisitionScenarios(),
    runOrderSuggestionColonialAcquisitionScenario,
  );
}
