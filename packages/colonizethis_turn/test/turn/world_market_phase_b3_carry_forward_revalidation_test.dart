import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_turn/src/turn/phases/world_market_phase.dart';
import 'package:colonizethis_turn/src/turn/turn_pipeline_state.dart';
import 'package:colonizethis_turn/src/turn/turn_resolver_config.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/world_market_test_support.dart';

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
      // Seller carried forward a 5-timber offer but has only 2 timber on hand.
      // Buyer submits a 5-timber bid; without re-validation the matcher would
      // attempt to fill from the dropped offer. Expectation: offer dropped,
      // no fill, bid carries forward, dropped note recorded on activity.
      final priorMarket = WorldMarketState.empty.copyWith(
        prices: const {'timber': 30},
        carryForwardOffersByFactionId: {
          'gpSeller': [
            TradeOrder(
              commodityId: 'timber',
              type: TradeOrderType.offer,
              quantity: 5,
              priority: 1,
            ),
          ],
        },
      );
      final acc = TurnPipelineState(
        game: gameWithTwoGps(
          sellerStockpile: const Stockpile().applyDelta('timber', 2),
          sellerTreasury: 0,
          buyerTreasury: 1000,
          marketPrices: const {'timber': 30},
        ).copyWith(worldMarketState: priorMarket),
      );
      final config = TurnResolverConfig(
        topology: const MapTopology(nodes: [], edges: []),
        orders: Orders(
          tradeOrdersByPlayerId: {
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

      final next = (worldMarketTurnPhaseHandler(acc, config, 3)
              as TurnPhaseStepContinue)
          .pipeline
          .game;

      final buyer = next.players.firstWhere((p) => p.id == 'gpBuyer');
      final seller = next.players.firstWhere((p) => p.id == 'gpSeller');
      expect(buyer.stockpile.quantityOf('timber'), 0,
          reason: 'dropped offer cannot fill the bid');
      expect(buyer.treasury, 1000,
          reason: 'no fill -> no treasury movement on buyer');
      expect(seller.stockpile.quantityOf('timber'), 2,
          reason: 'seller stockpile unchanged when offer is dropped');
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
      expect(carriedBids!.single.quantity, 5,
          reason: 'unfilled bid carries forward as usual');
    });

    test('carry-forward bid dropped when start-of-turn cargo capacity is below '
        'order quantity (note recorded, order not used in matching)', () {
      // Buyer carried forward a 30-timber bid but their default home-fleet
      // cargo capacity is only 24. The bid must be dropped, leaving the
      // seller's 30-timber offer unfilled.
      const oversizedBidQuantity = 30; // > defaultCargoHoldsStub (24)
      final priorMarket = WorldMarketState.empty.copyWith(
        prices: const {'timber': 30},
        carryForwardBidsByFactionId: {
          'gpBuyer': [
            TradeOrder(
              commodityId: 'timber',
              type: TradeOrderType.bid,
              quantity: oversizedBidQuantity,
              priority: 1,
            ),
          ],
        },
      );
      final acc = TurnPipelineState(
        game: gameWithTwoGps(
          sellerStockpile: const Stockpile().applyDelta('timber', 30),
          sellerTreasury: 0,
          buyerTreasury: 100000,
          marketPrices: const {'timber': 30},
        ).copyWith(worldMarketState: priorMarket),
      );
      final config = TurnResolverConfig(
        topology: const MapTopology(nodes: [], edges: []),
        orders: Orders(
          tradeOrdersByPlayerId: {
            'gpSeller': [
              TradeOrder(
                commodityId: 'timber',
                type: TradeOrderType.offer,
                quantity: oversizedBidQuantity,
                priority: 1,
              ),
            ],
          },
        ),
      );

      final next = (worldMarketTurnPhaseHandler(acc, config, 3)
              as TurnPhaseStepContinue)
          .pipeline
          .game;

      final buyer = next.players.firstWhere((p) => p.id == 'gpBuyer');
      final seller = next.players.firstWhere((p) => p.id == 'gpSeller');
      expect(buyer.stockpile.quantityOf('timber'), 0,
          reason: 'dropped bid cannot consume the offer');
      expect(buyer.treasury, 100000);
      expect(seller.stockpile.quantityOf('timber'), 30,
          reason: 'offer not consumed when bid is dropped');
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
      // Unfilled offer is a new submission, so it carries forward via the
      // matcher's unfilled-output path as usual.
      expect(
        next.worldMarketState.carryForwardOffersByFactionId['gpSeller'],
        isNotNull,
      );
    });

    test('carry-forward offer that still fits stockpile is preserved and '
        'matches normally', () {
      // Seller carried forward a 3-timber offer and has 5 timber on hand;
      // a matching new bid arrives and fills the carry-forward.
      final priorMarket = WorldMarketState.empty.copyWith(
        prices: const {'timber': 30},
        carryForwardOffersByFactionId: {
          'gpSeller': [
            TradeOrder(
              commodityId: 'timber',
              type: TradeOrderType.offer,
              quantity: 3,
              priority: 1,
            ),
          ],
        },
      );
      final acc = TurnPipelineState(
        game: gameWithTwoGps(
          sellerStockpile: const Stockpile().applyDelta('timber', 5),
          sellerTreasury: 0,
          buyerTreasury: 1000,
          marketPrices: const {'timber': 30},
        ).copyWith(worldMarketState: priorMarket),
      );
      final config = TurnResolverConfig(
        topology: const MapTopology(nodes: [], edges: []),
        orders: Orders(
          tradeOrdersByPlayerId: {
            'gpBuyer': [
              TradeOrder(
                commodityId: 'timber',
                type: TradeOrderType.bid,
                quantity: 3,
                priority: 1,
              ),
            ],
          },
        ),
      );

      final next = (worldMarketTurnPhaseHandler(acc, config, 3)
              as TurnPhaseStepContinue)
          .pipeline
          .game;

      final buyer = next.players.firstWhere((p) => p.id == 'gpBuyer');
      final seller = next.players.firstWhere((p) => p.id == 'gpSeller');
      expect(buyer.stockpile.quantityOf('timber'), 3,
          reason: 'kept carry-forward offer fills the bid');
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
      // Buyer carried forward two bids: 20 + 10 = 30 > 24-cap. The first
      // bid fits, the second pushes the cumulative kept total above the
      // cargo cap and must be dropped.
      final priorMarket = WorldMarketState.empty.copyWith(
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
      );
      final acc = TurnPipelineState(
        game: gameWithTwoGps(
          sellerStockpile: Stockpile.empty,
          sellerTreasury: 0,
          buyerTreasury: 100000,
          marketPrices: const {'timber': 30, 'iron': 80},
        ).copyWith(worldMarketState: priorMarket),
      );
      final config = TurnResolverConfig(
        topology: const MapTopology(nodes: [], edges: []),
        orders: const Orders(),
      );

      final next = (worldMarketTurnPhaseHandler(acc, config, 3)
              as TurnPhaseStepContinue)
          .pipeline
          .game;

      // The 10-iron bid was dropped, the 20-timber bid survived. With no
      // offers this turn the surviving bid carries forward again.
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
      final timberActivity =
          next.worldMarketState.lastTurnActivity['timber'];
      // Timber was not dropped; the activity entry may or may not be present
      // depending on whether the kept bid produced any new aggregation. With
      // zero new orders this turn, no timber activity is emitted by the
      // current handler. Either way, no drop notes for timber must appear.
      if (timberActivity != null) {
        expect(timberActivity.notes, isEmpty);
      }
    });
  });
}
