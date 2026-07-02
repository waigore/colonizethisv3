// Table-driven DealMatcher FRR scenarios (Refs #3836).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'deal_matcher_scenarios.dart';
import 'deal_matcher_test_support.dart';

const _frrTileKey = 'oldWorld|M1|0|0';

/// FRR matcher integration from `world_market_deal_matcher_first_right_test.dart`.
List<DealMatcherScenario> dealMatcherFirstRightScenarios() => [
  DealMatcherScenario(
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
    verify: (result) {
      expect(result.filledDeals.length, 2);
      final frrDeal = result.filledDeals.firstWhere(
        (d) => d.isFirstRightOfRefusalMatch,
      );
      expect(frrDeal.buyerFactionId, 'gpA');
      expect(frrDeal.quantity, 4);
      final regularDeal = result.filledDeals.firstWhere(
        (d) => !d.isFirstRightOfRefusalMatch,
      );
      expect(regularDeal.buyerFactionId, 'gpB');
      expect(regularDeal.quantity, 6);
      expect(result.unfilledBidsByFactionId['gpB'], [
        matcherBid('timber', 4, priority: 1),
      ]);
      expect(result.unfilledOffersByFactionId, isEmpty);
    },
    refs: '#2992',
  ),
  DealMatcherScenario(
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
    verify: (result) {
      expect(result.filledDeals.length, 2);
      final frrDeal = result.filledDeals.firstWhere(
        (d) => d.isFirstRightOfRefusalMatch,
      );
      expect(frrDeal.buyerFactionId, 'gpA');
      expect(frrDeal.quantity, 3);
      final regularDeal = result.filledDeals.firstWhere(
        (d) => !d.isFirstRightOfRefusalMatch,
      );
      expect(regularDeal.buyerFactionId, 'gpB');
      expect(regularDeal.quantity, 7);
      expect(result.unfilledBidsByFactionId['gpA'], [
        matcherBid('timber', 7, priority: 1),
      ]);
    },
    refs: '#2992',
  ),
  DealMatcherScenario(
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
    verify: (result) {
      expect(result.filledDeals.length, 1);
      final deal = result.filledDeals.single;
      expect(deal.buyerFactionId, 'gpB');
      expect(deal.isFirstRightOfRefusalMatch, isFalse);
    },
    refs: '#2992',
  ),
  DealMatcherScenario(
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
    verify: (result) {
      expect(result.filledDeals.length, 1);
      final deal = result.filledDeals.single;
      expect(deal.buyerFactionId, 'gpB');
      expect(deal.isFirstRightOfRefusalMatch, isFalse);
    },
    refs: '#2992',
  ),
  DealMatcherScenario(
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
    verify: (result) {
      expect(result.filledDeals.length, 1);
      final deal = result.filledDeals.single;
      expect(deal.buyerFactionId, 'gpB');
      expect(deal.isFirstRightOfRefusalMatch, isFalse);
    },
    refs: '#2992',
  ),
  DealMatcherScenario(
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
    verify: (result) {
      expect(result.filledDeals.length, 2);
      for (final deal in result.filledDeals) {
        expect(deal.buyerFactionId, 'gpA');
        expect(deal.quantity, 5);
        expect(deal.isFirstRightOfRefusalMatch, isTrue);
      }
      expect(result.unfilledOffersByFactionId, isEmpty);
      expect(result.unfilledBidsByFactionId, isEmpty);
    },
    refs: '#2992',
  ),
  DealMatcherScenario(
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
    verify: (result) {
      expect(result.filledDeals.length, 2);
      for (final deal in result.filledDeals) {
        expect(deal.buyerFactionId, 'gpA');
        expect(deal.isFirstRightOfRefusalMatch, isTrue);
      }
      expect(result.filledDeals[0].quantity, 4);
      expect(result.filledDeals[1].quantity, 6);
      expect(result.unfilledBidsByFactionId['gpA'], [
        matcherBid('timber', 2, priority: 5),
      ]);
    },
    refs: '#2992',
  ),
];

/// FRR activity bookkeeping from supplement test file.
List<DealMatcherScenario> dealMatcherFrrActivityScenarios() => [
  DealMatcherScenario(
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
    verify: (result) {
      expect(
        result.activityByCommodityId['timber'],
        const MarketActivity(
          totalBidQuantity: 12,
          totalOfferQuantity: 10,
          filledQuantity: 10,
        ),
      );
    },
    refs: '#2992',
  ),
];
