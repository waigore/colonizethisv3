import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'world_market_phase_b3_carry_forward_revalidation_cases.dart';

/// Integration tests for the carry-forward re-validation branch of
/// `worldMarketTurnPhaseHandler` (Refs #2990 B3 follow-up).
///
/// SPEC anchors:
/// - `SPEC/game/world-market.md` § Order persistence — drop on stockpile /
///   cargo shortfall.
/// - `SPEC/program/world-market-resolution.md` § Step A Gather (A.3) — drop
///   carry-forward offers/bids whose submitter no longer meets the
///   stockpile/cargo precondition, recording a [MarketActivityNote] per drop.
void main() {
  group('worldMarketTurnPhaseHandler — carry-forward re-validation '
      '(Refs #2990 B3 follow-up, SPEC/game/world-market.md § Order persistence, '
      'SPEC/program/world-market-resolution.md § Step A Gather)', () {
    test('carry-forward offer dropped when start-of-turn stockpile is below '
        'order quantity (note recorded, order not used in matching)', () {
      final next = runB3CarryForwardPhase(
        priorMarket: b3PriorMarket(
          carryForwardOffersByFactionId: {
            'gpSeller': [
              b3TimberOrder(type: TradeOrderType.offer, quantity: 5),
            ],
          },
        ),
        sellerStockpile: const Stockpile().applyDelta('timber', 2),
        buyerTreasury: 1000,
        orders: Orders(
          tradeOrdersByPlayerId: {
            'gpBuyer': [b3TimberOrder(type: TradeOrderType.bid, quantity: 5)],
          },
        ),
      );

      final buyer = next.players.firstWhere((p) => p.id == 'gpBuyer');
      final seller = next.players.firstWhere((p) => p.id == 'gpSeller');
      expect(
        buyer.stockpile.quantityOf('timber'),
        0,
        reason: 'dropped offer cannot fill the bid',
      );
      expect(
        buyer.treasury,
        1000,
        reason: 'no fill -> no treasury movement on buyer',
      );
      expect(
        seller.stockpile.quantityOf('timber'),
        2,
        reason: 'seller stockpile unchanged when offer is dropped',
      );
      expect(seller.treasury, 0);
      final activity = next.worldMarketState.lastTurnActivity['timber']!;
      expect(activity.filledQuantity, 0);
      expect(activity.notes, hasLength(1));
      expect(
        activity.notes.single.kind,
        MarketActivityNoteKind.carryForwardDroppedStockpileInsufficient,
      );
      expect(activity.notes.single.factionId, 'gpSeller');
      expect(activity.notes.single.commodityId, 'timber');
      expect(activity.notes.single.quantity, 5);
      expect(
        next.worldMarketState.carryForwardOffersByFactionId,
        isEmpty,
        reason: 'dropped offer is not re-emitted as a new carry-forward',
      );
      final carriedBids =
          next.worldMarketState.carryForwardBidsByFactionId['gpBuyer'];
      expect(carriedBids, isNotNull);
      expect(
        carriedBids!.single.quantity,
        5,
        reason: 'unfilled bid carries forward as usual',
      );
    });

    test('carry-forward bid dropped when start-of-turn cargo capacity is below '
        'order quantity (note recorded, order not used in matching)', () {
      const oversizedBidQuantity = 30; // > defaultCargoHoldsStub (24)
      final next = runB3CarryForwardPhase(
        priorMarket: b3PriorMarket(
          carryForwardBidsByFactionId: {
            'gpBuyer': [
              b3TimberOrder(
                type: TradeOrderType.bid,
                quantity: oversizedBidQuantity,
              ),
            ],
          },
        ),
        sellerStockpile: const Stockpile().applyDelta('timber', 30),
        buyerTreasury: 100000,
        orders: Orders(
          tradeOrdersByPlayerId: {
            'gpSeller': [
              b3TimberOrder(
                type: TradeOrderType.offer,
                quantity: oversizedBidQuantity,
              ),
            ],
          },
        ),
      );

      final buyer = next.players.firstWhere((p) => p.id == 'gpBuyer');
      final seller = next.players.firstWhere((p) => p.id == 'gpSeller');
      expect(
        buyer.stockpile.quantityOf('timber'),
        0,
        reason: 'dropped bid cannot consume the offer',
      );
      expect(buyer.treasury, 100000);
      expect(
        seller.stockpile.quantityOf('timber'),
        30,
        reason: 'offer not consumed when bid is dropped',
      );
      final activity = next.worldMarketState.lastTurnActivity['timber']!;
      expect(activity.filledQuantity, 0);
      expect(activity.notes, hasLength(1));
      expect(
        activity.notes.single.kind,
        MarketActivityNoteKind.carryForwardDroppedCargoInsufficient,
      );
      expect(activity.notes.single.factionId, 'gpBuyer');
      expect(activity.notes.single.commodityId, 'timber');
      expect(activity.notes.single.quantity, oversizedBidQuantity);
      expect(
        next.worldMarketState.carryForwardBidsByFactionId,
        isEmpty,
        reason: 'dropped bid is not re-emitted as a new carry-forward',
      );
      expect(
        next.worldMarketState.carryForwardOffersByFactionId['gpSeller'],
        isNotNull,
      );
    });

    test('carry-forward offer that still fits stockpile is preserved and '
        'matches normally', () {
      final next = runB3CarryForwardPhase(
        priorMarket: b3PriorMarket(
          carryForwardOffersByFactionId: {
            'gpSeller': [
              b3TimberOrder(type: TradeOrderType.offer, quantity: 3),
            ],
          },
        ),
        sellerStockpile: const Stockpile().applyDelta('timber', 5),
        buyerTreasury: 1000,
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
      final next = runB3CarryForwardPhase(
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
        orders: const Orders(),
        marketPrices: const {'timber': 30, 'iron': 80},
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
  });
}
