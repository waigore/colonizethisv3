// Table-driven DealMatcher priority / FTP / activity scenarios (Refs #3836).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'deal_matcher_core_scenarios.dart';
import 'deal_matcher_expectations.dart';
import 'deal_matcher_test_support.dart';

/// Priority and FTP precedence from `world_market_deal_matcher_priority_test.dart`.
List<DealMatcherScenario> dealMatcherPriorityAndFtpScenarios() => [
  DealMatcherScenario.expect(
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
    expect: const DealMatchExpectation(
      filledDealExpectations: [
        FilledDealExpectation(buyerFactionId: 'buyerLow', isFtpMatch: false),
        FilledDealExpectation(buyerFactionId: 'buyerFtp', isFtpMatch: true),
      ],
    ),
  ),
  DealMatcherScenario.expect(
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
    expect: DealMatchExpectation(
      filledDealExpectations: const [
        FilledDealExpectation(
          buyerFactionId: 'buyerFtp',
          isFtpMatch: true,
        ),
      ],
      unfilledBidsByFactionId: {
        'buyerOther': [matcherBid('timber', 5, priority: 1)],
      },
    ),
  ),
  DealMatcherScenario.expect(
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
    expect: DealMatchExpectation(
      filledDealExpectations: const [
        FilledDealExpectation(
          sellerFactionId: 'gpA',
          buyerFactionId: 'gpB',
          isFtpMatch: true,
        ),
      ],
      unfilledBidsByFactionId: {
        'gpC': [matcherBid('timber', 10, priority: 1)],
      },
    ),
    refs: '#2989',
  ),
  DealMatcherScenario.expect(
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
    expect: DealMatchExpectation(
      custom: (result) {
        expect(result.filledDeals.first.buyerFactionId, 'buyerOther');
        expect(result.filledDeals.first.isFtpMatch, false);
      },
    ),
  ),
  DealMatcherScenario.expect(
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
    expect: const DealMatchExpectation(
      filledDealExpectations: [
        FilledDealExpectation(isFtpMatch: true),
      ],
    ),
  ),
];

/// Multi-commodity and carry-forward from priority test file.
List<DealMatcherScenario> dealMatcherMultiCommodityScenarios() => [
  DealMatcherScenario.expect(
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
    expect: const DealMatchExpectation(
      filledDealCommodityIds: ['alpha', 'zeta'],
    ),
  ),
  DealMatcherScenario.expect(
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
    expect: DealMatchExpectation(
      filledDealExpectations: const [FilledDealExpectation(quantity: 4)],
      unfilledOffersEmpty: true,
      unfilledBidsByFactionId: {
        'b': [matcherBid('timber', 5, priority: 3)],
      },
      custom: (result) {
        final carryBid = result.unfilledBidsByFactionId['b']!.single;
        expect(carryBid.commodityId, 'timber');
        expect(carryBid.quantity, 5);
        expect(carryBid.priority, 3);
        expect(carryBid.type, TradeOrderType.bid);
      },
    ),
  ),
];

/// Lock-recovery seller priority (Refs #2924 F12).
List<DealMatcherScenario> dealMatcherLockRecoveryScenarios() => [
  DealMatcherScenario.expect(
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
    expect: DealMatchExpectation(
      filledDealsLength: 1,
      singleFilledDeal: (deal) {
        expect(deal.sellerFactionId, 'gp4');
        expect(deal.quantity, 3);
      },
    ),
    refs: '#2924',
  ),
];

/// Activity bookkeeping from priority test file.
List<DealMatcherScenario> dealMatcherActivityScenarios() => [
  DealMatcherScenario.expect(
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
    expect: DealMatchExpectation(
      activityByCommodityId: const {
        'timber': MarketActivity(
          totalBidQuantity: 7,
          totalOfferQuantity: 10,
          filledQuantity: 7,
        ),
      },
      unfilledBidsEmpty: true,
      unfilledOffersByFactionId: {
        'a': [matcherOffer('timber', 3)],
      },
    ),
  ),
  DealMatcherScenario.expect(
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
    expect: DealMatchExpectation(
      custom: (result) => expect(
        result.activityByCommodityId['timber']!.priceChangePercent,
        0.0,
      ),
    ),
  ),
];
