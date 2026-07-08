// Table-driven DealMatcher scenarios (Refs #3836, #3939).

import 'package:colonizethis_models/colonizethis_models.dart';

import 'deal_matcher_expectations.dart';
import 'deal_matcher_scenario.dart';
import 'deal_matcher_test_support.dart';

/// Priority and FTP precedence from `world_market_deal_matcher_priority_test.dart`.
List<DealMatcherScenario> dealMatcherPriorityAndFtpScenarios() => [
  matcherFtpTimberRow(
    label: 'priority integer absolutely beats FTP across tiers',
    offerPriorityBySeller: const {'sellerLow': 1, 'sellerFtp': 2},
    bidPriorityByBuyer: const {'buyerLow': 1, 'buyerFtp': 2},
    ftpSeller: 'sellerFtp',
    ftpBuyer: 'buyerFtp',
    expect: const DealMatchExpectation(
      filledDealExpectations: [
        FilledDealExpectation(buyerFactionId: 'buyerLow', isFtpMatch: false),
        FilledDealExpectation(buyerFactionId: 'buyerFtp', isFtpMatch: true),
      ],
    ),
  ),
  matcherFtpTimberRow(
    label: 'within a tier, FTP pair fills first as tiebreaker',
    qty: 5,
    offerPriorityBySeller: const {'sellerA': 1},
    bidPriorityByBuyer: const {'buyerFtp': 1, 'buyerOther': 1},
    ftpSeller: 'sellerA',
    ftpBuyer: 'buyerFtp',
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
  matcherFtpTimberRow(
    label:
        'three GPs: FTP A↔B fills before C at same tier; C carry-forward when exhausted (#2989 FTP AC)',
    offerPriorityBySeller: const {'gpA': 1},
    bidPriorityByBuyer: const {'gpB': 1, 'gpC': 1},
    ftpSeller: 'gpA',
    ftpBuyer: 'gpB',
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
  matcherFtpTimberRow(
    label: 'FTP pair at tier 2 does not fill before non-FTP at tier 1',
    offerPriorityBySeller: const {'sellerFtp': 2, 'sellerOther': 1},
    bidPriorityByBuyer: const {'buyerFtp': 2, 'buyerOther': 1},
    ftpSeller: 'sellerFtp',
    ftpBuyer: 'buyerFtp',
    expect: const DealMatchExpectation(
      firstFilledDeal: FilledDealExpectation(
        buyerFactionId: 'buyerOther',
        isFtpMatch: false,
      ),
    ),
  ),
  matcherFtpTimberRow(
    label:
        'FTP membership is order-independent (set keyed via canonical pairKey)',
    qty: 5,
    offerPriorityBySeller: const {'zeta': 1},
    bidPriorityByBuyer: const {'alpha': 1},
    ftpSeller: 'alpha',
    ftpBuyer: 'zeta',
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
    expect: const DealMatchExpectation(
      filledDealsLength: 1,
      firstFilledDeal: FilledDealExpectation(
        sellerFactionId: 'gp4',
        quantity: 3,
      ),
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
    expect: const DealMatchExpectation(
      activityPriceChangePercent: {'timber': 0.0},
    ),
  ),
];

/// Sell-priority relation tiebreaker from
/// `world_market_deal_matcher_sell_priority_test.dart`.
List<DealMatcherScenario> dealMatcherSellPriorityScenarios() => [
  sellPriorityMinorSellerRow(
    label: 'higher-relation consulate-holding buyer wins limited supply',
    sellPriorityRelationByMinorTribeSeller: const {
      'minorM': {'gpHigh': 80, 'gpLow': 40},
    },
    expect: DealMatchExpectation(
      filledDealsLength: 1,
      firstFilledDeal: const FilledDealExpectation(
        buyerFactionId: 'gpHigh',
        quantity: 5,
      ),
      unfilledBidsByFactionId: {
        'gpLow': [matcherBid('timber', 5, priority: 1)],
      },
    ),
  ),
  sellPriorityMinorSellerRow(
    label: 'relation order overrides default ascending-faction-id order',
    buyerA: 'aBuyer',
    buyerB: 'zBuyer',
    qty: 4,
    sellPriorityRelationByMinorTribeSeller: const {
      'minorM': {'aBuyer': 30, 'zBuyer': 90},
    },
    expect: const DealMatchExpectation(
      firstFilledDeal: FilledDealExpectation(buyerFactionId: 'zBuyer'),
    ),
  ),
  sellPriorityMinorSellerRow(
    label: 'consulate-less buyer falls back behind consulate-holding buyer',
    sellPriorityRelationByMinorTribeSeller: const {
      'minorM': {'gpLow': 40},
    },
    expect: DealMatchExpectation(
      firstFilledDeal: const FilledDealExpectation(buyerFactionId: 'gpLow'),
      unfilledBidsByFactionId: {
        'gpHigh': [matcherBid('timber', 5, priority: 1)],
      },
    ),
  ),
  sellPriorityMinorSellerRow(
    label: 'relation tie breaks deterministically by ascending faction id',
    buyerA: 'gpB',
    buyerB: 'gpA',
    sellPriorityRelationByMinorTribeSeller: const {
      'minorM': {'gpA': 55, 'gpB': 55},
    },
    expect: const DealMatchExpectation(
      firstFilledDeal: FilledDealExpectation(buyerFactionId: 'gpA'),
    ),
  ),
  sellPriorityMinorSellerRow(
    label: 'seller absent from map keeps legacy ordering (no reorder)',
    seller: 'minorN',
    buyerA: 'gpA',
    buyerB: 'gpZ',
    sellPriorityRelationByMinorTribeSeller: const {
      'minorM': {'gpA': 1, 'gpZ': 99},
    },
    expect: const DealMatchExpectation(
      firstFilledDeal: FilledDealExpectation(buyerFactionId: 'gpA'),
    ),
  ),
  sellPriorityMinorSellerRow(
    label: 'empty relation map preserves legacy ordering for minor seller',
    buyerA: 'gpA',
    buyerB: 'gpZ',
    expect: const DealMatchExpectation(
      firstFilledDeal: FilledDealExpectation(buyerFactionId: 'gpA'),
    ),
  ),
  DealMatcherScenario.expect(
    label: 'priority tier remains absolute over relation tiebreaker',
    inputs: matcherInputs(
      offersByFactionId: {
        'minorM': [
          matcherOffer('timber', 5, priority: 1),
          matcherOffer('timber', 5, priority: 2),
        ],
      },
      bidsByFactionId: {
        'gpHigh': [matcherBid('timber', 5, priority: 2)],
        'gpLow': [matcherBid('timber', 5, priority: 1)],
      },
      tradeCapacityByFactionId: const {'gpHigh': 100, 'gpLow': 100},
      sellPriorityRelationByMinorTribeSeller: const {
        'minorM': {'gpHigh': 90, 'gpLow': 10},
      },
    ),
    expect: const DealMatchExpectation(
      filledDealExpectations: [
        FilledDealExpectation(buyerFactionId: 'gpLow'),
        FilledDealExpectation(buyerFactionId: 'gpHigh'),
      ],
    ),
    refs: '#3753',
  ),
];
