// Table-driven DealMatcher priority / FTP / activity scenarios (Refs #3836).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'deal_matcher_scenarios.dart';
import 'deal_matcher_test_support.dart';

/// Priority and FTP precedence from `world_market_deal_matcher_priority_test.dart`.
List<DealMatcherScenario> dealMatcherPriorityAndFtpScenarios() => [
  DealMatcherScenario(
    label: 'priority integer absolutely beats FTP across tiers',
    inputs: matcherInputs(
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
    verify: (result) {
      expect(result.filledDeals.length, 2);
      expect(result.filledDeals.first.buyerFactionId, 'buyerLow');
      expect(result.filledDeals.first.isFtpMatch, false);
      expect(result.filledDeals[1].buyerFactionId, 'buyerFtp');
      expect(result.filledDeals[1].isFtpMatch, true);
    },
    refs: null,
  ),
  DealMatcherScenario(
    label: 'within a tier, FTP pair fills first as tiebreaker',
    inputs: matcherInputs(
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
    verify: (result) {
      expect(result.filledDeals.length, 1);
      expect(result.filledDeals.single.buyerFactionId, 'buyerFtp');
      expect(result.filledDeals.single.isFtpMatch, true);
      expect(result.unfilledBidsByFactionId['buyerOther'], [
        matcherBid('timber', 5, priority: 1),
      ]);
    },
    refs: null,
  ),
  DealMatcherScenario(
    label:
        'three GPs: FTP A↔B fills before C at same tier; C carry-forward when exhausted (#2989 FTP AC)',
    inputs: matcherInputs(
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
    verify: (result) {
      expect(result.filledDeals.length, 1);
      expect(result.filledDeals.single.sellerFactionId, 'gpA');
      expect(result.filledDeals.single.buyerFactionId, 'gpB');
      expect(result.filledDeals.single.isFtpMatch, isTrue);
      expect(result.unfilledBidsByFactionId['gpC'], [
        matcherBid('timber', 10, priority: 1),
      ]);
    },
    refs: '#2989',
  ),
  DealMatcherScenario(
    label: 'FTP pair at tier 2 does not fill before non-FTP at tier 1',
    inputs: matcherInputs(
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
    verify: (result) {
      expect(result.filledDeals.first.buyerFactionId, 'buyerOther');
      expect(result.filledDeals.first.isFtpMatch, false);
    },
    refs: null,
  ),
  DealMatcherScenario(
    label:
        'FTP membership is order-independent (set keyed via canonical pairKey)',
    inputs: matcherInputs(
      offersByFactionId: {
        'zeta': [matcherOffer('timber', 5)],
      },
      bidsByFactionId: {
        'alpha': [matcherBid('timber', 5)],
      },
      tradeCapacityByFactionId: {'alpha': 100},
      ftpPairKeys: {DealMatcher.pairKey('alpha', 'zeta')},
    ),
    verify: (result) {
      expect(result.filledDeals.single.isFtpMatch, true);
    },
    refs: null,
  ),
];

/// Multi-commodity and carry-forward from priority test file.
List<DealMatcherScenario> dealMatcherMultiCommodityScenarios() => [
  DealMatcherScenario(
    label: 'commodities are iterated in alphabetical order (deterministic)',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('zeta', 5), matcherOffer('alpha', 5)],
      },
      bidsByFactionId: {
        'b': [matcherBid('alpha', 5), matcherBid('zeta', 5)],
      },
      tradeCapacityByFactionId: {'b': 100},
      pricesByCommodityId: const {'alpha': 1.0, 'zeta': 2.0},
    ),
    verify: (result) {
      expect(result.filledDeals.map((d) => d.commodityId).toList(), [
        'alpha',
        'zeta',
      ]);
    },
    refs: null,
  ),
  DealMatcherScenario(
    label: 'partial fills produce carry-forward orders with copyWith semantics',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('timber', 4, priority: 3)],
      },
      bidsByFactionId: {
        'b': [matcherBid('timber', 9, priority: 3)],
      },
      tradeCapacityByFactionId: {'b': 100},
    ),
    verify: (result) {
      expect(result.filledDeals.single.quantity, 4);
      expect(result.unfilledOffersByFactionId, isEmpty);
      final carryBid = result.unfilledBidsByFactionId['b']!.single;
      expect(carryBid.commodityId, 'timber');
      expect(carryBid.quantity, 5);
      expect(carryBid.priority, 3);
      expect(carryBid.type, TradeOrderType.bid);
    },
    refs: null,
  ),
];

/// Lock-recovery seller priority (Refs #2924 F12).
List<DealMatcherScenario> dealMatcherLockRecoveryScenarios() => [
  DealMatcherScenario(
    label: 'fills lock-recovery seller before earlier-id affluent seller',
    inputs: matcherInputs(
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
    verify: (result) {
      expect(result.filledDeals, hasLength(1));
      expect(result.filledDeals.single.sellerFactionId, 'gp4');
      expect(result.filledDeals.single.quantity, 3);
    },
    refs: '#2924',
  ),
];

/// Activity bookkeeping from priority test file.
List<DealMatcherScenario> dealMatcherActivityScenarios() => [
  DealMatcherScenario(
    label: 'activity totals reflect input quantities, not just fills',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('timber', 10)],
      },
      bidsByFactionId: {
        'b': [matcherBid('timber', 3)],
        'c': [matcherBid('timber', 4)],
      },
      tradeCapacityByFactionId: {'b': 100, 'c': 100},
    ),
    verify: (result) {
      expect(
        result.activityByCommodityId['timber'],
        const MarketActivity(
          totalBidQuantity: 7,
          totalOfferQuantity: 10,
          filledQuantity: 7,
        ),
      );
      expect(result.unfilledBidsByFactionId, isEmpty);
      expect(result.unfilledOffersByFactionId['a'], [
        matcherOffer('timber', 3),
      ]);
    },
    refs: null,
  ),
  DealMatcherScenario(
    label:
        'priceChangePercent stays 0.0 (composed separately by phase handler)',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('timber', 10)],
      },
      bidsByFactionId: {
        'b': [matcherBid('timber', 20)],
      },
      tradeCapacityByFactionId: {'b': 100},
    ),
    verify: (result) {
      expect(result.activityByCommodityId['timber']!.priceChangePercent, 0.0);
    },
    refs: null,
  ),
];
