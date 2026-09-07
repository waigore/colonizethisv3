// Preserved-carry-forward cases for b3 revalidation (Refs #4740 Slice C).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/world_market_test_support.dart';
import 'world_market_phase_b3_carry_forward_revalidation_cases.dart';

void registerB3CarryForwardPreservedCases() {
  test('carry-forward offer that still fits stockpile is preserved and '
      'matches normally', () {
    final next = runWorldMarketPhase(
      game: b3CarryForwardGame(
        priorMarket: b3PriorMarket(
          carryForwardOffersByFactionId: {
            'gpSeller': [
              b3TimberOrder(type: TradeOrderType.offer, quantity: 3),
            ],
          },
        ),
        sellerStockpile: const Stockpile().applyDelta('timber', 5),
        buyerTreasury: 1000,
      ),
      orders: Orders(
        tradeOrdersByPlayerId: {
          'gpBuyer': [b3TimberOrder(type: TradeOrderType.bid, quantity: 3)],
        },
      ),
    );

    final buyer = next.players.firstWhere((p) => p.id == 'gpBuyer');
    final seller = next.players.firstWhere((p) => p.id == 'gpSeller');
    expect(
      buyer.stockpile.quantityOf('timber'),
      3,
      reason: 'kept carry-forward offer fills the bid',
    );
    expect(seller.stockpile.quantityOf('timber'), 2);
    expect(buyer.treasury, 1000 - 3 * 30);
    expect(seller.treasury, 0 + 3 * 30);
    final activity = next.worldMarketState.lastTurnActivity['timber']!;
    expect(activity.filledQuantity, 3);
    expect(
      activity.notes,
      isEmpty,
      reason:
          'no drops when carry-forwards satisfy start-of-turn constraints',
    );
  });

  test('cumulative cargo check drops only the bids that exceed capacity '
      '(earlier carry-forwards keep their slots)', () {
    final next = runWorldMarketPhase(
      game: b3CarryForwardGame(
        priorMarket: b3PriorMarket(
          prices: const {'timber': 30, 'iron': 80},
          carryForwardBidsByFactionId: {
            'gpBuyer': [
              TradeOrder(
                commodityId: 'timber',
                type: TradeOrderType.bid,
                quantity: 20,
                priority: 2,
              ),
              TradeOrder(
                commodityId: 'iron',
                type: TradeOrderType.bid,
                quantity: 10,
                priority: 1,
              ),
            ],
          },
        ),
        sellerStockpile: Stockpile.empty,
        buyerTreasury: 100000,
        marketPrices: const {'timber': 30, 'iron': 80},
      ),
      orders: const Orders(),
    );

    final carriedBids =
        next.worldMarketState.carryForwardBidsByFactionId['gpBuyer'];
    expect(carriedBids, isNotNull);
    expect(carriedBids!.length, 1);
    expect(carriedBids.single.commodityId, 'timber');
    expect(carriedBids.single.quantity, 20);
    final ironActivity = next.worldMarketState.lastTurnActivity['iron']!;
    expect(ironActivity.notes, hasLength(1));
    expect(
      ironActivity.notes.single.kind,
      MarketActivityNoteKind.carryForwardDroppedCargoInsufficient,
    );
    expect(ironActivity.notes.single.factionId, 'gpBuyer');
    expect(ironActivity.notes.single.quantity, 10);
    final timberActivity = next.worldMarketState.lastTurnActivity['timber'];
    if (timberActivity != null) {
      expect(timberActivity.notes, isEmpty);
    }
  });
}
