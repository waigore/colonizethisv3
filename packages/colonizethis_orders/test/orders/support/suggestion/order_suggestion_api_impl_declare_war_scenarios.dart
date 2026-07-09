// Table-driven API declare-war suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_api_impl_declare_war_expectations.dart';

/// One row in [orderSuggestionApiImplDeclareWarScenarios].
class OrderSuggestionApiImplDeclareWarScenario implements RefsScenario {
  const OrderSuggestionApiImplDeclareWarScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionApiImplDeclareWarTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionApiImplDeclareWarScenario(
  OrderSuggestionApiImplDeclareWarScenario scenario,
) {
  runOrderSuggestionApiImplDeclareWarExpectation(scenario.target);
}

List<OrderSuggestionApiImplDeclareWarScenario>
    orderSuggestionApiImplDeclareWarScenarios() => const [
          OrderSuggestionApiImplDeclareWarScenario(
            label: 'returns declareWar toward minor when establishOverture would win in suggestDiplomaticOrders',
            target: OrderSuggestionApiImplDeclareWarTarget
                .declareWarWhenOvertureWouldWinInDiplomaticPass,
          ),
        ];
