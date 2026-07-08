// Staged/carry-forward bid-spend and GP treasury-credit scenario tables
// (Refs #3427, #3836, #3856, #3939 phase 3 slice 6).

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../trade_order_factory.dart';
import 'treasury_expectations.dart';
import 'treasury_test_support.dart';

const String _gp = 'gp_h';

/// One row in [stagedBidSpendScenarios].
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

class CarryForwardBidNotionalScenario {
  const CarryForwardBidNotionalScenario({
    required this.label,
    required this.bids,
    required this.prices,
    required this.verify,
    this.playerId = 'gp1',
    this.refs,
  });

  CarryForwardBidNotionalScenario.expect({
    required String label,
    required List<TradeOrder> bids,
    required Map<CommodityId, int> prices,
    required CarryForwardBidNotionalExpectation expect,
    String playerId = 'gp1',
    String? refs,
  }) : this(
          label: label,
          bids: bids,
          prices: prices,
          playerId: playerId,
          verify: (notional, rules) => assertCarryForwardBidNotionalExpectation(
                notional: notional,
                rules: rules,
                expectation: expect,
              ),
          refs: refs,
        );

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
  CarryForwardBidNotionalScenario.expect(
    label: 'falls back to catalog default price when world price is missing',
    bids: [testBid('timber', 4)],
    prices: const <CommodityId, int>{},
    expect: const CarryForwardBidNotionalExpectation(
      catalogCommodity: 'timber',
      quantity: 4,
    ),
    refs: '#3122',
  ),
];

typedef BidSpendParityScenario = ({
  String label,
  void Function(data.ResourceRules rules) run,
});

List<BidSpendParityScenario> bidSpendParityScenarios() => [
  (
    label: 'staged and carry-forward totals match for an identical bid list',
    run: (rules) {
      final bids = [testBid('timber', 4), testBid('iron', 2)];
      final game = carryForwardBidGame(
        bids,
        playerId: _gp,
        prices: const {'timber': 30, 'iron': 80},
        gameId: 'g_bid_spend_parity',
      );
      final staged = stagedBidTotalSpendByPlayer(
        orders: Orders(tradeOrdersByPlayerId: {_gp: bids}),
        playerId: _gp,
        game: game,
        resourceRules: rules,
      );
      final carryForward = carryForwardBidNotionalByPlayer(
        game: game,
        playerId: _gp,
        resourceRules: rules,
      );
      expect(staged, 4 * 30 + 2 * 80);
      expect(
        carryForward,
        staged,
        reason: 'both entry points must delegate to the same summation core',
      );
    },
  ),
  (
    label: 'both apply identical defensive skips '
        '(offers, zero qty, unpriced ids)',
    run: (rules) {
      final list = [
        testOffer('timber', 9),
        testBid('timber', 0),
        testBid('not_a_commodity', 5),
        testBid('iron', 3),
      ];
      final game = carryForwardBidGame(
        list,
        playerId: _gp,
        prices: const {'timber': 30, 'iron': 80},
        gameId: 'g_bid_spend_parity',
      );
      final staged = stagedBidTotalSpendByPlayer(
        orders: Orders(tradeOrdersByPlayerId: {_gp: list}),
        playerId: _gp,
        game: game,
        resourceRules: rules,
      );
      final carryForward = carryForwardBidNotionalByPlayer(
        game: game,
        playerId: _gp,
        resourceRules: rules,
      );
      expect(
        staged,
        3 * 80,
        reason: 'only the priced positive iron bid counts',
      );
      expect(carryForward, staged);
    },
  ),
  (
    label: 'both return 0 for an empty bid list',
    run: (rules) {
      final game = carryForwardBidGame(
        const [],
        playerId: _gp,
        prices: const {'timber': 30},
        gameId: 'g_bid_spend_parity',
      );
      expect(
        stagedBidTotalSpendByPlayer(
          orders: const Orders(),
          playerId: _gp,
          game: game,
          resourceRules: rules,
        ),
        0,
      );
      expect(
        carryForwardBidNotionalByPlayer(
          game: game,
          playerId: _gp,
          resourceRules: rules,
        ),
        0,
      );
    },
  ),
  (
    label: 'bidTreasurySpendForOrder matches per-order summation core',
    run: (rules) {
      final bid = testBid('timber', 4);
      final game = carryForwardBidGame(
        [bid],
        playerId: _gp,
        prices: const {'timber': 30},
        gameId: 'g_bid_spend_parity',
      );
      expect(
        bidTreasurySpendForOrder(
          order: bid,
          worldMarket: game.worldMarketState,
          resourceRules: rules,
        ),
        120,
      );
      expect(
        bidTreasurySpendForOrder(
          order: testOffer('timber', 4),
          worldMarket: game.worldMarketState,
          resourceRules: rules,
        ),
        0,
        reason: 'offers do not spend treasury',
      );
      expect(
        bidTreasurySpendForOrder(
          order: testBid('unknown', 4),
          worldMarket: game.worldMarketState,
          resourceRules: rules,
        ),
        0,
        reason: 'unpriced commodities contribute 0',
      );
    },
  ),
];

typedef GpTreasuryCreditIntScenario = ({
  String label,
  void Function(GpTreasuryCreditAccumulator<int> acc) setup,
  void Function(GpTreasuryCreditAccumulator<int> acc) verify,
  String? refs,
});

GpTreasuryCreditIntScenario gpTreasuryCreditIntScenarioExpect({
  required String label,
  void Function(GpTreasuryCreditAccumulator<int> acc)? setup,
  required GpTreasuryCreditExpectation<int> expect,
  String? refs,
}) =>
    (
      label: label,
      setup: setup ?? (_) {},
      verify: (acc) => assertGpTreasuryCreditExpectation(acc, expect),
      refs: refs,
    );

List<GpTreasuryCreditIntScenario> gpTreasuryCreditIntScenarios() => [
  gpTreasuryCreditIntScenarioExpect(
    label: 'starts empty with a zero total',
    expect: const GpTreasuryCreditExpectation<int>(
      isEmpty: true,
      total: 0,
      view: {},
    ),
  ),
  gpTreasuryCreditIntScenarioExpect(
    label: 'add creates and accumulates entries, total stays incremental',
    setup: (acc) => acc
      ..add('gpA', 10)
      ..add('gpB', 5)
      ..add('gpA', 3),
    expect: const GpTreasuryCreditExpectation<int>(
      view: {'gpA': 13, 'gpB': 5},
      total: 18,
      isEmpty: false,
    ),
  ),
  gpTreasuryCreditIntScenarioExpect(
    label: 'view preserves first-seen insertion order',
    setup: (acc) => acc
      ..add('gpC', 1)
      ..add('gpA', 1)
      ..add('gpB', 1)
      ..add('gpA', 1),
    expect: const GpTreasuryCreditExpectation<int>(
      viewKeyOrder: ['gpC', 'gpA', 'gpB'],
    ),
  ),
  gpTreasuryCreditIntScenarioExpect(
    label: 'view is unmodifiable',
    setup: (acc) => acc.add('gpA', 1),
    expect: const GpTreasuryCreditExpectation<int>(viewUnmodifiable: true),
  ),
  gpTreasuryCreditIntScenarioExpect(
    label: 'incremental total equals the naive re-summed view total',
    setup: (acc) => acc
      ..add('gpA', 7)
      ..add('gpB', 11)
      ..add('gpA', 2),
    expect: const GpTreasuryCreditExpectation<int>(totalEqualsNaiveViewSum: true),
  ),
];

typedef GpTreasuryCreditDoubleScenario = ({
  String label,
  void Function(GpTreasuryCreditAccumulator<double> acc) setup,
  void Function(GpTreasuryCreditAccumulator<double> acc) verify,
  String? refs,
});

GpTreasuryCreditDoubleScenario gpTreasuryCreditDoubleScenarioExpect({
  required String label,
  void Function(GpTreasuryCreditAccumulator<double> acc)? setup,
  required GpTreasuryCreditExpectation<double> expect,
  String? refs,
}) =>
    (
      label: label,
      setup: setup ?? (_) {},
      verify: (acc) => assertGpTreasuryCreditExpectation(acc, expect),
      refs: refs,
    );

List<GpTreasuryCreditDoubleScenario> gpTreasuryCreditDoubleScenarios() => [
  gpTreasuryCreditDoubleScenarioExpect(
    label: 'ensure records a zero entry without changing the total',
    setup: (acc) => acc
      ..add('gpA', 40.0)
      ..ensure('gpB'),
    expect: const GpTreasuryCreditExpectation<double>(
      view: {'gpA': 40.0, 'gpB': 0.0},
      total: 40.0,
    ),
  ),
  gpTreasuryCreditDoubleScenarioExpect(
    label: 'ensure is a no-op when the key already has a credit',
    setup: (acc) => acc
      ..add('gpA', 12.5)
      ..ensure('gpA'),
    expect: const GpTreasuryCreditExpectation<double>(
      view: {'gpA': 12.5},
      total: 12.5,
    ),
  ),
  gpTreasuryCreditDoubleScenarioExpect(
    label: 'total matches naive re-sum including a zero-profit entry',
    setup: (acc) => acc
      ..add('gpA', 4.6)
      ..add('gpB', 40.0)
      ..ensure('gpC')
      ..add('gpA', 0.4),
    expect: const GpTreasuryCreditExpectation<double>(
      totalEqualsNaiveViewSum: true,
      viewCloseTo: {'gpC': 0.0},
    ),
  ),
];

void runGpTreasuryCreditIntScenario(GpTreasuryCreditIntScenario scenario) {
  final acc = GpTreasuryCreditAccumulator<int>(0);
  scenario.setup(acc);
  scenario.verify(acc);
}

void runGpTreasuryCreditDoubleScenario(
  GpTreasuryCreditDoubleScenario scenario,
) {
  final acc = GpTreasuryCreditAccumulator<double>(0.0);
  scenario.setup(acc);
  scenario.verify(acc);
}
