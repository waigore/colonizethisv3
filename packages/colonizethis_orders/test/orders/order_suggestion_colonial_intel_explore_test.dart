// Consolidated colonial intel explore runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_colonial_intel_explore_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'colonial intel explore',
    orderSuggestionColonialIntelExploreScenarios(),
    runRunnableScenario,
  );
}
