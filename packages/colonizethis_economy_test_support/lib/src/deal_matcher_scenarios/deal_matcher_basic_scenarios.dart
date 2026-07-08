// Table-driven DealMatcher scenarios (Refs #3836, #3939).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'deal_matcher_expectations.dart';
import 'deal_matcher_scenario.dart';
import 'deal_matcher_test_support.dart';

/// Empty-input and basic-fill scenarios from `world_market_deal_matcher_test.dart`.
List<DealMatcherScenario> dealMatcherEmptyAndBasicScenarios() => [
  DealMatcherScenario.expect(
    label: 'no offers and no bids returns DealMatchResult.empty',
    inputs: matcherInputs(),
    expect: const DealMatchExpectation(resultEqualsEmpty: true),
  ),
  DealMatcherScenario.expect(
    label: 'offers only (no bids) carries every offer forward, no deals',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('timber', 5)],
      },
    ),
    expect: DealMatchExpectation(
      filledDealsEmpty: true,
      unfilledBidsEmpty: true,
      unfilledOffersByFactionId: {
        'a': [matcherOffer('timber', 5)],
      },
      activityByCommodityId: const {
        'timber': MarketActivity(totalOfferQuantity: 5),
      },
    ),
  ),
  DealMatcherScenario.expect(
    label: 'bids only (no offers) carries every bid forward, no deals',
    inputs: matcherInputs(
      bidsByFactionId: {
        'b': [matcherBid('timber', 5)],
      },
      tradeCapacityByFactionId: {'b': 100},
    ),
    expect: DealMatchExpectation(
      filledDealsEmpty: true,
      unfilledOffersEmpty: true,
      unfilledBidsByFactionId: {
        'b': [matcherBid('timber', 5)],
      },
      activityByCommodityId: const {
        'timber': MarketActivity(totalBidQuantity: 5),
      },
    ),
  ),
  DealMatcherScenario.expect(
    label: 'single offer 10 vs single bid 5 fills 5, offer carries 5 forward',
    inputs: matcherPairTrade(offerQty: 10, bidQty: 5),
    expect: DealMatchExpectation(
      filledDealsLength: 1,
      firstFilledDeal: const FilledDealExpectation(
        sellerFactionId: 'a',
        buyerFactionId: 'b',
        commodityId: 'timber',
        quantity: 5,
        pricePerUnit: 30.0,
      ),
      unfilledBidsEmpty: true,
      unfilledOffersByFactionId: {
        'a': [matcherOffer('timber', 5)],
      },
      activityByCommodityId: const {
        'timber': MarketActivity(
          totalBidQuantity: 5,
          totalOfferQuantity: 10,
          filledQuantity: 5,
        ),
      },
    ),
  ),
  DealMatcherScenario.expect(
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
    expect: const DealMatchExpectation(
      filledDealsLength: 1,
      firstFilledDeal: FilledDealExpectation(pricePerUnit: 0.0),
    ),
  ),
  DealMatcherScenario.expect(
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
    expect: DealMatchExpectation(
      filledDealsEmpty: true,
      unfilledOffersEmpty: true,
      unfilledBidsByFactionId: {
        'b': [matcherBid('timber', 5)],
      },
    ),
  ),
];

/// Cargo-enforcement scenarios from `world_market_deal_matcher_test.dart`.
List<DealMatcherScenario> dealMatcherCargoScenarios() => [
  DealMatcherScenario.expect(
    label: 'buyer with no tradeCapacity entry treated as zero cargo',
    inputs: matcherInputs(
      offersByFactionId: {
        'a': [matcherOffer('timber', 10)],
      },
      bidsByFactionId: {
        'b': [matcherBid('timber', 5)],
      },
    ),
    expect: DealMatchExpectation(
      filledDealsEmpty: true,
      unfilledBidsByFactionId: {
        'b': [matcherBid('timber', 5)],
      },
    ),
  ),
  DealMatcherScenario.expect(
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
    expect: DealMatchExpectation(
      filledDealsLength: 2,
      filledDealQuantityByCommodityId: const {'alpha': 8, 'beta': 7},
      unfilledBidsByFactionId: {
        'buyer': [matcherBid('beta', 3, priority: 2)],
      },
      activityByCommodityId: const {
        'alpha': MarketActivity(
          totalBidQuantity: 8,
          totalOfferQuantity: 100,
          filledQuantity: 8,
        ),
        'beta': MarketActivity(
          totalBidQuantity: 10,
          totalOfferQuantity: 100,
          filledQuantity: 7,
        ),
      },
    ),
    refs: null,
  ),
  DealMatcherScenario.expect(
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
    expect: DealMatchExpectation(
      filledDealsEmpty: true,
      unfilledBidsByFactionId: {
        'b': [matcherBid('timber', 5)],
      },
    ),
  ),
];

/// Boycott exclusion scenarios from `world_market_deal_matcher_boycott_test.dart`.
List<DealMatcherScenario> dealMatcherBoycottScenarios() => [
  DealMatcherScenario.expect(
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
    expect: DealMatchExpectation(
      filledDealsEmpty: true,
      unfilledOffersByFactionId: {
        'tribeT': [matcherOffer('timber', 10, priority: 1)],
      },
      unfilledBidsByFactionId: {
        'gpB': [matcherBid('timber', 10, priority: 1)],
      },
    ),
    refs: '#3753',
  ),
  DealMatcherScenario.expect(
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
    expect: const DealMatchExpectation(filledDealsEmpty: true),
    refs: '#3753',
  ),
  DealMatcherScenario.expect(
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
    expect: DealMatchExpectation(
      filledDealsLength: 1,
      firstFilledDeal: const FilledDealExpectation(
        sellerFactionId: 'tribeT',
        buyerFactionId: 'gpD',
        quantity: 10,
      ),
      unfilledBidsByFactionId: {
        'gpB': [matcherBid('timber', 10, priority: 1)],
      },
    ),
    refs: '#3753',
  ),
  DealMatcherScenario.expect(
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
    expect: const DealMatchExpectation(
      filledDealsLength: 1,
      firstFilledDeal: FilledDealExpectation(
        buyerFactionId: 'gpB',
        quantity: 10,
      ),
    ),
    refs: '#3753',
  ),
];
