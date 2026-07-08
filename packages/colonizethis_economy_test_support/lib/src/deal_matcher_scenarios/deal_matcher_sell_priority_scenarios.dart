// Table-driven DealMatcher sell-priority scenarios (Refs #3836).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'deal_matcher_core_scenarios.dart';
import 'deal_matcher_expectations.dart';
import 'deal_matcher_test_support.dart';

/// Sell-priority relation tiebreaker from
/// `world_market_deal_matcher_sell_priority_test.dart`.
List<DealMatcherScenario> dealMatcherSellPriorityScenarios() => [
  DealMatcherScenario.expect(
    label: 'higher-relation consulate-holding buyer wins limited supply',
    inputs: matcherInputs(
      offersByFactionId: {
        'minorM': [matcherOffer('timber', 5, priority: 1)],
      },
      bidsByFactionId: {
        'gpHigh': [matcherBid('timber', 5, priority: 1)],
        'gpLow': [matcherBid('timber', 5, priority: 1)],
      },
      tradeCapacityByFactionId: const {'gpHigh': 100, 'gpLow': 100},
      sellPriorityRelationByMinorTribeSeller: const {
        'minorM': {'gpHigh': 80, 'gpLow': 40},
      },
    ),
    expect: DealMatchExpectation(
      filledDealsLength: 1,
      singleFilledDeal: (deal) {
        expect(deal.buyerFactionId, 'gpHigh');
        expect(deal.quantity, 5);
      },
      unfilledBidsByFactionId: {
        'gpLow': [matcherBid('timber', 5, priority: 1)],
      },
    ),
    refs: '#3753',
  ),
  DealMatcherScenario.expect(
    label: 'relation order overrides default ascending-faction-id order',
    inputs: matcherInputs(
      offersByFactionId: {
        'minorM': [matcherOffer('timber', 4, priority: 1)],
      },
      bidsByFactionId: {
        'aBuyer': [matcherBid('timber', 4, priority: 1)],
        'zBuyer': [matcherBid('timber', 4, priority: 1)],
      },
      tradeCapacityByFactionId: const {'aBuyer': 100, 'zBuyer': 100},
      sellPriorityRelationByMinorTribeSeller: const {
        'minorM': {'aBuyer': 30, 'zBuyer': 90},
      },
    ),
    expect: DealMatchExpectation(
      singleFilledDeal: (deal) => expect(deal.buyerFactionId, 'zBuyer'),
    ),
    refs: '#3753',
  ),
  DealMatcherScenario.expect(
    label: 'consulate-less buyer falls back behind consulate-holding buyer',
    inputs: matcherInputs(
      offersByFactionId: {
        'minorM': [matcherOffer('timber', 5, priority: 1)],
      },
      bidsByFactionId: {
        'gpHigh': [matcherBid('timber', 5, priority: 1)],
        'gpLow': [matcherBid('timber', 5, priority: 1)],
      },
      tradeCapacityByFactionId: const {'gpHigh': 100, 'gpLow': 100},
      sellPriorityRelationByMinorTribeSeller: const {
        'minorM': {'gpLow': 40},
      },
    ),
    expect: DealMatchExpectation(
      singleFilledDeal: (deal) => expect(deal.buyerFactionId, 'gpLow'),
      unfilledBidsByFactionId: {
        'gpHigh': [matcherBid('timber', 5, priority: 1)],
      },
    ),
    refs: '#3753',
  ),
  DealMatcherScenario.expect(
    label: 'relation tie breaks deterministically by ascending faction id',
    inputs: matcherInputs(
      offersByFactionId: {
        'minorM': [matcherOffer('timber', 5, priority: 1)],
      },
      bidsByFactionId: {
        'gpB': [matcherBid('timber', 5, priority: 1)],
        'gpA': [matcherBid('timber', 5, priority: 1)],
      },
      tradeCapacityByFactionId: const {'gpA': 100, 'gpB': 100},
      sellPriorityRelationByMinorTribeSeller: const {
        'minorM': {'gpA': 55, 'gpB': 55},
      },
    ),
    expect: DealMatchExpectation(
      singleFilledDeal: (deal) => expect(deal.buyerFactionId, 'gpA'),
    ),
    refs: '#3753',
  ),
  DealMatcherScenario.expect(
    label: 'seller absent from map keeps legacy ordering (no reorder)',
    inputs: matcherInputs(
      offersByFactionId: {
        'minorN': [matcherOffer('timber', 5, priority: 1)],
      },
      bidsByFactionId: {
        'gpA': [matcherBid('timber', 5, priority: 1)],
        'gpZ': [matcherBid('timber', 5, priority: 1)],
      },
      tradeCapacityByFactionId: const {'gpA': 100, 'gpZ': 100},
      sellPriorityRelationByMinorTribeSeller: const {
        'minorM': {'gpA': 1, 'gpZ': 99},
      },
    ),
    expect: DealMatchExpectation(
      singleFilledDeal: (deal) => expect(deal.buyerFactionId, 'gpA'),
    ),
    refs: '#3753',
  ),
  DealMatcherScenario.expect(
    label: 'empty relation map preserves legacy ordering for minor seller',
    inputs: matcherInputs(
      offersByFactionId: {
        'minorM': [matcherOffer('timber', 5, priority: 1)],
      },
      bidsByFactionId: {
        'gpA': [matcherBid('timber', 5, priority: 1)],
        'gpZ': [matcherBid('timber', 5, priority: 1)],
      },
      tradeCapacityByFactionId: const {'gpA': 100, 'gpZ': 100},
    ),
    expect: DealMatchExpectation(
      singleFilledDeal: (deal) => expect(deal.buyerFactionId, 'gpA'),
    ),
    refs: '#3753',
  ),
  DealMatcherScenario(
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
    verify: (result) {
      expect(result.filledDeals, hasLength(2));
      expect(result.filledDeals.first.buyerFactionId, 'gpLow');
      expect(result.filledDeals[1].buyerFactionId, 'gpHigh');
    },
    refs: '#3753',
  ),
];
