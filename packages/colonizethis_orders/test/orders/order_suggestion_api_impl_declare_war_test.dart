import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_api_impl_declare_war_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'suggestDeclareWarOrders',
    orderSuggestionApiImplDeclareWarScenarios(),
    runOrderSuggestionApiImplDeclareWarScenario,
  );
}
