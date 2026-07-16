import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/world_market_test_support.dart';

/// Phase-handler integration for the #3753 R7.3 sell-priority relation
/// tiebreaker. Minor M1 auto-offers a limited quantity; two GPs bid for it at
/// the same priority. The consulate-holding buyer with the higher relation
/// wins the limited supply; consulate-less buyers fall back; GP sellers are
/// unaffected (R7.4).
///
/// SPEC anchors:
/// - `SPEC/game/world-market.md` § Sell-priority relation tiebreaker.
/// - `SPEC/program/world-market-resolution.md` § Step B item 4 + ACs.
void main() {
  group('worldMarketTurnPhaseHandler — #3753 R7.3 sell-priority', () {
    test('higher-relation consulate-holding buyer wins limited supply', () {
      final next = runWorldMarketTradePhase(
        game: sellPriorityMinorTimberGame(
          gpHighRelation: 80,
          gpLowRelation: 40,
          overtureStates: const [
            OvertureState(
              gpId: 'gpHigh',
              targetId: 'M1',
              stage: OvertureStage.tradeConsulate,
            ),
            OvertureState(
              gpId: 'gpLow',
              targetId: 'M1',
              stage: OvertureStage.tradeConsulate,
            ),
          ],
        ),
        tradeOrdersByPlayerId: {
          'M1': minorTimberOffer(quantity: 5, originTileKey: frrCreditTestTileKey),
          'gpLow': gpTimberBid(quantity: 5),
          'gpHigh': gpTimberBid(quantity: 5),
        },
      );

      // M1 only sells 5 units; the higher-relation consulate holder wins them.
      expect(
        next.players.firstWhere((p) => p.id == 'gpHigh').stockpile.quantityOf(
          'timber',
        ),
        5,
      );
      expect(
        next.players.firstWhere((p) => p.id == 'gpLow').stockpile.quantityOf(
          'timber',
        ),
        0,
      );
      // gpLow's bid carries forward in full.
      expect(next.worldMarketState.carryForwardBidsByFactionId['gpLow'], [
        TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.bid,
          quantity: 5,
          priority: 1,
        ),
      ]);
    });

    test('consulate-less higher-relation buyer falls back behind holder', () {
      final next = runWorldMarketTradePhase(
        game: sellPriorityMinorTimberGame(
          gpHighRelation: 90,
          gpLowRelation: 30,
          // gpHigh holds NO overture with M1 (consulate-less); only gpLow does.
          overtureStates: const [
            OvertureState(
              gpId: 'gpLow',
              targetId: 'M1',
              stage: OvertureStage.tradeConsulate,
            ),
          ],
        ),
        tradeOrdersByPlayerId: {
          'M1': minorTimberOffer(quantity: 5, originTileKey: frrCreditTestTileKey),
          'gpLow': gpTimberBid(quantity: 5),
          'gpHigh': gpTimberBid(quantity: 5),
        },
      );

      // The only consulate-holding buyer (gpLow) wins despite lower relation.
      expect(
        next.players.firstWhere((p) => p.id == 'gpLow').stockpile.quantityOf(
          'timber',
        ),
        5,
      );
      expect(
        next.players.firstWhere((p) => p.id == 'gpHigh').stockpile.quantityOf(
          'timber',
        ),
        0,
      );
    });

    test('embassy (higher than consulate) satisfies the gate', () {
      final next = runWorldMarketTradePhase(
        game: sellPriorityMinorTimberGame(
          gpHighRelation: 70,
          gpLowRelation: 95,
          overtureStates: const [
            OvertureState(
              gpId: 'gpHigh',
              targetId: 'M1',
              stage: OvertureStage.embassy,
            ),
            OvertureState(
              gpId: 'gpLow',
              targetId: 'M1',
              stage: OvertureStage.embassy,
            ),
          ],
        ),
        tradeOrdersByPlayerId: {
          'M1': minorTimberOffer(quantity: 5, originTileKey: frrCreditTestTileKey),
          'gpHigh': gpTimberBid(quantity: 5),
          'gpLow': gpTimberBid(quantity: 5),
        },
      );

      // Both hold embassy (≥ consulate); gpLow's relation 95 > 70 wins.
      expect(
        next.players.firstWhere((p) => p.id == 'gpLow').stockpile.quantityOf(
          'timber',
        ),
        5,
      );
    });

    test('GP seller is unaffected by the tiebreaker (R7.4)', () {
      final next = runWorldMarketTradePhase(
        game: sellPriorityGpSellerUnaffectedGame(),
        tradeOrdersByPlayerId: {
          'gpSell': [
            TradeOrder(
              commodityId: 'timber',
              type: TradeOrderType.offer,
              quantity: 5,
              priority: 1,
            ),
          ],
          'gpA': gpTimberBid(quantity: 5),
          'gpZ': gpTimberBid(quantity: 5),
        },
      );

      // Default ascending-faction-id ordering: gpA wins the GP seller's offer.
      expect(
        next.players.firstWhere((p) => p.id == 'gpA').stockpile.quantityOf(
          'timber',
        ),
        5,
      );
      expect(
        next.players.firstWhere((p) => p.id == 'gpZ').stockpile.quantityOf(
          'timber',
        ),
        0,
      );
    });
  });
}
