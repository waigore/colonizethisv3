// Table-driven OrderEngine validateTrade scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_engine_validate_trade_expectations.dart';

class OrderEngineValidateTradeScenario implements RefsScenario {
  const OrderEngineValidateTradeScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderEngineValidateTradeTarget target;
  @override
  final String? refs;
}

void runOrderEngineValidateTradeScenario(
  OrderEngineValidateTradeScenario scenario,
) {
  runOrderEngineValidateTradeExpectation(scenario.target);
}

List<OrderEngineValidateTradeScenario>
orderEngineValidateTradeScenarios() => const [
  // dart format off
      OrderEngineValidateTradeScenario(
        label: 'accepts a valid offer when stockpile covers quantity',
        target: OrderEngineValidateTradeTarget.acceptsAValidOfferWhenStockpileCoversQuantity,
      ),
      OrderEngineValidateTradeScenario(
        label: 'rejects mutual exclusion when bid and offer share a commodity',
        target: OrderEngineValidateTradeTarget.rejectsMutualExclusionWhenBidAndOfferShareACommodity,
      ),
      OrderEngineValidateTradeScenario(
        label: 'rejects offer exceeding available stockpile',
        target: OrderEngineValidateTradeTarget.rejectsOfferExceedingAvailableStockpile,
      ),
      OrderEngineValidateTradeScenario(
        label: 'accepts first bid when player has no embassy (baseline bid type cap 1 per Refs #2924; SPEC/game/world-market.md § Bid type cap)',
        target: OrderEngineValidateTradeTarget.acceptsFirstBidWhenPlayerHasNoEmbassy,
      ),
      OrderEngineValidateTradeScenario(
        label: 'rejects second distinct-commodity bid when no embassy (baseline bid type cap == 1 exhausted; Refs #2924)',
        target: OrderEngineValidateTradeTarget.rejectsSecondDistinctCommodityBidWhenNoEmbassy,
      ),
      // dart format on
];
