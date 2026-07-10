// Table-driven OrderEngine validateTrade scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_engine_validate_trade_run_rows.dart';

class OrderEngineValidateTradeScenario implements RefsScenario {
  const OrderEngineValidateTradeScenario({
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

void runOrderEngineValidateTradeScenario(
  OrderEngineValidateTradeScenario scenario,
) =>
    scenario.run();

List<OrderEngineValidateTradeScenario> orderEngineValidateTradeScenarios() =>
    const [
      // dart format off
      OrderEngineValidateTradeScenario(
        label: 'accepts a valid offer when stockpile covers quantity',
        run: vetRunAcceptsValidOfferWhenStockpileCoversQuantity,
      ),
      OrderEngineValidateTradeScenario(
        label: 'rejects mutual exclusion when bid and offer share a commodity',
        run: vetRunRejectsMutualExclusionWhenBidAndOfferShareACommodity,
      ),
      OrderEngineValidateTradeScenario(
        label: 'rejects offer exceeding available stockpile',
        run: vetRunRejectsOfferExceedingAvailableStockpile,
      ),
      OrderEngineValidateTradeScenario(
        label: 'accepts first bid when player has no embassy (baseline bid type cap 1 per Refs #2924; SPEC/game/world-market.md § Bid type cap)',
        run: vetRunAcceptsFirstBidWhenPlayerHasNoEmbassy,
      ),
      OrderEngineValidateTradeScenario(
        label: 'rejects second distinct-commodity bid when no embassy (baseline bid type cap == 1 exhausted; Refs #2924)',
        run: vetRunRejectsSecondDistinctCommodityBidWhenNoEmbassy,
      ),
      // dart format on
    ];
