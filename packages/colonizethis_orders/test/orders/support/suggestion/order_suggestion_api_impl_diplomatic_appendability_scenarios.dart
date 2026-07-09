// Table-driven diplomatic appendability scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_api_impl_diplomatic_appendability_expectations.dart';

/// One row in [orderSuggestionApiImplDiplomaticAppendabilityScenarios].
class OrderSuggestionApiImplDiplomaticAppendabilityScenario
    implements RefsScenario {
  const OrderSuggestionApiImplDiplomaticAppendabilityScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionApiImplDiplomaticAppendabilityTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionApiImplDiplomaticAppendabilityScenario(
  OrderSuggestionApiImplDiplomaticAppendabilityScenario scenario,
) {
  runOrderSuggestionApiImplDiplomaticAppendabilityExpectation(scenario.target);
}

List<OrderSuggestionApiImplDiplomaticAppendabilityScenario>
    orderSuggestionApiImplDiplomaticAppendabilityScenarios() => const [
          OrderSuggestionApiImplDiplomaticAppendabilityScenario(
            label: 'does not suggest toward target already in draft diplomatic orders',
            target: OrderSuggestionApiImplDiplomaticAppendabilityTarget
                .excludesTargetAlreadyInDraft,
          ),
          OrderSuggestionApiImplDiplomaticAppendabilityScenario(
            label: 'suggestDiplomaticOrders: cumulative list appendable and validates',
            target: OrderSuggestionApiImplDiplomaticAppendabilityTarget
                .cumulativeListAppendableAndValidates,
          ),
          OrderSuggestionApiImplDiplomaticAppendabilityScenario(
            label: 'removing pending diplomatic order restores suggestions for that target',
            target: OrderSuggestionApiImplDiplomaticAppendabilityTarget
                .removingPendingRestoresSuggestions,
          ),
        ];
