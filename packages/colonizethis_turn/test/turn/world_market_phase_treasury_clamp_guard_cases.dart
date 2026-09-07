// Guard cases for world_market_phase_treasury_clamp_test (Refs #4740 Slice C).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/world_market_test_support.dart';

void registerWorldMarketTreasuryClampGuardCases() {
  test('treasury never goes negative under any resolved phase outcome', () {
    // Defense for the SPEC purpose: no scenario should leave treasury
    // negative after phase 13 application. Sweep across a few price
    // points to guard against integer-rounding edge cases.
    for (final price in const [7, 13, 30]) {
      final next = runTreasuryClampPhase(
        sellerStockpile: const Stockpile().applyDelta('timber', 50),
        sellerTreasury: 0,
        buyerTreasury: 100,
        marketPrices: {'timber': price},
        orders: Orders(
          tradeOrdersByPlayerId: {
            'gpSeller': [
              TradeOrder(
                commodityId: 'timber',
                type: TradeOrderType.offer,
                quantity: 50,
                priority: 1,
              ),
            ],
            'gpBuyer': [
              TradeOrder(
                commodityId: 'timber',
                type: TradeOrderType.bid,
                quantity: 50,
                priority: 1,
              ),
            ],
          },
        ),
      );

      final buyer = next.players.firstWhere((p) => p.id == 'gpBuyer');
      expect(buyer.treasury, greaterThanOrEqualTo(0),
          reason: 'buyer treasury must not go negative at price $price');
    }
  });

  test('full-fill happy path unchanged when treasury is sufficient', () {
    // Regression guard: with abundant treasury the clamp is inert; the
    // baseline GP↔GP fill (matches `world_market_phase_b3_test`) still
    // produces a 5-unit deal at old price 30.
    final next = runTreasuryClampPhase(
      sellerStockpile: const Stockpile().applyDelta('timber', 10),
      sellerTreasury: 100,
      buyerTreasury: 1000,
      marketPrices: const {'timber': 30},
      orders: Orders(
        tradeOrdersByPlayerId: {
          'gpSeller': [
            TradeOrder(
              commodityId: 'timber',
              type: TradeOrderType.offer,
              quantity: 5,
              priority: 1,
            ),
          ],
          'gpBuyer': [
            TradeOrder(
              commodityId: 'timber',
              type: TradeOrderType.bid,
              quantity: 5,
              priority: 1,
            ),
          ],
        },
      ),
    );

    final buyer = next.players.firstWhere((p) => p.id == 'gpBuyer');
    expect(buyer.treasury, 1000 - 5 * 30);
    expect(buyer.stockpile.quantityOf('timber'), 5);

    final activity = next.worldMarketState.lastTurnActivity['timber']!;
    expect(activity.totalBidQuantity, 5);
    expect(activity.filledQuantity, 5);
    expect(activity.notes, isEmpty,
        reason: 'no truncation notes when treasury is sufficient');
  });
}
