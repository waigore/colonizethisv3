// Unit tests for `carryForwardBidNotionalByPlayer` (Refs #3122).
//
// SPEC/ai/treasury-planner.md § Treasury-budget-aware bid sizing.

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

const String _gp = 'gp1';

Game _gameWithCarryForwardBids(
  List<TradeOrder> bids, {
  Map<CommodityId, int>? prices,
}) => carryForwardBidGame(
  bids,
  playerId: _gp,
  prices: prices ?? const <CommodityId, int>{},
  treasury: 1000,
  gameId: 'g_carryfwd',
);

TradeOrder _bid(String commodityId, int qty, {int priority = 3}) =>
    testBid(commodityId, qty, priority: priority);

void main() {
  final data.ResourceRules rules = data.ResourceRules.defaultRules;

  group('carryForwardBidNotionalByPlayer (Refs #3122)', () {
    // The empty-list (returns 0), positive summation (quantity * effectivePrice),
    // unpriced/unknown-id skip, and offer / zero-quantity skip behaviours are
    // pinned against `carryForwardBidNotionalByPlayer` directly by the shared
    // parity suite `world_market_bid_spend_shared_helper_test.dart` (Refs #3427),
    // which proves staged and carry-forward entry points compute identical
    // totals. This file retains only the catalog-default fallback case, which
    // the parity suite (explicit prices) does not exercise.

    test('falls back to catalog default price when world price is missing', () {
      final catalogTimber =
          rules.defaultMarketPriceForCommodityId('timber') ?? 0;
      expect(catalogTimber, greaterThan(0));
      final game = _gameWithCarryForwardBids([
        _bid('timber', 4),
      ], prices: const <CommodityId, int>{});
      expect(
        carryForwardBidNotionalByPlayer(
          game: game,
          playerId: _gp,
          resourceRules: rules,
        ),
        4 * catalogTimber,
      );
    });
  });
}
