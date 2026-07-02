// Table-driven effective-market-price scenarios (Refs #3836).

import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_models/colonizethis_models.dart';

/// One row in the [effectiveMarketPriceScenarios] table.
typedef EffectiveMarketPriceScenario = ({
  String label,
  String commodityId,
  Map<CommodityId, int> prices,
  int? expected,
  bool useCatalogDefault,
  bool expectNull,
  String? refs,
});

/// Canonical scenarios for [effectiveMarketPriceForCommodityId].
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

/// Resolves the expected price for a scenario row at test runtime.
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
