
import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_api_impl_diplomatic_appendability_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'suggestDiplomaticOrders appendability',
    orderSuggestionApiImplDiplomaticAppendabilityScenarios(),
    runRunnableScenario,
  );
}
