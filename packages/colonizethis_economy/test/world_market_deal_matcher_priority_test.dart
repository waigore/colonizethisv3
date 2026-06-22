import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  group('DealMatcher.matchDeals — priority and FTP precedence', () {
    test('priority integer absolutely beats FTP across tiers', () {
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'sellerLow': [matcherOffer('timber', 10, priority: 1)],
            'sellerFtp': [matcherOffer('timber', 10, priority: 2)],
          },
          bidsByFactionId: {
            'buyerLow': [matcherBid('timber', 10, priority: 1)],
            'buyerFtp': [matcherBid('timber', 10, priority: 2)],
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
        matcherInputs(
          offersByFactionId: {
            'sellerA': [matcherOffer('timber', 5, priority: 1)],
          },
          bidsByFactionId: {
            'buyerFtp': [matcherBid('timber', 5, priority: 1)],
            'buyerOther': [matcherBid('timber', 5, priority: 1)],
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
        matcherBid('timber', 5, priority: 1),
      ]);
    });

    test(
      'three GPs: FTP A↔B fills before C at same tier; C carry-forward when exhausted (#2989 FTP AC)',
      () {
        final result = DealMatcher.matchDeals(
          matcherInputs(
            offersByFactionId: {
              'gpA': [matcherOffer('timber', 10, priority: 1)],
            },
            bidsByFactionId: {
              'gpB': [matcherBid('timber', 10, priority: 1)],
              'gpC': [matcherBid('timber', 10, priority: 1)],
            },
            tradeCapacityByFactionId: const {'gpB': 100, 'gpC': 100},
            ftpPairKeys: {DealMatcher.pairKey('gpA', 'gpB')},
          ),
        );

        expect(result.filledDeals.length, 1);
        expect(result.filledDeals.single.sellerFactionId, 'gpA');
        expect(result.filledDeals.single.buyerFactionId, 'gpB');
        expect(result.filledDeals.single.isFtpMatch, isTrue);
        expect(result.unfilledBidsByFactionId['gpC'], [
          matcherBid('timber', 10, priority: 1),
        ]);
      },
    );

    test('FTP pair at tier 2 does not fill before non-FTP at tier 1', () {
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'sellerFtp': [matcherOffer('timber', 10, priority: 2)],
            'sellerOther': [matcherOffer('timber', 10, priority: 1)],
          },
          bidsByFactionId: {
            'buyerFtp': [matcherBid('timber', 10, priority: 2)],
            'buyerOther': [matcherBid('timber', 10, priority: 1)],
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
          matcherInputs(
            offersByFactionId: {
              'zeta': [matcherOffer('timber', 5)],
            },
            bidsByFactionId: {
              'alpha': [matcherBid('timber', 5)],
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
        matcherInputs(
          offersByFactionId: {
            'a': [matcherOffer('zeta', 5), matcherOffer('alpha', 5)],
          },
          bidsByFactionId: {
            'b': [matcherBid('alpha', 5), matcherBid('zeta', 5)],
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

    test(
      'partial fills produce carry-forward orders with copyWith semantics',
      () {
        final result = DealMatcher.matchDeals(
          matcherInputs(
            offersByFactionId: {
              'a': [matcherOffer('timber', 4, priority: 3)],
            },
            bidsByFactionId: {
              'b': [matcherBid('timber', 9, priority: 3)],
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
      },
    );
  });

  group(
    'DealMatcher.matchDeals — lock-recovery seller priority (Refs #2924 F12)',
    () {
      test('fills lock-recovery seller before earlier-id affluent seller', () {
        final result = DealMatcher.matchDeals(
          matcherInputs(
            offersByFactionId: {
              'gp1': [matcherOffer('grain', 10, priority: 2)],
              'gp4': [matcherOffer('grain', 10, priority: 2)],
            },
            bidsByFactionId: {
              'gp2': [matcherBid('grain', 3, priority: 2)],
            },
            tradeCapacityByFactionId: const {'gp2': 3},
            pricesByCommodityId: const {'grain': 10.0},
            lockRecoverySellerPriorityIds: const {'gp1', 'gp4'},
            treasuryByFactionId: const {'gp1': 100, 'gp4': -50},
          ),
        );
        expect(result.filledDeals, hasLength(1));
        expect(result.filledDeals.single.sellerFactionId, 'gp4');
        expect(result.filledDeals.single.quantity, 3);
      });
    },
  );

  group('DealMatcher.matchDeals — activity bookkeeping', () {
    test('activity totals reflect input quantities, not just fills', () {
      final result = DealMatcher.matchDeals(
        matcherInputs(
          offersByFactionId: {
            'a': [matcherOffer('timber', 10)],
          },
          bidsByFactionId: {
            'b': [matcherBid('timber', 3)],
            'c': [matcherBid('timber', 4)],
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
      expect(result.unfilledOffersByFactionId['a'], [
        matcherOffer('timber', 3),
      ]);
    });

    test(
      'priceChangePercent stays 0.0 (composed separately by phase handler)',
      () {
        final result = DealMatcher.matchDeals(
          matcherInputs(
            offersByFactionId: {
              'a': [matcherOffer('timber', 10)],
            },
            bidsByFactionId: {
              'b': [matcherBid('timber', 20)],
            },
            tradeCapacityByFactionId: {'b': 100},
          ),
        );
        expect(result.activityByCommodityId['timber']!.priceChangePercent, 0.0);
      },
    );
  });
}
