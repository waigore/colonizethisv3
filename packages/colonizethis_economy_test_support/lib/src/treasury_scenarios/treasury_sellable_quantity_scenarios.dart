// dart format off
// Data-driven sellable / offer-cap scenarios (Refs #3856, #3939 phase 3 slice 8).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'treasury_test_support.dart';

/// Asserts [actual] matches [expected] keys/values and omits [absentKeys].
void assertCommodityQuantityMap(Map<CommodityId, int> actual, {required Map<CommodityId, int> expected, Set<CommodityId> absentKeys = const {}, int? expectedLength}) {
  for (final key in absentKeys) {
    expect(actual.containsKey(key), isFalse);
  }
  for (final MapEntry(:key, :value) in expected.entries) {
    expect(actual[key], value);
  }
  if (expectedLength != null) {
    expect(actual.length, expectedLength);
  }
}

/// One row in [offerCapByCommodityIdScenarios].
typedef OfferCapByCommodityIdScenario = ({String label, Map<CommodityId, int> stockpile, String playerId, Map<CommodityId, int> expected, Set<CommodityId> absentKeys, int? expectedLength, String? refs});

/// Canonical scenarios for [offerCapByCommodityId].
List<OfferCapByCommodityIdScenario> offerCapByCommodityIdScenarios() => [
  offerCapRow(label: 'returns empty map for unknown player', playerId: 'gp_ghost', expected: const {}, expectedLength: 0),
  offerCapRow(label: 'returns each non-riches stockpile quantity as the offer cap', stockpile: const {'timber': 10, 'iron': 7, 'fabric': 3}, expected: const {'timber': 10, 'iron': 7, 'fabric': 3}, expectedLength: 3),
  offerCapRow(label: 'excludes riches commodities (gold, silver, gems, diamonds, spices)', stockpile: const {'timber': 10, 'gold': 5, 'silver': 4, 'gems': 3, 'diamonds': 2, 'spices': 1}, expected: const {'timber': 10}, absentKeys: const {'gold', 'silver', 'gems', 'diamonds', 'spices'}),
  offerCapRow(label: 'skips commodities with non-positive stockpile', expected: const {'timber': 10}, absentKeys: const {'iron'}),
];

void verifyOfferCapScenario(OfferCapByCommodityIdScenario scenario) {
  final game = buildStockpilePlayerGame(stockpile: scenario.stockpile);
  final cap = offerCapByCommodityId(game: game, playerId: scenario.playerId);
  assertCommodityQuantityMap(cap, expected: scenario.expected, absentKeys: scenario.absentKeys, expectedLength: scenario.expectedLength);
}

/// One row in [stagedOfferQuantitiesByCommodityIdScenarios].
typedef StagedOfferQuantitiesScenario = ({String label, List<TradeOrder> orders, Map<CommodityId, int> expected, Set<CommodityId> absentKeys, String? refs});

/// Canonical scenarios for [stagedOfferQuantitiesByCommodityId].
List<StagedOfferQuantitiesScenario> stagedOfferQuantitiesByCommodityIdScenarios() => [
  stagedOfferQtyRow(label: 'returns empty map when no trade orders are staged', expected: const {}),
  stagedOfferQtyRow(label: 'sums quantities per commodity for offer-typed orders', orders: [offerOrder('timber', 5), offerOrder('iron', 3)], expected: const {'timber': 5, 'iron': 3}),
  stagedOfferQtyRow(label: 'excludes bid-typed orders', orders: [bidOrder('timber', 4), offerOrder('iron', 3)], expected: const {'iron': 3}, absentKeys: const {'timber'}),
  stagedOfferQtyRow(label: 'excludes non-positive quantities', orders: [offerOrder('timber', 0)], expected: const {}, absentKeys: const {'timber'}),
];

void verifyStagedOfferQuantitiesScenario(StagedOfferQuantitiesScenario scenario) {
  final staged = stagedOfferQuantitiesByCommodityId(orders: humanOrdersWith(scenario.orders), playerId: humanPlayerId);
  assertCommodityQuantityMap(staged, expected: scenario.expected, absentKeys: scenario.absentKeys);
}

/// One row in [sellableHeadroomByCommodityIdScenarios].
typedef SellableHeadroomScenario = ({String label, Map<CommodityId, int> stockpile, List<TradeOrder> orders, Map<CommodityId, int>? productionInputConsumptionByCommodityId, bool useEmptyProductionMap, Map<CommodityId, int> expected, Set<CommodityId> absentKeys, String? refs});

/// Compact row builder for [offerCapByCommodityIdScenarios] (Refs #3939 slice 47).
OfferCapByCommodityIdScenario offerCapRow({required String label, required Map<CommodityId, int> expected, Map<CommodityId, int> stockpile = const {'timber': 10}, String playerId = humanPlayerId, Set<CommodityId> absentKeys = const {}, int? expectedLength, String? refs = '#3093'}) => (label: label, stockpile: stockpile, playerId: playerId, expected: expected, absentKeys: absentKeys, expectedLength: expectedLength, refs: refs);

/// Compact row builder for [stagedOfferQuantitiesByCommodityIdScenarios]
/// (Refs #3939 slice 47).
StagedOfferQuantitiesScenario stagedOfferQtyRow({required String label, required Map<CommodityId, int> expected, List<TradeOrder> orders = const <TradeOrder>[], Set<CommodityId> absentKeys = const {}, String? refs = '#3093'}) => (label: label, orders: orders, expected: expected, absentKeys: absentKeys, refs: refs);

/// Compact row builder for [sellableHeadroomByCommodityIdScenarios] (Refs #3939 slice 40).
SellableHeadroomScenario sellableHeadroomRow({required String label, required Map<CommodityId, int> expected, Map<CommodityId, int> stockpile = const {'timber': 10}, List<TradeOrder> orders = const <TradeOrder>[], Map<CommodityId, int>? productionInputConsumptionByCommodityId, bool useEmptyProductionMap = false, Set<CommodityId> absentKeys = const {}, String? refs = '#3093'}) => (label: label, stockpile: stockpile, orders: orders, productionInputConsumptionByCommodityId: productionInputConsumptionByCommodityId, useEmptyProductionMap: useEmptyProductionMap, expected: expected, absentKeys: absentKeys, refs: refs);

/// Canonical scenarios for [sellableHeadroomByCommodityId].
List<SellableHeadroomScenario> sellableHeadroomByCommodityIdScenarios() => [
  sellableHeadroomRow(label: 'returns the offer cap when no offers are staged', stockpile: const {'timber': 10, 'iron': 7}, expected: const {'timber': 10, 'iron': 7}),
  sellableHeadroomRow(label: 'subtracts staged offer quantity from the cap to produce the `(N)` display headroom (default: industry allocation = 0)', orders: [offerOrder('timber', 2)], expected: const {'timber': 8}),
  sellableHeadroomRow(label: 'industry-allocation reservation: stockpile 10 timber, production consumes 2 timber, staged offer 2 → sellable 6 (canonical AC for Refs #3093 sellable definition)', orders: [offerOrder('timber', 2)], productionInputConsumptionByCommodityId: const {'timber': 2}, expected: const {'timber': 6}),
  sellableHeadroomRow(label: 'industry-allocation reservation: when consumption equals stockpile, cap is 0 → key omitted (Offer chip disabled)', productionInputConsumptionByCommodityId: const {'timber': 10}, expected: const {}, absentKeys: const {'timber'}),
  sellableHeadroomRow(label: 'industry-allocation reservation: negative consumption entries are clamped at 0 (defensive — caller cannot inflate the cap)', productionInputConsumptionByCommodityId: const {'timber': -100}, expected: const {'timber': 10}),
  sellableHeadroomRow(label: 'industry-allocation reservation: empty map matches null (both fall back to raw stockpile)', useEmptyProductionMap: true, expected: const {'timber': 10}),
  sellableHeadroomRow(label: 'industry-allocation reservation: consumption on one commodity does not affect another commodity\'s cap', stockpile: const {'timber': 10, 'iron': 7}, productionInputConsumptionByCommodityId: const {'timber': 4}, expected: const {'timber': 6, 'iron': 7}),
  sellableHeadroomRow(label: 'clamps headroom at 0 (drops the commodity) when staged offer reaches or exceeds the cap', stockpile: const {'timber': 5}, orders: [offerOrder('timber', 5)], expected: const {}, absentKeys: const {'timber'}),
  sellableHeadroomRow(label: 'bids do not consume the offer headroom', orders: [bidOrder('timber', 4)], expected: const {'timber': 10}),
  sellableHeadroomRow(label: 'riches commodities are excluded even when staged offers exist', stockpile: const {'timber': 10, 'gold': 4}, orders: [offerOrder('gold', 2)], expected: const {'timber': 10}, absentKeys: const {'gold'}),
];

/// Runs [sellableHeadroomByCommodityId] for one [SellableHeadroomScenario].
Map<CommodityId, int> runSellableHeadroomScenario(SellableHeadroomScenario scenario) {
  final game = buildStockpilePlayerGame(stockpile: scenario.stockpile);
  final orders = humanOrdersWith(scenario.orders);
  if (scenario.useEmptyProductionMap) {
    final viaNull = sellableHeadroomByCommodityId(game: game, playerId: humanPlayerId, orders: orders);
    final viaEmpty = sellableHeadroomByCommodityId(game: game, playerId: humanPlayerId, orders: orders, productionInputConsumptionByCommodityId: const <CommodityId, int>{});
    expect(viaNull['timber'], viaEmpty['timber']);
    return viaEmpty;
  }
  return sellableHeadroomByCommodityId(game: game, playerId: humanPlayerId, orders: orders, productionInputConsumptionByCommodityId: scenario.productionInputConsumptionByCommodityId);
}

void verifySellableHeadroomScenario(SellableHeadroomScenario scenario) {
  final sellable = runSellableHeadroomScenario(scenario);
  assertCommodityQuantityMap(sellable, expected: scenario.expected, absentKeys: scenario.absentKeys);
}
// dart format on
