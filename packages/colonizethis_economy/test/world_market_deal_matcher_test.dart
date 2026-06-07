import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'world_market_deal_matcher_test_support.dart';

void main() {
  group('DealMatcher.pairKey', () {
    test('returns canonical key regardless of argument order', () {
      expect(
        DealMatcher.pairKey('alpha', 'zeta'),
        DealMatcher.pairKey('zeta', 'alpha'),
      );
      expect(DealMatcher.pairKey('alpha', 'zeta'), 'alpha|zeta');
    });

    test('handles equal ids (degenerate self-pair) deterministically', () {
      expect(DealMatcher.pairKey('a', 'a'), 'a|a');
    });
  });

  group('DealMatcher.matchDeals — empty inputs', () {
    test('no offers and no bids returns DealMatchResult.empty', () {
      expect(
        DealMatcher.matchDeals(matcherInputs()),
        equals(DealMatchResult.empty),
      );
    });

    test('offers only (no bids) carries every offer forward, no deals', () {
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'a': [matcherOffer('timber', 5)],
          },
        ),
      );
      expect(result.filledDeals, isEmpty);
      expect(result.unfilledOffersByFactionId['a'], [
        matcherOffer('timber', 5),
      ]);
      expect(result.unfilledBidsByFactionId, isEmpty);
      expect(
        result.activityByCommodityId['timber'],
        const MarketActivity(totalOfferQuantity: 5),
      );
    });

    test('bids only (no offers) carries every bid forward, no deals', () {
      final result = DealMatcher.matchDeals(
        matcherInputs(
          bidsByFactionId: {
            'b': [matcherBid('timber', 5)],
          },
          tradeCapacityByFactionId: {'b': 100},
        ),
      );
      expect(result.filledDeals, isEmpty);
      expect(result.unfilledBidsByFactionId['b'], [matcherBid('timber', 5)]);
      expect(result.unfilledOffersByFactionId, isEmpty);
      expect(
        result.activityByCommodityId['timber'],
        const MarketActivity(totalBidQuantity: 5),
      );
    });
  });

  group('DealMatcher.matchDeals — basic fills', () {
    test(
      'single offer 10 vs single bid 5 fills 5, offer carries 5 forward',
      () {
        final result = DealMatcher.matchDeals(
          matcherInputs(
            offersByFactionId: {
              'a': [matcherOffer('timber', 10)],
            },
            bidsByFactionId: {
              'b': [matcherBid('timber', 5)],
            },
            tradeCapacityByFactionId: {'b': 100},
          ),
        );

        expect(result.filledDeals, [
          const FilledDeal(
            sellerFactionId: 'a',
            buyerFactionId: 'b',
            commodityId: 'timber',
            quantity: 5,
            pricePerUnit: 30.0,
          ),
        ]);
        expect(result.unfilledOffersByFactionId['a'], [
          matcherOffer('timber', 5),
        ]);
        expect(result.unfilledBidsByFactionId, isEmpty);
        expect(
          result.activityByCommodityId['timber'],
          const MarketActivity(
            totalBidQuantity: 5,
            totalOfferQuantity: 10,
            filledQuantity: 5,
          ),
        );
      },
    );

    test('missing price for commodity records pricePerUnit = 0.0', () {
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'a': [matcherOffer('iron', 5)],
          },
          bidsByFactionId: {
            'b': [matcherBid('iron', 5)],
          },
          tradeCapacityByFactionId: {'b': 100},
          pricesByCommodityId: const <CommodityId, double>{},
        ),
      );
      expect(result.filledDeals.single.pricePerUnit, 0.0);
    });

    test('zero-quantity offer emits no deal and no carry-forward', () {
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'a': [matcherOffer('timber', 0)],
          },
          bidsByFactionId: {
            'b': [matcherBid('timber', 5)],
          },
          tradeCapacityByFactionId: {'b': 100},
        ),
      );
      expect(result.filledDeals, isEmpty);
      expect(result.unfilledOffersByFactionId, isEmpty);
      expect(result.unfilledBidsByFactionId['b'], [matcherBid('timber', 5)]);
    });
  });

  group('DealMatcher.matchDeals — cargo enforcement', () {
    test('buyer with no tradeCapacity entry treated as zero cargo', () {
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'a': [matcherOffer('timber', 10)],
          },
          bidsByFactionId: {
            'b': [matcherBid('timber', 5)],
          },
        ),
      );
      expect(result.filledDeals, isEmpty);
      expect(result.unfilledBidsByFactionId['b'], [matcherBid('timber', 5)]);
    });

    test('cross-commodity cargo: A=8 priority-1, B=10 priority-2 with '
        'tradeCapacity 15 -> A fills 8, B partial 7, B carry 3', () {
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'sellerA': [matcherOffer('alpha', 100, priority: 1)],
            'sellerB': [matcherOffer('beta', 100, priority: 2)],
          },
          bidsByFactionId: {
            'buyer': [
              matcherBid('alpha', 8, priority: 1),
              matcherBid('beta', 10, priority: 2),
            ],
          },
          tradeCapacityByFactionId: {'buyer': 15},
          pricesByCommodityId: const {'alpha': 5.0, 'beta': 10.0},
        ),
      );

      expect(result.filledDeals.length, 2);
      final alpha = result.filledDeals.firstWhere(
        (d) => d.commodityId == 'alpha',
      );
      final beta = result.filledDeals.firstWhere(
        (d) => d.commodityId == 'beta',
      );
      expect(alpha.quantity, 8);
      expect(beta.quantity, 7);

      expect(result.unfilledBidsByFactionId['buyer'], [
        matcherBid('beta', 3, priority: 2),
      ]);

      expect(
        result.activityByCommodityId['alpha'],
        const MarketActivity(
          totalBidQuantity: 8,
          totalOfferQuantity: 100,
          filledQuantity: 8,
        ),
      );
      expect(
        result.activityByCommodityId['beta'],
        const MarketActivity(
          totalBidQuantity: 10,
          totalOfferQuantity: 100,
          filledQuantity: 7,
        ),
      );
    });

    test('negative tradeCapacity is clamped to zero', () {
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'a': [matcherOffer('timber', 5)],
          },
          bidsByFactionId: {
            'b': [matcherBid('timber', 5)],
          },
          tradeCapacityByFactionId: {'b': -50},
        ),
      );
      expect(result.filledDeals, isEmpty);
      expect(result.unfilledBidsByFactionId['b'], [matcherBid('timber', 5)]);
    });
  });
}
