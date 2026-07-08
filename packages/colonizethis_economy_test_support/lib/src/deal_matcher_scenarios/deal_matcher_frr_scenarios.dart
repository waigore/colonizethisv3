// FRR DealMatcher scenarios (Refs #3836, #3939).

import 'package:colonizethis_models/colonizethis_models.dart';

import 'deal_matcher_expectations.dart';
import 'deal_matcher_scenario.dart';
import 'deal_matcher_test_support.dart';

/// FRR matcher integration from `world_market_deal_matcher_first_right_test.dart`.
List<DealMatcherScenario> dealMatcherFirstRightScenarios() => [
  ...dealMatcherFirstRightRoutingScenarios(),
  ...dealMatcherFirstRightMultiBidScenarios(),
];

List<DealMatcherScenario> dealMatcherFirstRightRoutingScenarios() => [
  frrPartialFillRow(
    label:
        'partial FRR fill: residual offer quantity becomes available for '
        'other GPs at their normal priority tier',
  ),
  frrCargoCapRow(
    label:
        'cargo limit caps FRR fill (per-buyer cumulative cargo still applies)',
  ),
  frrNoFrrFallbackRow(
    label: 'offer without originTileKey is unaffected by FRR even when index '
        'has matching attributions',
    offersByFactionId: {
      'sellerX': [matcherOffer('timber', 10)],
    },
    purchasedTileIndex: frrMatcherTestIndex(),
  ),
  frrNoFrrFallbackRow(
    label: 'offer with originTileKey not present in index falls back to normal '
        'matching (no FRR)',
    offersByFactionId: {
      'M2': [
        matcherOffer('timber', 10, originTileKey: 'oldWorld|M2|7|3'),
      ],
    },
    purchasedTileIndex: frrMatcherTestIndex(),
  ),
  frrNoFrrFallbackRow(
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
  DealMatcherScenario.expect(
    label:
        'FRR fills count toward filledQuantity in the per-commodity activity',
    inputs: frrM1OfferInputs(
      offerQty: 10,
      bidsByFactionId: {
        'gpA': [matcherBid('timber', 6, priority: 5)],
        'gpB': [matcherBid('timber', 6, priority: 1)],
      },
      tradeCapacityByFactionId: const {'gpA': 100, 'gpB': 100},
    ),
    expect: const DealMatchExpectation(
      activityByCommodityId: {
        'timber': MarketActivity(
          totalBidQuantity: 12,
          totalOfferQuantity: 10,
          filledQuantity: 10,
        ),
      },
    ),
    refs: '#2992',
  ),
];

List<DealMatcherScenario> frrIssueAcD5MatcherScenarios() => [
  frrD5RivalPriorityRow(
    label:
        'rival priority-1 bid loses to owning-GP priority-5 bid; rival '
        'priority-1 bid carries forward intact',
  ),
  frrD5FtpRivalRow(
    label:
        'FTP-paired rival bid at same priority loses to owning GP; FTP '
        'partner bid carries forward (FRR overrides FTP)',
  ),
  frrD5NoOwnerBidRow(
    label:
        'negative — owning GP does NOT bid: purchased-tile offer falls '
        'back to standard tier matching (not FRR-flagged)',
  ),
];
