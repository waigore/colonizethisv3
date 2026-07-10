// Table-driven no-OrderEngine-full-pass scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_no_order_engine_full_pass_run_rows.dart';

/// One row in [orderSuggestionNoOrderEngineFullPassScenarios].
class OrderSuggestionNoOrderEngineFullPassScenario implements RefsScenario {
  const OrderSuggestionNoOrderEngineFullPassScenario({
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

void runOrderSuggestionNoOrderEngineFullPassScenario(
  OrderSuggestionNoOrderEngineFullPassScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionNoOrderEngineFullPassScenario>
orderSuggestionNoOrderEngineFullPassScenarios() => const [
  OrderSuggestionNoOrderEngineFullPassScenario(
    label: 'suggestBuildOrders does not invoke validatePlayerOrdersWithContext',
    run: osnoefpRunSuggestBuildOrdersSkipsFullPass,
    refs: '#2237 AC2',
  ),
  OrderSuggestionNoOrderEngineFullPassScenario(
    label: 'OrderEngine add-with-context still invokes full validation',
    run: osnoefpRunOrderEngineAddWithContextInvokesFullValidation,
    refs: '#2237',
  ),
];
