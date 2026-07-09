// Pins #3620 first-contact gate for colonial declare-war discovery:
//
//   A tribe becomes a diplomatic target only after first contact (relation or
//   non-`unknown` tile visibility). Sea-reachable NW provinces without tile
//   visibility must not surface declare-war candidates.
//
// Companion tests:
//   - `order_suggestion_declare_war_intervention_risk_test.dart` (tribe with
//     tile visibility IS a valid target; intervention-risk scoring must not
//     hard-skip).
//   - `order_suggestion_colonial_acquisition_join_empire_or_war_test.dart`
//     (embassy-stage tribe with visibility surfaces Join Empire / declareWar).

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_declare_war_colonial_discovery_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'knownDiplomaticTargetFactionIds colonial discovery',
    orderSuggestionDeclareWarColonialDiscoveryScenarios(),
    runOrderSuggestionDeclareWarColonialDiscoveryScenario,
  );
}
