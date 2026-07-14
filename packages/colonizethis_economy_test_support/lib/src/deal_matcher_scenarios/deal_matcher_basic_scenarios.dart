// Table-driven DealMatcher scenarios (Refs #3836, #3939).
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'deal_matcher_expectations.dart';
import 'deal_matcher_scenario.dart';
import 'deal_matcher_test_support.dart';
/// Empty-input and basic-fill scenarios from `world_market_deal_matcher_test.dart`.
// dart format off
List<DealMatcherScenario> dealMatcherEmptyAndBasicScenarios() => [
  matcherRow(label: 'no offers and no bids returns DealMatchResult.empty', inputs: matcherInputs(), expect: const DealMatchExpectation(resultEqualsEmpty: true)),
  matcherUnilateralRow(label: 'offers only (no bids) carries every offer forward, no deals', offersByFactionId: matcherUnfilledOffer('a', 5), expect: DealMatchExpectation(filledDealsEmpty: true, unfilledBidsEmpty: true, unfilledOffersByFactionId: matcherUnfilledOffer('a', 5), activityByCommodityId: {'timber': matcherActivity(offer: 5)})),
  matcherUnilateralRow(label: 'bids only (no offers) carries every bid forward, no deals', bidsByFactionId: matcherUnfilledBid('b', 5), tradeCapacityByFactionId: {'b': 100}, expect: DealMatchExpectation(filledDealsEmpty: true, unfilledOffersEmpty: true, unfilledBidsByFactionId: matcherUnfilledBid('b', 5), activityByCommodityId: {'timber': matcherActivity(bid: 5)})),
  matcherPairRow(label: 'single offer 10 vs single bid 5 fills 5, offer carries 5 forward', expect: matcherSingleFillExpect(seller: 'a', buyer: 'b', commodity: 'timber', quantity: 5, pricePerUnit: 30.0, unfilledBidsEmpty: true, unfilledOffersByFactionId: matcherUnfilledOffer('a', 5), activityByCommodityId: {'timber': matcherActivity(bid: 5, offer: 10, filled: 5)})),
  matcherPairRow(label: 'missing price for commodity records pricePerUnit = 0.0', commodity: 'iron', offerQty: 5, bidQty: 5, pricesByCommodityId: const <CommodityId, double>{}, expect: matcherSingleFillExpect(pricePerUnit: 0.0)),
  matcherPairRow(label: 'zero-quantity offer emits no deal and no carry-forward', offerQty: 0, expect: matcherNoFillExpect(unfilledOffersEmpty: true, unfilledBidsByFactionId: matcherUnfilledBid('b', 5))),
];
/// Cargo-enforcement scenarios from `world_market_deal_matcher_test.dart`.
List<DealMatcherScenario> dealMatcherCargoScenarios() => [
  matcherPairRow(label: 'buyer with no tradeCapacity entry treated as zero cargo', buyerCapacity: null, expect: matcherNoFillExpect(unfilledBidsByFactionId: matcherUnfilledBid('b', 5))),
  matcherRow(label: 'cross-commodity cargo: A=8 priority-1, B=10 priority-2 with tradeCapacity 15 -> A fills 8, B partial 7, B carry 3', inputs: matcherInputs(offersByFactionId: {'sellerA': [matcherOffer('alpha', 100, priority: 1)], 'sellerB': [matcherOffer('beta', 100, priority: 2)]}, bidsByFactionId: {'buyer': [matcherBid('alpha', 8, priority: 1), matcherBid('beta', 10, priority: 2)]}, tradeCapacityByFactionId: {'buyer': 15}, pricesByCommodityId: const {'alpha': 5.0, 'beta': 10.0}), expect: DealMatchExpectation(filledDealsLength: 2, filledDealQuantityByCommodityId: const {'alpha': 8, 'beta': 7}, unfilledBidsByFactionId: matcherUnfilledBid('buyer', 3, commodity: 'beta', priority: 2), activityByCommodityId: {'alpha': matcherActivity(bid: 8, offer: 100, filled: 8), 'beta': matcherActivity(bid: 10, offer: 100, filled: 7)}), refs: null),
  matcherPairRow(label: 'negative tradeCapacity is clamped to zero', offerQty: 5, buyerCapacity: -50, expect: matcherNoFillExpect(unfilledBidsByFactionId: matcherUnfilledBid('b', 5))),
];
/// Boycott exclusion scenarios from `world_market_deal_matcher_boycott_test.dart`.
List<DealMatcherScenario> dealMatcherBoycottScenarios() => [
  boycottTradeRow(label: 'blocks trade where target GP buys goods a colony Tribe sells', seller: 'tribeT', buyer: 'gpB', boycottBlockedPairKeys: {DealMatcher.pairKey('tribeT', 'gpB')}, expect: matcherNoFillExpect(unfilledOffersByFactionId: matcherUnfilledOffer('tribeT', 10), unfilledBidsByFactionId: matcherUnfilledBid('gpB', 10))),
  boycottTradeRow(label: 'block is bidirectional (colony Tribe buying goods target GP sells)', seller: 'gpB', buyer: 'tribeT', boycottBlockedPairKeys: {DealMatcher.pairKey('tribeT', 'gpB')}, expect: matcherNoFillExpect()),
  matcherRow(label: 'only the boycotted GP is blocked; other buyers still trade', inputs: matcherInputs(offersByFactionId: {'tribeT': [matcherOffer('timber', 10, priority: 1)]}, bidsByFactionId: {'gpB': [matcherBid('timber', 10, priority: 1)], 'gpD': [matcherBid('timber', 10, priority: 1)]}, tradeCapacityByFactionId: const {'gpB': 100, 'gpD': 100}, boycottBlockedPairKeys: {DealMatcher.pairKey('tribeT', 'gpB')}), expect: matcherSingleFillExpect(seller: 'tribeT', buyer: 'gpD', quantity: 10, unfilledBidsByFactionId: matcherUnfilledBid('gpB', 10)), refs: '#3753'),
  boycottTradeRow(label: 'empty blocked set is a no-op (legacy matching preserved)', seller: 'tribeT', buyer: 'gpB', expect: matcherSingleFillExpect(buyer: 'gpB', quantity: 10)),
];
// dart format on
