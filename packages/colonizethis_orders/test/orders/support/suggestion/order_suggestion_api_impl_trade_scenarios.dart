// Table-driven trade API impl suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_api_impl_trade_run_rows.dart';

/// One row in [orderSuggestionApiImplTradeScenarios].
class OrderSuggestionApiImplTradeScenario implements RefsScenario {
  const OrderSuggestionApiImplTradeScenario({
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

void runOrderSuggestionApiImplTradeScenario(
  OrderSuggestionApiImplTradeScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionApiImplTradeScenario>
orderSuggestionApiImplTradeScenarios() => const [
  OrderSuggestionApiImplTradeScenario(
    label:
        'no embassy ⇒ bidTypeCap = 0; suggester emits offers only from current stockpile (riches excluded) and no bids',
    run: osaitRunNoEmbassyBidTypeCapZeroOffersFromStockpileNoBids,
    refs: '#2989 A6',
  ),
  OrderSuggestionApiImplTradeScenario(
    label: 'contextOverride passes through to the pure suggester',
    run: osaitRunContextOverridePassesThroughToPureSuggester,
    refs: '#2989 A6',
  ),
  OrderSuggestionApiImplTradeScenario(
    label: 'default impl returns validator-clean output for the wired context',
    run: osaitRunDefaultImplReturnsValidatorCleanOutputForWiredContext,
    refs: '#2989 A6',
  ),
];
