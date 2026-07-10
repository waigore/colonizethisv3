// Table-driven intervention-risk declare-war scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_declare_war_intervention_risk_run_rows.dart';

/// One row in [orderSuggestionDeclareWarInterventionRiskScenarios].
class OrderSuggestionDeclareWarInterventionRiskScenario
    implements RefsScenario {
  const OrderSuggestionDeclareWarInterventionRiskScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runOrderSuggestionDeclareWarInterventionRiskScenario(
  OrderSuggestionDeclareWarInterventionRiskScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionDeclareWarInterventionRiskScenario>
orderSuggestionDeclareWarInterventionRiskScenarios() => const [
  OrderSuggestionDeclareWarInterventionRiskScenario(
    label: 'tribe stays in candidates when other GPs hold embassies on it',
    run: osdwirRunTribeStaysInCandidates,
    refs: '#2509',
  ),
  OrderSuggestionDeclareWarInterventionRiskScenario(
    label:
        'tribe candidate is deterministic across repeated suggestDeclareWarOrders calls',
    run: osdwirRunDeterministicAcrossRepeatedCalls,
    refs: '#2509',
  ),
];
