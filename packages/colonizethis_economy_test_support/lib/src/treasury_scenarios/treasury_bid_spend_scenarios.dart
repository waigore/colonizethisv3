// Staged/carry-forward bid-spend scenario tables (Refs #3427, #3836, #3939).

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../trade_order_factory.dart';
import 'treasury_expectations.dart';
import 'treasury_test_support.dart';

const String _gp = 'gp_h';

/// One row in [stagedBidSpendScenarios].
typedef StagedBidSpendScenario = ({
  String label,
  Map<CommodityId, int>? prices,
  List<TradeOrder> orders,
  int? expectedSpend,
  int Function(data.ResourceRules rules)? expectedSpendFn,
  String playerId,
  String? refs,
});

int resolveStagedBidSpendExpected(
  StagedBidSpendScenario scenario,
  data.ResourceRules rules,
) {
  if (scenario.expectedSpendFn != null) {
    return scenario.expectedSpendFn!(rules);
  }
  return scenario.expectedSpend ?? 0;
}

void runStagedBidSpendScenario(
  StagedBidSpendScenario scenario,
  data.ResourceRules rules,
) {
  final game = buildTreasuryBidBudgetGame(prices: scenario.prices);
  final orders = scenario.orders.isEmpty
      ? const Orders()
      : humanOrdersWith(scenario.orders);
  expect(
    stagedBidTotalSpendByPlayer(
      orders: orders,
      playerId: scenario.playerId,
      game: game,
      resourceRules: rules,
    ),
    resolveStagedBidSpendExpected(scenario, rules),
    reason:
        scenario.label ==
            'ignores bids with non-positive quantity '
                '(defensive guard)'
        ? 'quantity == 0 should contribute nothing to the running total'
        : null,
  );
}

List<StagedBidSpendScenario> stagedBidSpendScenarios(data.ResourceRules rules) {
  return [
    stagedBidSpendRow(
      label: 'returns 0 when the player has no staged trade orders',
      orders: <TradeOrder>[],
      prices: const {'timber': 30},
      expectedSpend: 0,
    ),
    stagedBidSpendRow(
      label: 'returns 0 when the player has only staged offers (no bids)',
      orders: [offerOrder('timber', 5)],
      prices: const {'timber': 30},
      expectedSpend: 0,
    ),
    stagedBidSpendRow(
      label: 'sums quantity × effectiveMarketPrice across all staged bids',
      orders: [bidOrder('timber', 4), bidOrder('iron', 2)],
      prices: const {'timber': 30, 'iron': 80},
      expectedSpend: 4 * 30 + 2 * 80,
    ),
    stagedBidSpendRow(
      label:
          'uses catalog defaults when a bid commodity is missing from prices',
      orders: [bidOrder('timber', 3)],
      prices: const <CommodityId, int>{},
      expectedSpendFn: (rules) =>
          3 * rules.defaultMarketPriceForCommodityId('timber')!,
    ),
    stagedBidSpendRow(
      label:
          'sums spend across raw + manufactured bids using catalog defaults '
          '(Refs #3093 manufactured-default-prices)',
      orders: [bidOrder('lumber', 5), bidOrder('timber', 2)],
      prices: const <CommodityId, int>{},
      expectedSpendFn: (rules) =>
          5 * rules.defaultMarketPriceForCommodityId('lumber')! +
          2 * rules.defaultMarketPriceForCommodityId('timber')!,
    ),
    stagedBidSpendRow(
      label:
          'skips bids on commodities with no effective price (defensive guard '
          'against unknown / future ids)',
      orders: [bidOrder('not_a_commodity', 5), bidOrder('timber', 2)],
      prices: const <CommodityId, int>{},
      expectedSpendFn: (rules) =>
          2 * rules.defaultMarketPriceForCommodityId('timber')!,
      refs: null,
    ),
    stagedBidSpendRow(
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
    stagedBidSpendRow(
      label: 'isolates spend per player (unknown playerId returns 0)',
      orders: [bidOrder('timber', 4)],
      prices: const {'timber': 30},
      expectedSpend: 0,
      playerId: 'gp_ghost',
      refs: null,
    ),
  ];
}

class CarryForwardBidNotionalScenario {
  const CarryForwardBidNotionalScenario({
    required this.label,
    required this.bids,
    required this.prices,
    required this.verify,
    this.playerId = 'gp1',
    this.refs,
  });

  final String label;
  final List<TradeOrder> bids;
  final Map<CommodityId, int> prices;
  final String playerId;
  final void Function(int notional, data.ResourceRules rules) verify;
  final String? refs;
}

void runCarryForwardBidNotionalScenario(
  CarryForwardBidNotionalScenario scenario,
  data.ResourceRules rules,
) {
  final game = carryForwardBidGame(
    scenario.bids,
    playerId: scenario.playerId,
    prices: scenario.prices,
    gameId: 'g_carryfwd',
  );
  final notional = carryForwardBidNotionalByPlayer(
    game: game,
    playerId: scenario.playerId,
    resourceRules: rules,
  );
  scenario.verify(notional, rules);
}

List<CarryForwardBidNotionalScenario> carryForwardBidNotionalScenarios() => [
  CarryForwardBidNotionalScenario(
    label: 'falls back to catalog default price when world price is missing',
    bids: [testBid('timber', 4)],
    prices: const <CommodityId, int>{},
    verify: (notional, rules) => assertCarryForwardBidNotionalExpectation(
      notional: notional,
      rules: rules,
      expectation: const CarryForwardBidNotionalExpectation(
        catalogCommodity: 'timber',
        quantity: 4,
      ),
    ),
    refs: '#3122',
  ),
];

typedef BidSpendParityScenario = ({
  String label,
  List<TradeOrder> bids,
  Map<CommodityId, int> prices,
  String playerId,
  BidSpendParityExpectation expect,
});

BidSpendParityScenario bidSpendParityScenarioExpect({
  required String label,
  required List<TradeOrder> bids,
  required Map<CommodityId, int> prices,
  String playerId = _gp,
  required BidSpendParityExpectation expect,
}) => (
  label: label,
  bids: bids,
  prices: prices,
  playerId: playerId,
  expect: expect,
);

void runBidSpendParityScenario(
  BidSpendParityScenario scenario,
  data.ResourceRules rules,
) {
  final game = carryForwardBidGame(
    scenario.bids,
    playerId: scenario.playerId,
    prices: scenario.prices,
    gameId: 'g_bid_spend_parity',
  );
  final staged = stagedBidTotalSpendByPlayer(
    orders: Orders(tradeOrdersByPlayerId: {scenario.playerId: scenario.bids}),
    playerId: scenario.playerId,
    game: game,
    resourceRules: rules,
  );
  final carryForward = carryForwardBidNotionalByPlayer(
    game: game,
    playerId: scenario.playerId,
    resourceRules: rules,
  );
  assertBidSpendParityExpectation(
    staged: staged,
    carryForward: carryForward,
    game: game,
    rules: rules,
    expectation: scenario.expect,
  );
}

List<BidSpendParityScenario> bidSpendParityScenarios() => [
  bidSpendParityScenarioExpect(
    label: 'staged and carry-forward totals match for an identical bid list',
    bids: [testBid('timber', 4), testBid('iron', 2)],
    prices: const {'timber': 30, 'iron': 80},
    expect: const BidSpendParityExpectation(stagedSpend: 4 * 30 + 2 * 80),
  ),
  bidSpendParityScenarioExpect(
    label:
        'both apply identical defensive skips '
        '(offers, zero qty, unpriced ids)',
    bids: [
      testOffer('timber', 9),
      testBid('timber', 0),
      testBid('not_a_commodity', 5),
      testBid('iron', 3),
    ],
    prices: const {'timber': 30, 'iron': 80},
    expect: const BidSpendParityExpectation(
      stagedSpend: 3 * 80,
      carryForwardEqualsStaged: true,
    ),
  ),
  bidSpendParityScenarioExpect(
    label: 'both return 0 for an empty bid list',
    bids: const [],
    prices: const {'timber': 30},
    expect: const BidSpendParityExpectation(stagedSpend: 0),
  ),
  bidSpendParityScenarioExpect(
    label: 'bidTreasurySpendForOrder matches per-order summation core',
    bids: [testBid('timber', 4)],
    prices: const {'timber': 30},
    expect: BidSpendParityExpectation(
      carryForwardEqualsStaged: false,
      bidTreasurySpendPins: [
        (order: testBid('timber', 4), expected: 120, reason: null),
        (
          order: testOffer('timber', 4),
          expected: 0,
          reason: 'offers do not spend treasury',
        ),
        (
          order: testBid('unknown', 4),
          expected: 0,
          reason: 'unpriced commodities contribute 0',
        ),
      ],
    ),
  ),
];
