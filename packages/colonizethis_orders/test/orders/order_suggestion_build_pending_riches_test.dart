// Consolidated pending-riches build suggestion runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.
// Build suggestions treat pending riches-to-treasury cash as part of affordability
// (Refs #2509, SPEC/program/order-suggestions.md § Build orders).

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_build_pending_riches_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'suggestBuildOrders pending riches treasury',
    suggestBuildOrdersPendingRichesTreasuryScenarios(),
    runOrderSuggestionBuildPendingRichesScenario,
  );
}
