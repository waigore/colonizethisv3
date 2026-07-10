// Table-driven intervention-risk declare-war scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_declare_war_intervention_risk_expectations.dart';

/// One row in [orderSuggestionDeclareWarInterventionRiskScenarios].
class OrderSuggestionDeclareWarInterventionRiskScenario implements RefsScenario {
  const OrderSuggestionDeclareWarInterventionRiskScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionDeclareWarInterventionRiskTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionDeclareWarInterventionRiskScenario(
  OrderSuggestionDeclareWarInterventionRiskScenario scenario,
) {
  runOrderSuggestionDeclareWarInterventionRiskExpectation(scenario.target);
}

List<OrderSuggestionDeclareWarInterventionRiskScenario>
    orderSuggestionDeclareWarInterventionRiskScenarios() => const [
          OrderSuggestionDeclareWarInterventionRiskScenario(
            label: 'tribe stays in candidates when other GPs hold embassies on it',
            target: OrderSuggestionDeclareWarInterventionRiskTarget
                .tribeStaysInCandidates,
            refs: '#2509',
          ),
          OrderSuggestionDeclareWarInterventionRiskScenario(
            label: 'tribe candidate is deterministic across repeated suggestDeclareWarOrders calls',
            target: OrderSuggestionDeclareWarInterventionRiskTarget
                .deterministicAcrossRepeatedCalls,
            refs: '#2509',
          ),
        ];
