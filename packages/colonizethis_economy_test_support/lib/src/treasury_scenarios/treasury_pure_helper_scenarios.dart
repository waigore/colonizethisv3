// Pure treasury bid-budget helper scenario tables (Refs #3836, #3939 phase 3 slice 6).

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_models/colonizethis_models.dart';

/// One row in [capBidQuantityForBudgetsScenarios].
typedef CapBidQuantityScenario = ({
  String label,
  int bidQuantity,
  int remainingCargoBudget,
  int remainingTreasuryBudget,
  int? unitPrice,
  int expected,
  String? refs,
});

const List<CapBidQuantityScenario> capBidQuantityForBudgetsScenarios = [
  (
    label: 'cargo-only cap when treasury is ample',
    bidQuantity: 10,
    remainingCargoBudget: 4,
    remainingTreasuryBudget: 1000,
    unitPrice: 30,
    expected: 4,
    refs: '#3093',
  ),
  (
    label: 'treasury-only cap when cargo is ample',
    bidQuantity: 10,
    remainingCargoBudget: 100,
    remainingTreasuryBudget: 90,
    unitPrice: 30,
    expected: 3,
    refs: '#3123',
  ),
  (
    label: 'zero treasury budget yields zero',
    bidQuantity: 5,
    remainingCargoBudget: 100,
    remainingTreasuryBudget: 0,
    unitPrice: 30,
    expected: 0,
    refs: '#3123',
  ),
  (
    label: 'zero cargo budget yields zero',
    bidQuantity: 5,
    remainingCargoBudget: 0,
    remainingTreasuryBudget: 100,
    unitPrice: 30,
    expected: 0,
    refs: null,
  ),
  (
    label: 'null unit price applies cargo cap only',
    bidQuantity: 8,
    remainingCargoBudget: 5,
    remainingTreasuryBudget: 10,
    unitPrice: null,
    expected: 5,
    refs: null,
  ),
  (
    label: 'non-positive unit price applies cargo cap only',
    bidQuantity: 8,
    remainingCargoBudget: 5,
    remainingTreasuryBudget: 10,
    unitPrice: 0,
    expected: 5,
    refs: null,
  ),
  (
    label: 'bid quantity below both caps passes through',
    bidQuantity: 2,
    remainingCargoBudget: 10,
    remainingTreasuryBudget: 100,
    unitPrice: 30,
    expected: 2,
    refs: null,
  ),
  (
    label: 'non-positive bid quantity yields zero',
    bidQuantity: 0,
    remainingCargoBudget: 10,
    remainingTreasuryBudget: 100,
    unitPrice: 30,
    expected: 0,
    refs: null,
  ),
];

/// One row in [effectiveMarketPriceScenarios].
typedef EffectiveMarketPriceScenario = ({
  String label,
  String commodityId,
  Map<CommodityId, int> prices,
  int? expected,
  bool useCatalogDefault,
  bool expectNull,
  String? refs,
});

const List<EffectiveMarketPriceScenario> effectiveMarketPriceScenarios = [
  (
    label:
        'returns the integer price from worldMarketState.prices when present',
    commodityId: 'timber',
    prices: {'timber': 42},
    expected: 42,
    useCatalogDefault: false,
    expectNull: false,
    refs: '#3093',
  ),
  (
    label: 'falls back to ResourceRules.defaultMarketPriceForCommodityId when '
        'the prices map omits the commodity',
    commodityId: 'timber',
    prices: {},
    expected: null,
    useCatalogDefault: true,
    expectNull: false,
    refs: '#3093',
  ),
  (
    label: 'falls back to the catalog manufactured base price when the '
        'prices map omits the commodity (Refs #3093 manufactured-default-prices)',
    commodityId: 'lumber',
    prices: {},
    expected: null,
    useCatalogDefault: true,
    expectNull: false,
    refs: '#3093',
  ),
  (
    label: 'returns null only when neither prices nor catalog has a value '
        '(defensive fallback for unknown / future commodity ids)',
    commodityId: 'not_a_commodity',
    prices: {},
    expected: null,
    useCatalogDefault: false,
    expectNull: true,
    refs: null,
  ),
  (
    label: 'returns null for riches commodities regardless of stored prices',
    commodityId: 'gold',
    prices: {'gold': 1000, 'silver': 500, 'gems': 999},
    expected: null,
    useCatalogDefault: false,
    expectNull: true,
    refs: null,
  ),
  (
    label: 'treats negative stored prices as missing and falls back to catalog',
    commodityId: 'timber',
    prices: {'timber': -5},
    expected: null,
    useCatalogDefault: true,
    expectNull: false,
    refs: null,
  ),
];

int? expectedEffectiveMarketPrice(
  EffectiveMarketPriceScenario scenario,
  data.ResourceRules rules,
) {
  if (scenario.expectNull) {
    return null;
  }
  if (scenario.useCatalogDefault) {
    return rules.defaultMarketPriceForCommodityId(scenario.commodityId);
  }
  return scenario.expected;
}

/// One row in [maxAffordableBidQuantityScenarios].
typedef MaxAffordableBidQuantityScenario = ({
  String label,
  int bidRemaining,
  double pricePerUnit,
  int remainingTreasuryBudget,
  int expected,
  String? refs,
});

const List<MaxAffordableBidQuantityScenario> maxAffordableBidQuantityScenarios =
    [
  (
    label: 'floor(treasury / price) when price is positive',
    bidRemaining: 10,
    pricePerUnit: 30.0,
    remainingTreasuryBudget: 90,
    expected: 3,
    refs: '#3115',
  ),
  (
    label: 'zero treasury budget yields zero',
    bidRemaining: 10,
    pricePerUnit: 30.0,
    remainingTreasuryBudget: 0,
    expected: 0,
    refs: '#3115',
  ),
  (
    label: 'missing-price free-fill returns bid remaining',
    bidRemaining: 8,
    pricePerUnit: 0.0,
    remainingTreasuryBudget: 10,
    expected: 8,
    refs: '#3115',
  ),
  (
    label: 'negative price preserves free-fill contract',
    bidRemaining: 5,
    pricePerUnit: -1.0,
    remainingTreasuryBudget: 0,
    expected: 5,
    refs: '#3115',
  ),
];
