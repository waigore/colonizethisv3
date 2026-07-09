// Consolidated research diversification runner (Refs #3949 wave 3).
//
// Full-AI category diversification for `suggestResearchOrders` (Refs #3472).
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.
//
// Free slot 0 stays greedy-cheapest; free slots >= 1 prefer the highest-weight
// AI bucket not represented by lower slots. The default (`categoryDiversify
// Weight == 0`) preserves pure greedy selection for human / simple-AI callers.
// SPEC/program/order-suggestions.md § Research orders.

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_research_diversify_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'suggestResearchOrders category diversification',
    orderSuggestionResearchDiversifyScenarios(),
    runOrderSuggestionResearchDiversifyScenario,
  );
}
