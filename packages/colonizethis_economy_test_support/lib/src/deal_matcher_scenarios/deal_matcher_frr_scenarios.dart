// Table-driven DealMatcher FRR scenarios (Refs #3836).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'deal_matcher_core_scenarios.dart';
import 'deal_matcher_expectations.dart';
import 'deal_matcher_test_support.dart';

const _frrTileKey = 'oldWorld|M1|0|0';

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
    inputs: matcherInputs(
      offersByFactionId: {
        'M1': [matcherOffer('timber', 10, originTileKey: _frrTileKey)],
      },
      bidsByFactionId: {
        'gpA': [matcherBid('timber', 4, priority: 5)],
        'gpB': [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: {'gpA': 100, 'gpB': 100},
      purchasedTileIndex: frrMatcherTestIndex(),
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
    inputs: matcherInputs(
      offersByFactionId: {
        'M1': [matcherOffer('timber', 10, originTileKey: _frrTileKey)],
      },
      bidsByFactionId: {
        'gpA': [matcherBid('timber', 10, priority: 1)],
        'gpB': [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: {'gpA': 3, 'gpB': 100},
      purchasedTileIndex: frrMatcherTestIndex(),
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
    inputs: matcherInputs(
      offersByFactionId: {
        'sellerX': [matcherOffer('timber', 10)],
      },
      bidsByFactionId: {
        'gpA': [matcherBid('timber', 10, priority: 5)],
        'gpB': [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: {'gpA': 100, 'gpB': 100},
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
    inputs: matcherInputs(
      offersByFactionId: {
        'M2': [
          matcherOffer('timber', 10, originTileKey: 'oldWorld|M2|7|3'),
        ],
      },
      bidsByFactionId: {
        'gpA': [matcherBid('timber', 10, priority: 5)],
        'gpB': [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: {'gpA': 100, 'gpB': 100},
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
    inputs: matcherInputs(
      offersByFactionId: {
        'M1': [matcherOffer('timber', 10, originTileKey: _frrTileKey)],
      },
      bidsByFactionId: {
        'gpA': [matcherBid('timber', 10, priority: 5)],
        'gpB': [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: {'gpA': 100, 'gpB': 100},
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
          matcherOffer('timber', 5, originTileKey: _frrTileKey),
          matcherOffer('timber', 5, originTileKey: 'oldWorld|M1|1|0'),
        ],
      },
      bidsByFactionId: {
        'gpA': [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: {'gpA': 100},
      purchasedTileIndex: PurchasedTileIndex.forTesting(const [
        PurchasedTileAttribution(
          tileKey: _frrTileKey,
          owningGpId: 'gpA',
          sourceFactionId: 'M1',
          provinceId: 'oldWorld|M1',
        ),
        PurchasedTileAttribution(
          tileKey: 'oldWorld|M1|1|0',
          owningGpId: 'gpA',
          sourceFactionId: 'M1',
          provinceId: 'oldWorld|M1',
        ),
      ]),
    ),
    expect: DealMatchExpectation(
      filledDealsLength: 2,
      filledDealExpectations: const [
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
        'M1': [matcherOffer('timber', 10, originTileKey: _frrTileKey)],
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
    inputs: matcherInputs(
      offersByFactionId: {
        'M1': [matcherOffer('timber', 10, originTileKey: _frrTileKey)],
      },
      bidsByFactionId: {
        'gpA': [matcherBid('timber', 6, priority: 5)],
        'gpB': [matcherBid('timber', 6, priority: 1)],
      },
      tradeCapacityByFactionId: {'gpA': 100, 'gpB': 100},
      purchasedTileIndex: frrMatcherTestIndex(),
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
