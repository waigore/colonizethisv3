// Pins must-have #6 / SPEC `Colonial expansion (Full AI)` clause:
//   "Weight tuning only — no hard skip that removes all tribe declare-war
//    candidates for intervention risk."
// (`SPEC/ai/ai-architecture.md` § Colonial expansion).
//
// Counterpart AC text in `issue #2509`:
//   Given a fixed-seed Full AI state where a tribe is a valid declare-war
//   target, colonial-support weights are active, and intervention-risk
//   scoring would discourage war on a Great Power, when
//   `suggestDeclareWarOrders` runs, then the tribe target is **not**
//   unconditionally excluded by a hard skip guard (score may be low but
//   must remain in the candidate set; deterministic for fixed seed).
//
// Discovery note (#3620): a tribe becomes a diplomatic target only after
// first contact (relation or non-`unknown` tile visibility). These tests grant
// gp1 tile visibility into the tribe's NW colony so the tribe is a valid target
// and the "no hard skip" scoring behaviour can be exercised.
//
// Companion tests:
//   - `order_suggestion_declare_war_colonial_discovery_test.dart` (sea-reachable
//     NW without tile visibility is NOT a diplomatic target, #3620).
//   - `war_desire_score_test.dart` (intervention-risk reduces minor/tribe
//     score; pure scoring level).

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_declare_war_intervention_risk_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'suggestDeclareWarOrders intervention-risk',
    orderSuggestionDeclareWarInterventionRiskScenarios(),
    runRunnableScenario,
  );
}
