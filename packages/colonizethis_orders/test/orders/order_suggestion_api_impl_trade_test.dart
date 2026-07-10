// Consolidated trade API impl suggestion runner (Refs #3949 wave 3).
//
// Integration tests for `DefaultOrderSuggestionAPI.suggestTradeOrders` per
// `SPEC/program/world-market-resolution.md` § Trade order suggestion API
// § Default `OrderSuggestionAPI` wiring. Refs #2989 A6.

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_api_impl_trade_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'DefaultOrderSuggestionAPI.suggestTradeOrders — wiring',
    orderSuggestionApiImplTradeScenarios(),
    runRunnableScenario,
  );
}
