// Table-driven API declare-war suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_api_impl_declare_war_run_rows.dart';

/// One row in [orderSuggestionApiImplDeclareWarScenarios].
class OrderSuggestionApiImplDeclareWarScenario implements RefsScenario {
  const OrderSuggestionApiImplDeclareWarScenario({
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

void runOrderSuggestionApiImplDeclareWarScenario(
  OrderSuggestionApiImplDeclareWarScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionApiImplDeclareWarScenario>
orderSuggestionApiImplDeclareWarScenarios() => const [
  OrderSuggestionApiImplDeclareWarScenario(
    label:
        'returns declareWar toward minor when establishOverture would win in suggestDiplomaticOrders',
    run: osaidwRunDeclareWarWhenOvertureWouldWinInDiplomaticPass,
  ),
];
