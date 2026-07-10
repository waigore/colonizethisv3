// Table-driven feedstock new-world projection scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_feedstock_new_world_projection_run_rows.dart';

class OrderSuggestionFeedstockNewWorldProjectionScenario
    implements LabeledScenario {
  const OrderSuggestionFeedstockNewWorldProjectionScenario({
    required this.label,
    required this.run,
  });

  @override
  final String label;
  final void Function() run;
}

void runOrderSuggestionFeedstockNewWorldProjectionScenario(
  OrderSuggestionFeedstockNewWorldProjectionScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionFeedstockNewWorldProjectionScenario>
orderSuggestionFeedstockNewWorldProjectionScenarios() => const [
  OrderSuggestionFeedstockNewWorldProjectionScenario(
    label:
        'seller owning a New World province deactivates the feedstock gate (projection-backed new-world count, Refs #3393)',
    run: osfnwpRunSellerNwDeactivatesGate,
  ),
];
