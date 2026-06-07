// Unit tests for `stagedBidTotalSpendByPlayer` (Refs #3093).
//
// SPEC/game/world-market.md § Treasury budget for bids,
// SPEC/ui/trade-screen.md § Market tab — treasury bid cap.

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'world_market_treasury_bid_budget_test_support.dart';

void main() {
  final data.ResourceRules rules = data.ResourceRules.defaultRules;

  group('stagedBidTotalSpendByPlayer (Refs #3093)', () {
    test('returns 0 when the player has no staged trade orders', () {
      final game = buildTreasuryBidBudgetGame(prices: const {'timber': 30});
      expect(
        stagedBidTotalSpendByPlayer(
          orders: const Orders(),
          playerId: humanPlayerId,
          game: game,
          resourceRules: rules,
        ),
        0,
      );
    });

    test('returns 0 when the player has only staged offers (no bids)', () {
      final game = buildTreasuryBidBudgetGame(prices: const {'timber': 30});
      final orders = humanOrdersWith([offerOrder('timber', 5)]);
      expect(
        stagedBidTotalSpendByPlayer(
          orders: orders,
          playerId: humanPlayerId,
          game: game,
          resourceRules: rules,
        ),
        0,
      );
    });

    test('sums quantity × effectiveMarketPrice across all staged bids', () {
      final game = buildTreasuryBidBudgetGame(
        prices: const {'timber': 30, 'iron': 80},
      );
      final orders = humanOrdersWith([
        bidOrder('timber', 4),
        bidOrder('iron', 2),
      ]);
      expect(
        stagedBidTotalSpendByPlayer(
          orders: orders,
          playerId: humanPlayerId,
          game: game,
          resourceRules: rules,
        ),
        4 * 30 + 2 * 80,
      );
    });

    test(
      'uses catalog defaults when a bid commodity is missing from prices',
      () {
        final game = buildTreasuryBidBudgetGame(
          prices: const <CommodityId, int>{},
        );
        final int? defaultTimber = rules.defaultMarketPriceForCommodityId(
          'timber',
        );
        expect(defaultTimber, isNotNull);
        final orders = humanOrdersWith([bidOrder('timber', 3)]);
        expect(
          stagedBidTotalSpendByPlayer(
            orders: orders,
            playerId: humanPlayerId,
            game: game,
            resourceRules: rules,
          ),
          3 * defaultTimber!,
        );
      },
    );

    test('sums spend across raw + manufactured bids using catalog defaults '
        '(Refs #3093 manufactured-default-prices)', () {
      final game = buildTreasuryBidBudgetGame(
        prices: const <CommodityId, int>{},
      );
      final int? defaultLumber = rules.defaultMarketPriceForCommodityId(
        'lumber',
      );
      final int? defaultTimber = rules.defaultMarketPriceForCommodityId(
        'timber',
      );
      expect(defaultLumber, isNotNull);
      expect(defaultTimber, isNotNull);
      final orders = humanOrdersWith([
        bidOrder('lumber', 5),
        bidOrder('timber', 2),
      ]);
      expect(
        stagedBidTotalSpendByPlayer(
          orders: orders,
          playerId: humanPlayerId,
          game: game,
          resourceRules: rules,
        ),
        5 * defaultLumber! + 2 * defaultTimber!,
      );
    });

    test('skips bids on commodities with no effective price (defensive guard '
        'against unknown / future ids)', () {
      final game = buildTreasuryBidBudgetGame(
        prices: const <CommodityId, int>{},
      );
      expect(rules.defaultMarketPriceForCommodityId('not_a_commodity'), isNull);
      final orders = humanOrdersWith([
        bidOrder('not_a_commodity', 5),
        bidOrder('timber', 2),
      ]);
      final int? defaultTimber = rules.defaultMarketPriceForCommodityId(
        'timber',
      );
      expect(defaultTimber, isNotNull);
      expect(
        stagedBidTotalSpendByPlayer(
          orders: orders,
          playerId: humanPlayerId,
          game: game,
          resourceRules: rules,
        ),
        2 * defaultTimber!,
      );
    });

    test('ignores bids with non-positive quantity (defensive guard)', () {
      final game = buildTreasuryBidBudgetGame(prices: const {'timber': 30});
      final orders = humanOrdersWith([
        TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.bid,
          quantity: 0,
          priority: 1,
        ),
        bidOrder('timber', 3),
      ]);
      expect(
        stagedBidTotalSpendByPlayer(
          orders: orders,
          playerId: humanPlayerId,
          game: game,
          resourceRules: rules,
        ),
        3 * 30,
        reason: 'quantity == 0 should contribute nothing to the running total',
      );
    });

    test('isolates spend per player (unknown playerId returns 0)', () {
      final game = buildTreasuryBidBudgetGame(prices: const {'timber': 30});
      final orders = humanOrdersWith([bidOrder('timber', 4)]);
      expect(
        stagedBidTotalSpendByPlayer(
          orders: orders,
          playerId: 'gp_ghost',
          game: game,
          resourceRules: rules,
        ),
        0,
      );
    });
  });
}
