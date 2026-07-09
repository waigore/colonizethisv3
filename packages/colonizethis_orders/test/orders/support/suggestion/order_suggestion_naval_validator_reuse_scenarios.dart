// Table-driven naval validator-reuse scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_naval_validator_reuse_expectations.dart';

/// One row in [orderSuggestionNavalValidatorReuseScenarios].
class OrderSuggestionNavalValidatorReuseScenario implements RefsScenario {
  const OrderSuggestionNavalValidatorReuseScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionNavalValidatorReuseTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionNavalValidatorReuseScenario(
  OrderSuggestionNavalValidatorReuseScenario scenario,
) {
  runOrderSuggestionNavalValidatorReuseExpectation(scenario.target);
}

List<OrderSuggestionNavalValidatorReuseScenario>
    orderSuggestionNavalValidatorReuseScenarios() => const [
          OrderSuggestionNavalValidatorReuseScenario(
            label: 'suggestNavalMoveOrders and suggestNavalMissionOrders reuse one validator',
            target: OrderSuggestionNavalValidatorReuseTarget
                .moveAndMissionReuseOneValidator,
            refs: '#2394',
          ),
        ];
