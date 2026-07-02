// Table-driven DealMatcher scenarios (Refs #3836).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'deal_matcher_test_support.dart';

/// One row in a DealMatcher scenario table.
class DealMatcherScenario {
  const DealMatcherScenario({
    required this.label,
    required this.inputs,
    required this.verify,
    this.refs,
  });

  final String label;
  final DealMatchInputs inputs;
  final void Function(DealMatchResult result) verify;
  final String? refs;
}

void runDealMatcherScenario(DealMatcherScenario scenario) {
  scenario.verify(DealMatcher.matchDeals(scenario.inputs));
}

/// Empty-input and basic-fill scenarios from `world_market_deal_matcher_test.dart`.
List<DealMatcherScenario> dealMatcherEmptyAndBasicScenarios() => [
  DealMatcherScenario(
    label: 'no offers and no bids returns DealMatchResult.empty',
    inputs: matcherInputs(),
    verify: (result) => expect(result, equals(DealMatchResult.empty)),
    refs: null,
  ),
  DealMatcherScenario(
    label: 'offers only (no bids) carries every offer forward, no deals',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('timber', 5)],
      },
    ),
    verify: (result) {
      expect(result.filledDeals, isEmpty);
      expect(result.unfilledOffersByFactionId['a'], [
        matcherOffer('timber', 5),
      ]);
      expect(result.unfilledBidsByFactionId, isEmpty);
      expect(
        result.activityByCommodityId['timber'],
        const MarketActivity(totalOfferQuantity: 5),
      );
    },
    refs: null,
  ),
  DealMatcherScenario(
    label: 'bids only (no offers) carries every bid forward, no deals',
    inputs: matcherInputs(
      bidsByFactionId: {
        'b': [matcherBid('timber', 5)],
      },
      tradeCapacityByFactionId: {'b': 100},
    ),
    verify: (result) {
      expect(result.filledDeals, isEmpty);
      expect(result.unfilledBidsByFactionId['b'], [matcherBid('timber', 5)]);
      expect(result.unfilledOffersByFactionId, isEmpty);
      expect(
        result.activityByCommodityId['timber'],
        const MarketActivity(totalBidQuantity: 5),
      );
    },
    refs: null,
  ),
  DealMatcherScenario(
    label: 'single offer 10 vs single bid 5 fills 5, offer carries 5 forward',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('timber', 10)],
      },
      bidsByFactionId: {
        'b': [matcherBid('timber', 5)],
      },
      tradeCapacityByFactionId: {'b': 100},
    ),
    verify: (result) {
      expect(result.filledDeals, [
        const FilledDeal(
          sellerFactionId: 'a',
          buyerFactionId: 'b',
          commodityId: 'timber',
          quantity: 5,
          pricePerUnit: 30.0,
        ),
      ]);
      expect(result.unfilledOffersByFactionId['a'], [
        matcherOffer('timber', 5),
      ]);
      expect(result.unfilledBidsByFactionId, isEmpty);
      expect(
        result.activityByCommodityId['timber'],
        const MarketActivity(
          totalBidQuantity: 5,
          totalOfferQuantity: 10,
          filledQuantity: 5,
        ),
      );
    },
    refs: null,
  ),
  DealMatcherScenario(
    label: 'missing price for commodity records pricePerUnit = 0.0',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('iron', 5)],
      },
      bidsByFactionId: {
        'b': [matcherBid('iron', 5)],
      },
      tradeCapacityByFactionId: {'b': 100},
      pricesByCommodityId: const <CommodityId, double>{},
    ),
    verify: (result) {
      expect(result.filledDeals.single.pricePerUnit, 0.0);
    },
    refs: null,
  ),
  DealMatcherScenario(
    label: 'zero-quantity offer emits no deal and no carry-forward',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('timber', 0)],
      },
      bidsByFactionId: {
        'b': [matcherBid('timber', 5)],
      },
      tradeCapacityByFactionId: {'b': 100},
    ),
    verify: (result) {
      expect(result.filledDeals, isEmpty);
      expect(result.unfilledOffersByFactionId, isEmpty);
      expect(result.unfilledBidsByFactionId['b'], [matcherBid('timber', 5)]);
    },
    refs: null,
  ),
];

/// Cargo-enforcement scenarios from `world_market_deal_matcher_test.dart`.
List<DealMatcherScenario> dealMatcherCargoScenarios() => [
  DealMatcherScenario(
    label: 'buyer with no tradeCapacity entry treated as zero cargo',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('timber', 10)],
      },
      bidsByFactionId: {
        'b': [matcherBid('timber', 5)],
      },
    ),
    verify: (result) {
      expect(result.filledDeals, isEmpty);
      expect(result.unfilledBidsByFactionId['b'], [matcherBid('timber', 5)]);
    },
    refs: null,
  ),
  DealMatcherScenario(
    label: 'cross-commodity cargo: A=8 priority-1, B=10 priority-2 with '
        'tradeCapacity 15 -> A fills 8, B partial 7, B carry 3',
    inputs: matcherInputs(
      offersByFactionId: {
        'sellerA': [matcherOffer('alpha', 100, priority: 1)],
        'sellerB': [matcherOffer('beta', 100, priority: 2)],
      },
      bidsByFactionId: {
        'buyer': [
          matcherBid('alpha', 8, priority: 1),
          matcherBid('beta', 10, priority: 2),
        ],
      },
      tradeCapacityByFactionId: {'buyer': 15},
      pricesByCommodityId: const {'alpha': 5.0, 'beta': 10.0},
    ),
    verify: (result) {
      expect(result.filledDeals.length, 2);
      final alpha = result.filledDeals.firstWhere(
        (d) => d.commodityId == 'alpha',
      );
      final beta = result.filledDeals.firstWhere(
        (d) => d.commodityId == 'beta',
      );
      expect(alpha.quantity, 8);
      expect(beta.quantity, 7);
      expect(result.unfilledBidsByFactionId['buyer'], [
        matcherBid('beta', 3, priority: 2),
      ]);
      expect(
        result.activityByCommodityId['alpha'],
        const MarketActivity(
          totalBidQuantity: 8,
          totalOfferQuantity: 100,
          filledQuantity: 8,
        ),
      );
      expect(
        result.activityByCommodityId['beta'],
        const MarketActivity(
          totalBidQuantity: 10,
          totalOfferQuantity: 100,
          filledQuantity: 7,
        ),
      );
    },
    refs: null,
  ),
  DealMatcherScenario(
    label: 'negative tradeCapacity is clamped to zero',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('timber', 5)],
      },
      bidsByFactionId: {
        'b': [matcherBid('timber', 5)],
      },
      tradeCapacityByFactionId: {'b': -50},
    ),
    verify: (result) {
      expect(result.filledDeals, isEmpty);
      expect(result.unfilledBidsByFactionId['b'], [matcherBid('timber', 5)]);
    },
    refs: null,
  ),
];

/// Boycott exclusion scenarios from `world_market_deal_matcher_boycott_test.dart`.
List<DealMatcherScenario> dealMatcherBoycottScenarios() => [
  DealMatcherScenario(
    label: 'blocks trade where target GP buys goods a colony Tribe sells',
    inputs: matcherInputs(
      offersByFactionId: {
        'tribeT': [matcherOffer('timber', 10, priority: 1)],
      },
      bidsByFactionId: {
        'gpB': [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: const {'gpB': 100},
      boycottBlockedPairKeys: {DealMatcher.pairKey('tribeT', 'gpB')},
    ),
    verify: (result) {
      expect(result.filledDeals, isEmpty);
      expect(result.unfilledOffersByFactionId['tribeT'], [
        matcherOffer('timber', 10, priority: 1),
      ]);
      expect(result.unfilledBidsByFactionId['gpB'], [
        matcherBid('timber', 10, priority: 1),
      ]);
    },
    refs: '#3753',
  ),
  DealMatcherScenario(
    label: 'block is bidirectional (colony Tribe buying goods target GP sells)',
    inputs: matcherInputs(
      offersByFactionId: {
        'gpB': [matcherOffer('timber', 10, priority: 1)],
      },
      bidsByFactionId: {
        'tribeT': [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: const {'tribeT': 100},
      boycottBlockedPairKeys: {DealMatcher.pairKey('tribeT', 'gpB')},
    ),
    verify: (result) {
      expect(result.filledDeals, isEmpty);
    },
    refs: '#3753',
  ),
  DealMatcherScenario(
    label: 'only the boycotted GP is blocked; other buyers still trade',
    inputs: matcherInputs(
      offersByFactionId: {
        'tribeT': [matcherOffer('timber', 10, priority: 1)],
      },
      bidsByFactionId: {
        'gpB': [matcherBid('timber', 10, priority: 1)],
        'gpD': [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: const {'gpB': 100, 'gpD': 100},
      boycottBlockedPairKeys: {DealMatcher.pairKey('tribeT', 'gpB')},
    ),
    verify: (result) {
      expect(result.filledDeals, hasLength(1));
      expect(result.filledDeals.single.sellerFactionId, 'tribeT');
      expect(result.filledDeals.single.buyerFactionId, 'gpD');
      expect(result.filledDeals.single.quantity, 10);
      expect(result.unfilledBidsByFactionId['gpB'], [
        matcherBid('timber', 10, priority: 1),
      ]);
    },
    refs: '#3753',
  ),
  DealMatcherScenario(
    label: 'empty blocked set is a no-op (legacy matching preserved)',
    inputs: matcherInputs(
      offersByFactionId: {
        'tribeT': [matcherOffer('timber', 10, priority: 1)],
      },
      bidsByFactionId: {
        'gpB': [matcherBid('timber', 10, priority: 1)],
      },
      tradeCapacityByFactionId: const {'gpB': 100},
    ),
    verify: (result) {
      expect(result.filledDeals, hasLength(1));
      expect(result.filledDeals.single.buyerFactionId, 'gpB');
      expect(result.filledDeals.single.quantity, 10);
    },
    refs: '#3753',
  ),
];
