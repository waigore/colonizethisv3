// Table-driven own-province prospect budget priority scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_prospect_own_province_budget_priority_run_rows.dart';

/// One row in own-province prospect budget priority scenario tables.
class OrderSuggestionProspectOwnProvinceBudgetPriorityScenario
    implements RefsScenario {
  const OrderSuggestionProspectOwnProvinceBudgetPriorityScenario({
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

void runOrderSuggestionProspectOwnProvinceBudgetPriorityScenario(
  OrderSuggestionProspectOwnProvinceBudgetPriorityScenario scenario,
) {
  scenario.run();
}

/// Scenarios for suggestWorkOrders own-province prospect budget exemption.
List<OrderSuggestionProspectOwnProvinceBudgetPriorityScenario>
suggestWorkOrdersOwnProvinceProspectBudgetScenarios() => const [
  OrderSuggestionProspectOwnProvinceBudgetPriorityScenario(
    label:
        'co-located feedstock Explorer still receives its iron prospect after earlier units drain the shared probe budget',
    run: ospobpRunCoLocatedFeedstockReceivesProspectAfterBudgetDrain,
    refs: '#2847',
  ),
  OrderSuggestionProspectOwnProvinceBudgetPriorityScenario(
    label:
        'no feedstock prospect when the co-located tile is already prospected (negative control)',
    run: ospobpRunNoFeedstockProspectWhenAlreadyProspected,
    refs: '#2847',
  ),
  OrderSuggestionProspectOwnProvinceBudgetPriorityScenario(
    label: 'own-province budget exemption is deterministic across runs',
    run: ospobpRunOwnProvinceBudgetExemptionDeterministic,
    refs: '#2847',
  ),
];
