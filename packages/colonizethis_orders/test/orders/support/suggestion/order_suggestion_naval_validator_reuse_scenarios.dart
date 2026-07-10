// Table-driven naval validator-reuse scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_naval_validator_reuse_run_rows.dart';

/// One row in [orderSuggestionNavalValidatorReuseScenarios].
class OrderSuggestionNavalValidatorReuseScenario implements RefsScenario {
  const OrderSuggestionNavalValidatorReuseScenario({
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

void runOrderSuggestionNavalValidatorReuseScenario(
  OrderSuggestionNavalValidatorReuseScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionNavalValidatorReuseScenario>
orderSuggestionNavalValidatorReuseScenarios() => const [
  OrderSuggestionNavalValidatorReuseScenario(
    label:
        'suggestNavalMoveOrders and suggestNavalMissionOrders reuse one validator',
    run: osnvrRunMoveAndMissionReuseOneValidator,
    refs: '#2394',
  ),
];
