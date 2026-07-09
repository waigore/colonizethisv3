// Table-driven no-OrderEngine-full-pass scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_no_order_engine_full_pass_expectations.dart';

/// One row in [orderSuggestionNoOrderEngineFullPassScenarios].
class OrderSuggestionNoOrderEngineFullPassScenario implements RefsScenario {
  const OrderSuggestionNoOrderEngineFullPassScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionNoOrderEngineFullPassTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionNoOrderEngineFullPassScenario(
  OrderSuggestionNoOrderEngineFullPassScenario scenario,
) {
  runOrderSuggestionNoOrderEngineFullPassExpectation(scenario.target);
}

List<OrderSuggestionNoOrderEngineFullPassScenario>
    orderSuggestionNoOrderEngineFullPassScenarios() => const [
          OrderSuggestionNoOrderEngineFullPassScenario(
            label: 'suggestBuildOrders does not invoke validatePlayerOrdersWithContext',
            target: OrderSuggestionNoOrderEngineFullPassTarget
                .suggestBuildOrdersSkipsFullPass,
            refs: '#2237 AC2',
          ),
          OrderSuggestionNoOrderEngineFullPassScenario(
            label: 'OrderEngine add-with-context still invokes full validation',
            target: OrderSuggestionNoOrderEngineFullPassTarget
                .orderEngineAddWithContextInvokesFullValidation,
            refs: '#2237',
          ),
        ];
