// Consolidated diplomatic boycott suggestion runner (Refs #3949 wave 3).
//
// Tests for the `boycott` candidate in `suggestDiplomaticOrders` (Refs #3758 R8).
// SPEC/program/order-suggestions.md § Boycott candidate;
// SPEC/game/diplomacy.md § GP–Tribe Rules (Boycott).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_diplomatic_boycott_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'suggestDiplomaticOrders boycott candidate',
    suggestDiplomaticOrdersBoycottCandidateScenarios(),
    runRunnableScenario,
  );
}
