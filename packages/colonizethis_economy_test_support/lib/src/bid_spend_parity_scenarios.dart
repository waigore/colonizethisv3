// Table-driven bid-spend helper parity scenarios (Refs #3427, #3856).

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'bid_spend_game_factory.dart';
import 'trade_order_factory.dart';

const String _gp = 'gp_h';

/// One row in [bidSpendParityScenarios].
typedef BidSpendParityScenario = ({
  String label,
  void Function(data.ResourceRules rules) run,
});

/// Canonical scenarios for staged vs carry-forward bid-spend parity.
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
