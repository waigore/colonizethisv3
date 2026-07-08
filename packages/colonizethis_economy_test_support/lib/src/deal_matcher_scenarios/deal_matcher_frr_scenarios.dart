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
  DealMatcherScenario.expect(
    label:
        'partial FRR fill: residual offer quantity becomes available for '
        'other GPs at their normal priority tier',
    inputs: frrM1OfferInputs(
      bidsByFactionId: {
        'gpA': [matcherBid('timber', 4, priority: 5)],
        'gpB': [matcherBid('timber', 10, priority: 1)],
      },
    ),
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
    refs: '#2992',
  ),
  DealMatcherScenario.expect(
    label:
        'cargo limit caps FRR fill (per-buyer cumulative cargo still applies)',
    inputs: frrM1OfferInputs(
      bidsByFactionId: {
        'gpA': [matcherBid('timber', 10, priority: 1)],
        'gpB': [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: const {'gpA': 3, 'gpB': 100},
    ),
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
    refs: '#2992',
  ),
  DealMatcherScenario.expect(
    label: 'offer without originTileKey is unaffected by FRR even when index '
        'has matching attributions',
    inputs: frrTwoBuyerRivalInputs(
      offersByFactionId: {
        'sellerX': [matcherOffer('timber', 10)],
      },
      purchasedTileIndex: frrMatcherTestIndex(),
    ),
    expect: const DealMatchExpectation(
      filledDealsLength: 1,
      firstFilledDeal: FilledDealExpectation(
        buyerFactionId: 'gpB',
        isFirstRightOfRefusalMatch: false,
      ),
    ),
    refs: '#2992',
  ),
  DealMatcherScenario.expect(
    label: 'offer with originTileKey not present in index falls back to normal '
        'matching (no FRR)',
    inputs: frrTwoBuyerRivalInputs(
      offersByFactionId: {
        'M2': [
          matcherOffer('timber', 10, originTileKey: 'oldWorld|M2|7|3'),
        ],
      },
      purchasedTileIndex: frrMatcherTestIndex(),
    ),
    expect: const DealMatchExpectation(
      filledDealsLength: 1,
      firstFilledDeal: FilledDealExpectation(
        buyerFactionId: 'gpB',
        isFirstRightOfRefusalMatch: false,
      ),
    ),
    refs: '#2992',
  ),
  DealMatcherScenario.expect(
    label: 'null purchasedTileIndex disables FRR (legacy behavior preserved)',
    inputs: frrTwoBuyerRivalInputs(
      offersByFactionId: {
        'M1': [matcherOffer('timber', 10, originTileKey: kFrrMatcherTestTileKey)],
      },
    ),
    expect: const DealMatchExpectation(
      filledDealsLength: 1,
      firstFilledDeal: FilledDealExpectation(
        buyerFactionId: 'gpB',
        isFirstRightOfRefusalMatch: false,
      ),
    ),
    refs: '#2992',
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
  DealMatcherScenario.expect(
    label:
        'rival priority-1 bid loses to owning-GP priority-5 bid; rival '
        'priority-1 bid carries forward intact',
    inputs: matcherInputs(
      offersByFactionId: {
        kFrrIssueAcD5MinorM1: [
          matcherOffer('timber', 10, originTileKey: kFrrIssueAcD5TileK1),
        ],
      },
      bidsByFactionId: {
        kFrrIssueAcD5GpA: [matcherBid('timber', 10, priority: 5)],
        kFrrIssueAcD5GpB: [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: const {
        kFrrIssueAcD5GpA: 100,
        kFrrIssueAcD5GpB: 100,
      },
      pricesByCommodityId: const {'timber': 20.0},
      purchasedTileIndex: frrD5IdxK1GpA(),
    ),
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
    refs: '#2992 D5 AC1',
  ),
  DealMatcherScenario.expect(
    label:
        'FTP-paired rival bid at same priority loses to owning GP; FTP '
        'partner bid carries forward (FRR overrides FTP)',
    inputs: matcherInputs(
      offersByFactionId: {
        kFrrIssueAcD5MinorM1: [
          matcherOffer('timber', 6, originTileKey: kFrrIssueAcD5TileK1),
        ],
      },
      bidsByFactionId: {
        kFrrIssueAcD5GpA: [matcherBid('timber', 6, priority: 1)],
        kFrrIssueAcD5GpFtp: [matcherBid('timber', 6, priority: 1)],
      },
      tradeCapacityByFactionId: const {
        kFrrIssueAcD5GpA: 100,
        kFrrIssueAcD5GpFtp: 100,
      },
      pricesByCommodityId: const {'timber': 20.0},
      ftpPairKeys: {
        DealMatcher.pairKey(kFrrIssueAcD5MinorM1, kFrrIssueAcD5GpFtp),
      },
      purchasedTileIndex: frrD5IdxK1GpA(),
    ),
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
    refs: '#2992 D5 AC1',
  ),
  DealMatcherScenario.expect(
    label:
        'negative — owning GP does NOT bid: purchased-tile offer falls '
        'back to standard tier matching (not FRR-flagged)',
    inputs: matcherInputs(
      offersByFactionId: {
        kFrrIssueAcD5MinorM1: [
          matcherOffer('timber', 10, originTileKey: kFrrIssueAcD5TileK1),
        ],
      },
      bidsByFactionId: {
        kFrrIssueAcD5GpB: [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: const {kFrrIssueAcD5GpB: 100},
      pricesByCommodityId: const {'timber': 20.0},
      purchasedTileIndex: frrD5IdxK1GpA(),
    ),
    expect: const DealMatchExpectation(
      filledDealsLength: 1,
      nonFrrFilledDeal: FilledDealExpectation(
        buyerFactionId: kFrrIssueAcD5GpB,
        isFirstRightOfRefusalMatch: false,
      ),
    ),
    refs: '#2992 D5 AC1',
  ),
];
