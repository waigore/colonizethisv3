// Table-driven staged-bid-spend scenarios (Refs #3836).

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_models/colonizethis_models.dart';

import 'trade_order_factory.dart';
import 'treasury_bid_budget_test_support.dart';

/// One row in the [stagedBidSpendScenarios] table.
class StagedBidSpendScenario {
  const StagedBidSpendScenario({
    required this.label,
    required this.orders,
    this.prices,
    this.expectedSpend,
    this.expectedSpendFn,
    this.playerId = humanPlayerId,
    this.refs,
  });

  final String label;
  final Map<CommodityId, int>? prices;
  final List<TradeOrder> orders;
  final int? expectedSpend;
  final int Function(data.ResourceRules rules)? expectedSpendFn;
  final String playerId;
  final String? refs;

  int resolveExpectedSpend(data.ResourceRules rules) {
    if (expectedSpendFn != null) {
      return expectedSpendFn!(rules);
    }
    return expectedSpend ?? 0;
  }
}

/// Canonical scenarios for [stagedBidTotalSpendByPlayer].
List<StagedBidSpendScenario> stagedBidSpendScenarios(data.ResourceRules rules) {
  final int? defaultTimber = rules.defaultMarketPriceForCommodityId('timber');
  final int? defaultLumber = rules.defaultMarketPriceForCommodityId('lumber');

  return [
    const StagedBidSpendScenario(
      label: 'returns 0 when the player has no staged trade orders',
      orders: [],
      prices: {'timber': 30},
      expectedSpend: 0,
      refs: '#3093',
    ),
    StagedBidSpendScenario(
      label: 'returns 0 when the player has only staged offers (no bids)',
      orders: [offerOrder('timber', 5)],
      prices: const {'timber': 30},
      expectedSpend: 0,
      refs: '#3093',
    ),
    StagedBidSpendScenario(
      label: 'sums quantity × effectiveMarketPrice across all staged bids',
      orders: [bidOrder('timber', 4), bidOrder('iron', 2)],
      prices: const {'timber': 30, 'iron': 80},
      expectedSpend: 4 * 30 + 2 * 80,
      refs: '#3093',
    ),
    StagedBidSpendScenario(
      label: 'uses catalog defaults when a bid commodity is missing from prices',
      orders: [bidOrder('timber', 3)],
      prices: const {},
      expectedSpend: 3 * defaultTimber!,
      refs: '#3093',
    ),
    StagedBidSpendScenario(
      label: 'sums spend across raw + manufactured bids using catalog defaults '
          '(Refs #3093 manufactured-default-prices)',
      orders: [bidOrder('lumber', 5), bidOrder('timber', 2)],
      prices: const {},
      expectedSpend: 5 * defaultLumber! + 2 * defaultTimber!,
      refs: '#3093',
    ),
    StagedBidSpendScenario(
      label: 'skips bids on commodities with no effective price (defensive guard '
          'against unknown / future ids)',
      orders: [bidOrder('not_a_commodity', 5), bidOrder('timber', 2)],
      prices: const {},
      expectedSpend: 2 * defaultTimber!,
      refs: null,
    ),
    StagedBidSpendScenario(
      label: 'ignores bids with non-positive quantity (defensive guard)',
      orders: [
        TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.bid,
          quantity: 0,
          priority: 1,
        ),
        bidOrder('timber', 3),
      ],
      prices: const {'timber': 30},
      expectedSpend: 3 * 30,
      refs: null,
    ),
    StagedBidSpendScenario(
      label: 'isolates spend per player (unknown playerId returns 0)',
      orders: [bidOrder('timber', 4)],
      prices: const {'timber': 30},
      expectedSpend: 0,
      playerId: 'gp_ghost',
      refs: null,
    ),
  ];
}
