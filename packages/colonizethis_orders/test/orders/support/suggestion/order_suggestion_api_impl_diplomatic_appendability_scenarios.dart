// Table-driven diplomatic appendability scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_api_impl_diplomatic_appendability_run_rows.dart';

/// One row in [orderSuggestionApiImplDiplomaticAppendabilityScenarios].
class OrderSuggestionApiImplDiplomaticAppendabilityScenario
    implements RefsScenario {
  const OrderSuggestionApiImplDiplomaticAppendabilityScenario({
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

void runOrderSuggestionApiImplDiplomaticAppendabilityScenario(
  OrderSuggestionApiImplDiplomaticAppendabilityScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionApiImplDiplomaticAppendabilityScenario>
orderSuggestionApiImplDiplomaticAppendabilityScenarios() => const [
  OrderSuggestionApiImplDiplomaticAppendabilityScenario(
    label: 'does not suggest toward target already in draft diplomatic orders',
    run: osaidaRunExcludesTargetAlreadyInDraft,
  ),
  OrderSuggestionApiImplDiplomaticAppendabilityScenario(
    label: 'suggestDiplomaticOrders: cumulative list appendable and validates',
    run: osaidaRunCumulativeListAppendableAndValidates,
  ),
  OrderSuggestionApiImplDiplomaticAppendabilityScenario(
    label:
        'removing pending diplomatic order restores suggestions for that target',
    run: osaidaRunRemovingPendingRestoresSuggestions,
  ),
];
