// Consolidated multi-slot research suggestion runner (Refs #3949 wave 3).
//
// Multi-slot research suggestion behavior for the Full-AI research planner
// (Refs #3472). The suggestion layer is funding-agnostic: it enumerates
// assignable slots, preserves in-progress research, and fills remaining slots
// with distinct researchable techs. Funding is left as a placeholder for the
// planner. SPEC/program/order-suggestions.md § Research orders.

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_research_multi_slot_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'suggestResearchOrders multi-slot',
    orderSuggestionResearchMultiSlotScenarios(),
    runRunnableScenario,
  );
}
