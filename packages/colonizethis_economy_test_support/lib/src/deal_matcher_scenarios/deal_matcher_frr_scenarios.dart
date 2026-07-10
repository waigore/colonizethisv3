// FRR DealMatcher scenarios (Refs #3836, #3939).

import 'package:colonizethis_economy/colonizethis_economy.dart';

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
    expect: frrSplitExpect(
      frrBuyer: 'gpA',
      frrQty: 4,
      otherBuyer: 'gpB',
      otherQty: 6,
      unfilledBidsByFactionId: matcherUnfilledBid('gpB', 4),
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
    expect: frrSplitExpect(
      frrBuyer: 'gpA',
      frrQty: 3,
      otherBuyer: 'gpB',
      otherQty: 7,
      unfilledBidsPinsByFactionId: matcherUnfilledBid('gpA', 7),
    ),
  ),
  frrNoEffectRow(
    label:
        'offer without originTileKey is unaffected by FRR even when index '
        'has matching attributions',
    offersByFactionId: {
      'sellerX': [matcherOffer('timber', 10)],
    },
    purchasedTileIndex: frrMatcherTestIndex(),
  ),
  frrNoEffectRow(
    label:
        'offer with originTileKey not present in index falls back to normal '
        'matching (no FRR)',
    offersByFactionId: {
      'M2': [matcherOffer('timber', 10, originTileKey: 'oldWorld|M2|7|3')],
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
  frrOwnerOffersRow(
    label:
        'multiple purchased tiles owned by the same GP each route through FRR',
    offerQtysByOrigin: const {kFrrMatcherTestTileKey: 5, 'oldWorld|M1|1|0': 5},
    purchasedTileIndex: frrMatcherTestIndexDual(),
    expect: frrOwnerFillsExpect(
      ownerBuyer: 'gpA',
      quantities: const [5, 5],
      unfilledOffersEmpty: true,
      unfilledBidsEmpty: true,
    ),
  ),
  frrOwnerOffersRow(
    label:
        'FRR pass respects multiple bids from the owning GP in submission order',
    singleOfferQty: 10,
    ownerBids: const [(4, 1), (8, 5)],
    expect: frrOwnerFillsExpect(
      ownerBuyer: 'gpA',
      quantities: const [4, 6],
      unfilledBidsByFactionId: matcherUnfilledBid('gpA', 2, priority: 5),
    ),
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
    expect: DealMatchExpectation(
      activityByCommodityId: {
        'timber': matcherActivity(bid: 12, offer: 10, filled: 10),
      },
    ),
  ),
];

List<DealMatcherScenario> frrIssueAcD5MatcherScenarios() => [
  frrD5MatcherRow(
    label:
        'rival priority-1 bid loses to owning-GP priority-5 bid; rival '
        'priority-1 bid carries forward intact',
    bidPriorityByBuyer: const {kFrrIssueAcD5GpA: 5, kFrrIssueAcD5GpB: 1},
    expect: frrOwnerFillExpect(
      ownerBuyer: kFrrIssueAcD5GpA,
      fillQty: 10,
      rivalBuyer: kFrrIssueAcD5GpB,
      rivalUnfilledQty: 10,
    ),
  ),
  frrD5MatcherRow(
    label:
        'FTP-paired rival bid at same priority loses to owning GP; FTP '
        'partner bid carries forward (FRR overrides FTP)',
    offerQty: 6,
    bidPriorityByBuyer: const {kFrrIssueAcD5GpA: 1, kFrrIssueAcD5GpFtp: 1},
    ftpPairKeys: {
      DealMatcher.pairKey(kFrrIssueAcD5MinorM1, kFrrIssueAcD5GpFtp),
    },
    expect: frrOwnerFillExpect(
      ownerBuyer: kFrrIssueAcD5GpA,
      rivalBuyer: kFrrIssueAcD5GpFtp,
      rivalUnfilledQty: 6,
    ),
  ),
  frrD5MatcherRow(
    label:
        'negative — owning GP does NOT bid: purchased-tile offer falls '
        'back to standard tier matching (not FRR-flagged)',
    bidPriorityByBuyer: const {kFrrIssueAcD5GpB: 1},
    expect: DealMatchExpectation(
      filledDealsLength: 1,
      nonFrrFilledDeal: matcherFilled(buyer: kFrrIssueAcD5GpB, isFrr: false),
    ),
  ),
];
