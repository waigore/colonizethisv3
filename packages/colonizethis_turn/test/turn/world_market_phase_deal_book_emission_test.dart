import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/world_market_test_support.dart';
import 'world_market_phase_deal_book_emission_cases.dart';

/// Per-commodity Deal Book ledger emission tests for the World Market phase
/// handler (Refs #2993 E6 / #2988 § UI Design — Deal Book).
///
/// SPEC anchors:
/// - `SPEC/program/world-market-resolution.md` § Step F Activity rollup
///   (`MarketActivity.deals` carries the per-commodity `FilledDeal` list).
/// - `SPEC/ui/trade-screen.md` § Deal Book tab (consumes
///   `Game.worldMarketState.lastTurnActivity[commodity].deals`).
void main() {
  group('worldMarketTurnPhaseHandler — Deal Book ledger emission '
      '(Refs #2993 E6, SPEC/program/world-market-resolution.md § Step F)', () {
    test(
      'GP↔GP fill emits a FilledDeal on the resolved commodity activity',
      () {
        final next = runDealBookTimberPhase(
          sellerTimber: 10,
          buyerTreasury: 1000,
          offerQuantity: 5,
          bidQuantity: 5,
        );

        final activity = next.worldMarketState.lastTurnActivity['timber']!;
        expect(activity.deals, hasLength(1));
        final deal = activity.deals.single;
        expect(deal.sellerFactionId, 'gpSeller');
        expect(deal.buyerFactionId, 'gpBuyer');
        expect(deal.commodityId, 'timber');
        expect(deal.quantity, 5);
        expect(deal.pricePerUnit, closeTo(30.0, 1e-9));
        expect(deal.isFirstRightOfRefusalMatch, isFalse);
        expect(deal.isFtpMatch, isFalse);
      },
    );

    test('multi-commodity matching emits deals scoped to each commodity', () {
      final next = runWorldMarketPhase(
        game: gameWithTwoGps(
          sellerStockpile: const Stockpile()
              .applyDelta('timber', 10)
              .applyDelta('iron', 4),
          sellerTreasury: 0,
          buyerTreasury: 10000,
          marketPrices: const {'timber': 30, 'iron': 80},
        ),
        orders: dealBookTimberIronOrders(timberQty: 5, ironQty: 3),
      );

      final timberDeals =
          next.worldMarketState.lastTurnActivity['timber']!.deals;
      final ironDeals = next.worldMarketState.lastTurnActivity['iron']!.deals;
      expect(timberDeals, hasLength(1));
      expect(timberDeals.single.commodityId, 'timber');
      expect(timberDeals.single.quantity, 5);
      expect(ironDeals, hasLength(1));
      expect(ironDeals.single.commodityId, 'iron');
      expect(ironDeals.single.quantity, 3);
      expect(
        timberDeals.map((d) => d.commodityId).toSet(),
        equals(<String>{'timber'}),
      );
      expect(
        ironDeals.map((d) => d.commodityId).toSet(),
        equals(<String>{'iron'}),
      );
    });

    test('commodity with no fills carries empty deals list', () {
      final next = runWorldMarketPhase(
        game: gameWithTwoGps(
          sellerStockpile: const Stockpile().applyDelta('timber', 10),
          sellerTreasury: 0,
          buyerTreasury: 0,
          marketPrices: const {'timber': 30},
        ),
        orders: dealBookSellerTimberOffer(5),
      );

      final activity = next.worldMarketState.lastTurnActivity['timber']!;
      expect(activity.filledQuantity, 0);
      expect(activity.deals, isEmpty);
      expect(activity.deals, equals(const <FilledDeal>[]));
    });

    test('partial fill emits one deal at the matched quantity, residual '
        'carries forward but no extra deal appears', () {
      final next = runDealBookTimberPhase(
        sellerTimber: 3,
        buyerTreasury: 1000,
        offerQuantity: 3,
        bidQuantity: 10,
      );

      final activity = next.worldMarketState.lastTurnActivity['timber']!;
      expect(activity.filledQuantity, 3);
      expect(activity.deals, hasLength(1));
      expect(activity.deals.single.quantity, 3);
      final carriedBids =
          next.worldMarketState.carryForwardBidsByFactionId['gpBuyer'];
      expect(carriedBids, isNotNull);
      expect(carriedBids!.single.quantity, 7);
    });

    test('empty-turn semantics: no activity entries, no deals', () {
      final next = runWorldMarketPhase(
        game:
            gameWithTwoGps(
              sellerStockpile: Stockpile.empty,
              sellerTreasury: 0,
              buyerTreasury: 0,
              marketPrices: const {'timber': 30},
            ).copyWith(
              worldMarketState: WorldMarketState.empty.copyWith(
                prices: const {'timber': 30},
              ),
            ),
        orders: const Orders(),
      );

      expect(next.worldMarketState.lastTurnActivity, isEmpty);
    });
  });
}
