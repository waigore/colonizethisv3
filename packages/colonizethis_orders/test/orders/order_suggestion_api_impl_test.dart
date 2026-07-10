// Consolidated DefaultOrderSuggestionAPI suggestion runner (Refs #3949 wave 3).

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_api_impl_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'DefaultOrderSuggestionAPI',
    orderSuggestionApiImplScenarios(),
    runRunnableScenario,
  );
}
