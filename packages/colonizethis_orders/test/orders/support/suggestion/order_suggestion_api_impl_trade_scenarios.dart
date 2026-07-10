// Table-driven trade API impl suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_api_impl_trade_expectations.dart';

/// One row in [orderSuggestionApiImplTradeScenarios].
class OrderSuggestionApiImplTradeScenario implements RefsScenario {
  const OrderSuggestionApiImplTradeScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionApiImplTradeTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionApiImplTradeScenario(
  OrderSuggestionApiImplTradeScenario scenario,
) {
  runOrderSuggestionApiImplTradeExpectation(scenario.target);
}

List<OrderSuggestionApiImplTradeScenario> orderSuggestionApiImplTradeScenarios() =>
    const [
      OrderSuggestionApiImplTradeScenario(
        label: 'no embassy ⇒ bidTypeCap = 0; suggester emits offers only from current stockpile (riches excluded) and no bids',
        target: OrderSuggestionApiImplTradeTarget
            .noEmbassyBidTypeCapZeroOffersFromStockpileNoBids,
        refs: '#2989 A6',
      ),
      OrderSuggestionApiImplTradeScenario(
        label: 'contextOverride passes through to the pure suggester',
        target:
            OrderSuggestionApiImplTradeTarget.contextOverridePassesThroughToPureSuggester,
        refs: '#2989 A6',
      ),
      OrderSuggestionApiImplTradeScenario(
        label: 'default impl returns validator-clean output for the wired context',
        target: OrderSuggestionApiImplTradeTarget
            .defaultImplReturnsValidatorCleanOutputForWiredContext,
        refs: '#2989 A6',
      ),
    ];
