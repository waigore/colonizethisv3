// Table-driven feedstock new-world projection scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_feedstock_new_world_projection_expectations.dart';

class OrderSuggestionFeedstockNewWorldProjectionScenario
    implements LabeledScenario {
  const OrderSuggestionFeedstockNewWorldProjectionScenario({
    required this.label,
    required this.target,
  });

  @override
  final String label;
  final OrderSuggestionFeedstockNewWorldProjectionTarget target;
}

void runOrderSuggestionFeedstockNewWorldProjectionScenario(
  OrderSuggestionFeedstockNewWorldProjectionScenario scenario,
) {
  runOrderSuggestionFeedstockNewWorldProjectionExpectation(scenario.target);
}

List<OrderSuggestionFeedstockNewWorldProjectionScenario>
    orderSuggestionFeedstockNewWorldProjectionScenarios() => const [
          OrderSuggestionFeedstockNewWorldProjectionScenario(
            label: 'seller owning a New World province deactivates the feedstock gate (projection-backed new-world count, Refs #3393)',
            target: OrderSuggestionFeedstockNewWorldProjectionTarget
                .sellerNwDeactivatesGate,
          ),
        ];
