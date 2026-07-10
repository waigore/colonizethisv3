// Consolidated diplomatic-pass suggestion runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_diplomatic_pass_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'order_suggestion_diplomatic_pass',
    orderSuggestionDiplomaticPassScenarios(),
    runRunnableScenario,
  );
}
