// Consolidated own-province prospect budget priority runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.
// `suggestWorkOrders` exempts the Explorer's own-province prospect probe from
// the shared WorkSuggestionProbeBudget (Refs #2847).

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_prospect_own_province_budget_priority_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'suggestWorkOrders exempts own-province prospect from the shared probe '
    'budget (Refs #2847 H8-extraction gp1 residual)',
    suggestWorkOrdersOwnProvinceProspectBudgetScenarios(),
    runOrderSuggestionProspectOwnProvinceBudgetPriorityScenario,
  );
}
