// Table-driven own-province prospect budget priority scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_prospect_own_province_budget_priority_expectations.dart';

/// One row in own-province prospect budget priority scenario tables.
class OrderSuggestionProspectOwnProvinceBudgetPriorityScenario
    implements RefsScenario {
  const OrderSuggestionProspectOwnProvinceBudgetPriorityScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionProspectOwnProvinceBudgetPriorityTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionProspectOwnProvinceBudgetPriorityScenario(
  OrderSuggestionProspectOwnProvinceBudgetPriorityScenario scenario,
) {
  runOrderSuggestionProspectOwnProvinceBudgetPriorityExpectation(
    scenario.target,
  );
}

/// Scenarios for suggestWorkOrders own-province prospect budget exemption.
List<OrderSuggestionProspectOwnProvinceBudgetPriorityScenario>
    suggestWorkOrdersOwnProvinceProspectBudgetScenarios() => const [
          OrderSuggestionProspectOwnProvinceBudgetPriorityScenario(
            label: 'co-located feedstock Explorer still receives its iron prospect after earlier units drain the shared probe budget',
            target: OrderSuggestionProspectOwnProvinceBudgetPriorityTarget
                .coLocatedFeedstockReceivesProspectAfterBudgetDrain,
            refs: '#2847',
          ),
          OrderSuggestionProspectOwnProvinceBudgetPriorityScenario(
            label: 'no feedstock prospect when the co-located tile is already prospected (negative control)',
            target: OrderSuggestionProspectOwnProvinceBudgetPriorityTarget
                .noFeedstockProspectWhenAlreadyProspected,
            refs: '#2847',
          ),
          OrderSuggestionProspectOwnProvinceBudgetPriorityScenario(
            label: 'own-province budget exemption is deterministic across runs',
            target: OrderSuggestionProspectOwnProvinceBudgetPriorityTarget
                .ownProvinceBudgetExemptionDeterministic,
            refs: '#2847',
          ),
        ];
