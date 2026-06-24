// Parity tests for the shared bid-spend summation helper (Refs #3427).
//
// `stagedBidTotalSpendByPlayer` (staged orders) and
// `carryForwardBidNotionalByPlayer` (carry-forward bids) now delegate to one
// private `_sumBidSpend` core whose only varying input is the source iterable.
// These tests pin that the two public entry points compute identical totals for
// identical bid lists and apply the same defensive skips (offers, non-positive
// quantities, unpriced commodities), guarding against future drift between the
// two call sites.

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

const String _gp = 'gp_h';

Game _gameWith(List<TradeOrder> bids, {required Map<CommodityId, int> prices}) =>
    carryForwardBidGame(
      bids,
      playerId: _gp,
      prices: prices,
      gameId: 'g_bid_spend_parity',
    );

TradeOrder _bid(String commodityId, int qty) => testBid(commodityId, qty);

TradeOrder _offer(String commodityId, int qty) => testOffer(commodityId, qty);

void main() {
  final data.ResourceRules rules = data.ResourceRules.defaultRules;

  group('shared bid-spend helper parity (Refs #3427)', () {
    test('staged and carry-forward totals match for an identical bid list', () {
      final bids = [_bid('timber', 4), _bid('iron', 2)];
      final game = _gameWith(bids, prices: const {'timber': 30, 'iron': 80});
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
    });

    test('both apply identical defensive skips '
        '(offers, zero qty, unpriced ids)', () {
      final list = [
        _offer('timber', 9),
        _bid('timber', 0),
        _bid('not_a_commodity', 5),
        _bid('iron', 3),
      ];
      final game = _gameWith(list, prices: const {'timber': 30, 'iron': 80});
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
    });

    test('both return 0 for an empty bid list', () {
      final game = _gameWith(const [], prices: const {'timber': 30});
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
    });
  });
}
