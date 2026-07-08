// FRR DealMatcher scenarios (Refs #3836, #3939).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../frr_scenarios/frr_d5_test_support.dart';
import 'deal_matcher_expectations.dart';
import 'deal_matcher_scenario.dart';
import 'deal_matcher_test_support.dart';

/// FRR matcher integration from `world_market_deal_matcher_first_right_test.dart`.
List<DealMatcherScenario> dealMatcherFirstRightScenarios() => [
  ...dealMatcherFirstRightRoutingScenarios(),
  ...dealMatcherFirstRightMultiBidScenarios(),
];

List<DealMatcherScenario> dealMatcherFirstRightRoutingScenarios() => [
  frrM1OfferExpectRow(
    label:
        'partial FRR fill: residual offer quantity becomes available for '
        'other GPs at their normal priority tier',
    bidsByFactionId: {
      'gpA': [matcherBid('timber', 4, priority: 5)],
      'gpB': [matcherBid('timber', 10, priority: 1)],
    },
    expect: DealMatchExpectation(
      filledDealsLength: 2,
      frrFilledDeal: const FilledDealExpectation(
        buyerFactionId: 'gpA',
        quantity: 4,
      ),
      nonFrrFilledDeal: const FilledDealExpectation(
        buyerFactionId: 'gpB',
        quantity: 6,
      ),
      unfilledBidsByFactionId: {
        'gpB': [matcherBid('timber', 4, priority: 1)],
      },
      unfilledOffersEmpty: true,
    ),
  ),
  frrM1OfferExpectRow(
    label:
        'cargo limit caps FRR fill (per-buyer cumulative cargo still applies)',
    bidsByFactionId: {
      'gpA': [matcherBid('timber', 10, priority: 1)],
      'gpB': [matcherBid('timber', 10, priority: 1)],
    },
    tradeCapacityByFactionId: const {'gpA': 3, 'gpB': 100},
    expect: DealMatchExpectation(
      filledDealsLength: 2,
      frrFilledDeal: const FilledDealExpectation(
        buyerFactionId: 'gpA',
        quantity: 3,
      ),
      nonFrrFilledDeal: const FilledDealExpectation(
        buyerFactionId: 'gpB',
        quantity: 7,
      ),
      unfilledBidsPinsByFactionId: {
        'gpA': [matcherBid('timber', 7, priority: 1)],
      },
    ),
  ),
  frrNoEffectRow(
    label: 'offer without originTileKey is unaffected by FRR even when index '
        'has matching attributions',
    offersByFactionId: {
      'sellerX': [matcherOffer('timber', 10)],
    },
    purchasedTileIndex: frrMatcherTestIndex(),
  ),
  frrNoEffectRow(
    label: 'offer with originTileKey not present in index falls back to normal '
        'matching (no FRR)',
    offersByFactionId: {
      'M2': [
        matcherOffer('timber', 10, originTileKey: 'oldWorld|M2|7|3'),
      ],
    },
    purchasedTileIndex: frrMatcherTestIndex(),
  ),
  frrNoEffectRow(
    label: 'null purchasedTileIndex disables FRR (legacy behavior preserved)',
    offersByFactionId: {
      'M1': [matcherOffer('timber', 10, originTileKey: kFrrMatcherTestTileKey)],
    },
  ),
];

List<DealMatcherScenario> dealMatcherFirstRightMultiBidScenarios() => [
  DealMatcherScenario.expect(
    label:
        'multiple purchased tiles owned by the same GP each route through FRR',
    inputs: matcherInputs(
      offersByFactionId: {
        'M1': [
          matcherOffer('timber', 5, originTileKey: kFrrMatcherTestTileKey),
          matcherOffer('timber', 5, originTileKey: 'oldWorld|M1|1|0'),
        ],
      },
      bidsByFactionId: {
        'gpA': [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: {'gpA': 100},
      purchasedTileIndex: frrMatcherTestIndexDual(),
    ),
    expect: const DealMatchExpectation(
      filledDealsLength: 2,
      filledDealExpectations: [
        FilledDealExpectation(
          buyerFactionId: 'gpA',
          quantity: 5,
          isFirstRightOfRefusalMatch: true,
        ),
        FilledDealExpectation(
          buyerFactionId: 'gpA',
          quantity: 5,
          isFirstRightOfRefusalMatch: true,
        ),
      ],
      unfilledOffersEmpty: true,
      unfilledBidsEmpty: true,
    ),
    refs: '#2992',
  ),
  DealMatcherScenario.expect(
    label:
        'FRR pass respects multiple bids from the owning GP in submission order',
    inputs: matcherInputs(
      offersByFactionId: {
        'M1': [
          matcherOffer('timber', 10, originTileKey: kFrrMatcherTestTileKey),
        ],
      },
      bidsByFactionId: {
        'gpA': [
          matcherBid('timber', 4, priority: 1),
          matcherBid('timber', 8, priority: 5),
        ],
      },
      tradeCapacityByFactionId: {'gpA': 100},
      purchasedTileIndex: frrMatcherTestIndex(),
    ),
    expect: DealMatchExpectation(
      filledDealsLength: 2,
      filledDealExpectations: const [
        FilledDealExpectation(
          buyerFactionId: 'gpA',
          quantity: 4,
          isFirstRightOfRefusalMatch: true,
        ),
        FilledDealExpectation(
          buyerFactionId: 'gpA',
          quantity: 6,
          isFirstRightOfRefusalMatch: true,
        ),
      ],
      unfilledBidsByFactionId: {
        'gpA': [matcherBid('timber', 2, priority: 5)],
      },
    ),
    refs: '#2992',
  ),
];

/// FRR activity bookkeeping from supplement test file.
List<DealMatcherScenario> dealMatcherFrrActivityScenarios() => [
  frrM1OfferExpectRow(
    label:
        'FRR fills count toward filledQuantity in the per-commodity activity',
    bidsByFactionId: {
      'gpA': [matcherBid('timber', 6, priority: 5)],
      'gpB': [matcherBid('timber', 6, priority: 1)],
    },
    expect: const DealMatchExpectation(
      activityByCommodityId: {
        'timber': MarketActivity(
          totalBidQuantity: 12,
          totalOfferQuantity: 10,
          filledQuantity: 10,
        ),
      },
    ),
  ),
];

List<DealMatcherScenario> frrIssueAcD5MatcherScenarios() => [
  frrD5MatcherRow(
    label:
        'rival priority-1 bid loses to owning-GP priority-5 bid; rival '
        'priority-1 bid carries forward intact',
    bidPriorityByBuyer: const {
      kFrrIssueAcD5GpA: 5,
      kFrrIssueAcD5GpB: 1,
    },
    expect: DealMatchExpectation(
      filledDealsLength: 1,
      frrFilledDeal: const FilledDealExpectation(
        buyerFactionId: kFrrIssueAcD5GpA,
        quantity: 10,
        isFirstRightOfRefusalMatch: true,
        isFtpMatch: false,
      ),
      unfilledBidsByFactionId: {
        kFrrIssueAcD5GpB: [matcherBid('timber', 10, priority: 1)],
      },
    ),
  ),
  frrD5MatcherRow(
    label:
        'FTP-paired rival bid at same priority loses to owning GP; FTP '
        'partner bid carries forward (FRR overrides FTP)',
    offerQty: 6,
    bidPriorityByBuyer: const {
      kFrrIssueAcD5GpA: 1,
      kFrrIssueAcD5GpFtp: 1,
    },
    ftpPairKeys: {
      DealMatcher.pairKey(kFrrIssueAcD5MinorM1, kFrrIssueAcD5GpFtp),
    },
    expect: DealMatchExpectation(
      filledDealsLength: 1,
      frrFilledDeal: const FilledDealExpectation(
        buyerFactionId: kFrrIssueAcD5GpA,
        isFirstRightOfRefusalMatch: true,
        isFtpMatch: false,
      ),
      unfilledBidsByFactionId: {
        kFrrIssueAcD5GpFtp: [matcherBid('timber', 6, priority: 1)],
      },
    ),
  ),
  frrD5MatcherRow(
    label:
        'negative — owning GP does NOT bid: purchased-tile offer falls '
        'back to standard tier matching (not FRR-flagged)',
    bidPriorityByBuyer: const {kFrrIssueAcD5GpB: 1},
    expect: const DealMatchExpectation(
      filledDealsLength: 1,
      nonFrrFilledDeal: FilledDealExpectation(
        buyerFactionId: kFrrIssueAcD5GpB,
        isFirstRightOfRefusalMatch: false,
      ),
    ),
  ),
];
