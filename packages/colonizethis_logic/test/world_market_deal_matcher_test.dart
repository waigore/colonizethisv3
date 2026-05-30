import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

TradeOrder _offer(
  String commodityId,
  int quantity, {
  int priority = 1,
}) => TradeOrder(
      commodityId: commodityId,
      type: TradeOrderType.offer,
      quantity: quantity,
      priority: priority,
    );

TradeOrder _bid(
  String commodityId,
  int quantity, {
  int priority = 1,
}) => TradeOrder(
      commodityId: commodityId,
      type: TradeOrderType.bid,
      quantity: quantity,
      priority: priority,
    );

DealMatchInputs _inputs({
  Map<String, List<TradeOrder>> offersByFactionId = const {},
  Map<String, List<TradeOrder>> bidsByFactionId = const {},
  Map<String, int> tradeCapacityByFactionId = const {},
  Map<CommodityId, double> pricesByCommodityId = const {'timber': 30.0},
  Set<String> ftpPairKeys = const {},
}) => (
      offersByFactionId: offersByFactionId,
      bidsByFactionId: bidsByFactionId,
      tradeCapacityByFactionId: tradeCapacityByFactionId,
      pricesByCommodityId: pricesByCommodityId,
      ftpPairKeys: ftpPairKeys,
    );

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
      expect(DealMatcher.matchDeals(_inputs()), equals(DealMatchResult.empty));
    });

    test('offers only (no bids) carries every offer forward, no deals', () {
      final result = DealMatcher.matchDeals(
        _inputs(
          offersByFactionId: {
            'a': [_offer('timber', 5)],
          },
        ),
      );
      expect(result.filledDeals, isEmpty);
      expect(result.unfilledOffersByFactionId['a'], [_offer('timber', 5)]);
      expect(result.unfilledBidsByFactionId, isEmpty);
      expect(
        result.activityByCommodityId['timber'],
        const MarketActivity(totalOfferQuantity: 5),
      );
    });

    test('bids only (no offers) carries every bid forward, no deals', () {
      final result = DealMatcher.matchDeals(
        _inputs(
          bidsByFactionId: {
            'b': [_bid('timber', 5)],
          },
          tradeCapacityByFactionId: {'b': 100},
        ),
      );
      expect(result.filledDeals, isEmpty);
      expect(result.unfilledBidsByFactionId['b'], [_bid('timber', 5)]);
      expect(result.unfilledOffersByFactionId, isEmpty);
      expect(
        result.activityByCommodityId['timber'],
        const MarketActivity(totalBidQuantity: 5),
      );
    });
  });

  group('DealMatcher.matchDeals — basic fills', () {
    test('single offer 10 vs single bid 5 fills 5, offer carries 5 forward',
        () {
      final result = DealMatcher.matchDeals(
        _inputs(
          offersByFactionId: {
            'a': [_offer('timber', 10)],
          },
          bidsByFactionId: {
            'b': [_bid('timber', 5)],
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
      expect(result.unfilledOffersByFactionId['a'], [_offer('timber', 5)]);
      expect(result.unfilledBidsByFactionId, isEmpty);
      expect(
        result.activityByCommodityId['timber'],
        const MarketActivity(
          totalBidQuantity: 5,
          totalOfferQuantity: 10,
          filledQuantity: 5,
        ),
      );
    });

    test('missing price for commodity records pricePerUnit = 0.0', () {
      final result = DealMatcher.matchDeals(
        _inputs(
          offersByFactionId: {
            'a': [_offer('iron', 5)],
          },
          bidsByFactionId: {
            'b': [_bid('iron', 5)],
          },
          tradeCapacityByFactionId: {'b': 100},
          pricesByCommodityId: const <CommodityId, double>{},
        ),
      );
      expect(result.filledDeals.single.pricePerUnit, 0.0);
    });

    test('zero-quantity offer emits no deal and no carry-forward', () {
      final result = DealMatcher.matchDeals(
        _inputs(
          offersByFactionId: {
            'a': [_offer('timber', 0)],
          },
          bidsByFactionId: {
            'b': [_bid('timber', 5)],
          },
          tradeCapacityByFactionId: {'b': 100},
        ),
      );
      expect(result.filledDeals, isEmpty);
      expect(result.unfilledOffersByFactionId, isEmpty);
      expect(result.unfilledBidsByFactionId['b'], [_bid('timber', 5)]);
    });
  });

  group('DealMatcher.matchDeals — cargo enforcement', () {
    test('buyer with no tradeCapacity entry treated as zero cargo', () {
      final result = DealMatcher.matchDeals(
        _inputs(
          offersByFactionId: {
            'a': [_offer('timber', 10)],
          },
          bidsByFactionId: {
            'b': [_bid('timber', 5)],
          },
        ),
      );
      expect(result.filledDeals, isEmpty);
      expect(result.unfilledBidsByFactionId['b'], [_bid('timber', 5)]);
    });

    test(
      'cross-commodity cargo: A=8 priority-1, B=10 priority-2 with '
      'tradeCapacity 15 -> A fills 8, B partial 7, B carry 3',
      () {
        final result = DealMatcher.matchDeals(
          _inputs(
            offersByFactionId: {
              'sellerA': [_offer('alpha', 100, priority: 1)],
              'sellerB': [_offer('beta', 100, priority: 2)],
            },
            bidsByFactionId: {
              'buyer': [
                _bid('alpha', 8, priority: 1),
                _bid('beta', 10, priority: 2),
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
          _bid('beta', 3, priority: 2),
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
      },
    );

    test('negative tradeCapacity is clamped to zero', () {
      final result = DealMatcher.matchDeals(
        _inputs(
          offersByFactionId: {
            'a': [_offer('timber', 5)],
          },
          bidsByFactionId: {
            'b': [_bid('timber', 5)],
          },
          tradeCapacityByFactionId: {'b': -50},
        ),
      );
      expect(result.filledDeals, isEmpty);
      expect(result.unfilledBidsByFactionId['b'], [_bid('timber', 5)]);
    });
  });

  group('DealMatcher.matchDeals — priority and FTP precedence', () {
    test('priority integer absolutely beats FTP across tiers', () {
      final result = DealMatcher.matchDeals(
        _inputs(
          offersByFactionId: {
            'sellerLow': [_offer('timber', 10, priority: 1)],
            'sellerFtp': [_offer('timber', 10, priority: 2)],
          },
          bidsByFactionId: {
            'buyerLow': [_bid('timber', 10, priority: 1)],
            'buyerFtp': [_bid('timber', 10, priority: 2)],
          },
          tradeCapacityByFactionId: {'buyerLow': 100, 'buyerFtp': 100},
          ftpPairKeys: {DealMatcher.pairKey('sellerFtp', 'buyerFtp')},
        ),
      );

      // tier 1 (non-FTP) fills first, tier 2 (FTP) fills next.
      expect(result.filledDeals.length, 2);
      expect(result.filledDeals.first.buyerFactionId, 'buyerLow');
      expect(result.filledDeals.first.isFtpMatch, false);
      expect(result.filledDeals[1].buyerFactionId, 'buyerFtp');
      expect(result.filledDeals[1].isFtpMatch, true);
    });

    test('within a tier, FTP pair fills first as tiebreaker', () {
      final result = DealMatcher.matchDeals(
        _inputs(
          offersByFactionId: {
            'sellerA': [_offer('timber', 5, priority: 1)],
          },
          bidsByFactionId: {
            'buyerFtp': [_bid('timber', 5, priority: 1)],
            'buyerOther': [_bid('timber', 5, priority: 1)],
          },
          tradeCapacityByFactionId: {'buyerFtp': 100, 'buyerOther': 100},
          ftpPairKeys: {DealMatcher.pairKey('sellerA', 'buyerFtp')},
        ),
      );

      // sellerA's 5 units go entirely to the FTP-paired buyer.
      expect(result.filledDeals.length, 1);
      expect(result.filledDeals.single.buyerFactionId, 'buyerFtp');
      expect(result.filledDeals.single.isFtpMatch, true);
      // buyerOther's bid carries forward.
      expect(result.unfilledBidsByFactionId['buyerOther'], [
        _bid('timber', 5, priority: 1),
      ]);
    });

    test('FTP pair at tier 2 does not fill before non-FTP at tier 1', () {
      final result = DealMatcher.matchDeals(
        _inputs(
          offersByFactionId: {
            'sellerFtp': [_offer('timber', 10, priority: 2)],
            'sellerOther': [_offer('timber', 10, priority: 1)],
          },
          bidsByFactionId: {
            'buyerFtp': [_bid('timber', 10, priority: 2)],
            'buyerOther': [_bid('timber', 10, priority: 1)],
          },
          tradeCapacityByFactionId: {'buyerFtp': 100, 'buyerOther': 100},
          ftpPairKeys: {DealMatcher.pairKey('sellerFtp', 'buyerFtp')},
        ),
      );

      // First deal must be the non-FTP tier-1 pair (priority integer wins).
      expect(result.filledDeals.first.buyerFactionId, 'buyerOther');
      expect(result.filledDeals.first.isFtpMatch, false);
    });

    test(
      'FTP membership is order-independent (set keyed via canonical pairKey)',
      () {
        final result = DealMatcher.matchDeals(
          _inputs(
            offersByFactionId: {
              'zeta': [_offer('timber', 5)],
            },
            bidsByFactionId: {
              'alpha': [_bid('timber', 5)],
            },
            tradeCapacityByFactionId: {'alpha': 100},
            // Key built with one ordering — matcher must find the symmetric pair.
            ftpPairKeys: {DealMatcher.pairKey('alpha', 'zeta')},
          ),
        );
        expect(result.filledDeals.single.isFtpMatch, true);
      },
    );
  });

  group('DealMatcher.matchDeals — multi-commodity', () {
    test('commodities are iterated in alphabetical order (deterministic)', () {
      final result = DealMatcher.matchDeals(
        _inputs(
          offersByFactionId: {
            'a': [
              _offer('zeta', 5),
              _offer('alpha', 5),
            ],
          },
          bidsByFactionId: {
            'b': [
              _bid('alpha', 5),
              _bid('zeta', 5),
            ],
          },
          tradeCapacityByFactionId: {'b': 100},
          pricesByCommodityId: const {'alpha': 1.0, 'zeta': 2.0},
        ),
      );
      expect(result.filledDeals.map((d) => d.commodityId).toList(), [
        'alpha',
        'zeta',
      ]);
    });

    test('partial fills produce carry-forward orders with copyWith semantics',
        () {
      final result = DealMatcher.matchDeals(
        _inputs(
          offersByFactionId: {
            'a': [_offer('timber', 4, priority: 3)],
          },
          bidsByFactionId: {
            'b': [_bid('timber', 9, priority: 3)],
          },
          tradeCapacityByFactionId: {'b': 100},
        ),
      );

      expect(result.filledDeals.single.quantity, 4);
      expect(result.unfilledOffersByFactionId, isEmpty);
      final carryBid = result.unfilledBidsByFactionId['b']!.single;
      expect(carryBid.commodityId, 'timber');
      expect(carryBid.quantity, 5);
      expect(carryBid.priority, 3);
      expect(carryBid.type, TradeOrderType.bid);
    });
  });

  group('DealMatcher.matchDeals — activity bookkeeping', () {
    test('activity totals reflect input quantities, not just fills', () {
      final result = DealMatcher.matchDeals(
        _inputs(
          offersByFactionId: {
            'a': [_offer('timber', 10)],
          },
          bidsByFactionId: {
            'b': [_bid('timber', 3)],
            'c': [_bid('timber', 4)],
          },
          tradeCapacityByFactionId: {'b': 100, 'c': 100},
        ),
      );
      expect(
        result.activityByCommodityId['timber'],
        const MarketActivity(
          totalBidQuantity: 7,
          totalOfferQuantity: 10,
          filledQuantity: 7,
        ),
      );
      // Buyer-side carry-forward only when remainder > 0 — here both bids fill.
      expect(result.unfilledBidsByFactionId, isEmpty);
      expect(result.unfilledOffersByFactionId['a'], [_offer('timber', 3)]);
    });

    test('priceChangePercent stays 0.0 (composed separately by phase handler)',
        () {
      final result = DealMatcher.matchDeals(
        _inputs(
          offersByFactionId: {
            'a': [_offer('timber', 10)],
          },
          bidsByFactionId: {
            'b': [_bid('timber', 20)],
          },
          tradeCapacityByFactionId: {'b': 100},
        ),
      );
      expect(
        result.activityByCommodityId['timber']!.priceChangePercent,
        0.0,
      );
    });
  });
}
