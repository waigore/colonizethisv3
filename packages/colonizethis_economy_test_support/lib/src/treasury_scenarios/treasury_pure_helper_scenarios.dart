// dart format off
// Pure treasury bid-budget helper scenario tables (Refs #3836, #3939 phase 3 slice 6).
import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'treasury_test_support.dart';
/// One row in [capBidQuantityForBudgetsScenarios].
typedef CapBidQuantityScenario = ({String label, int bidQuantity, int remainingCargoBudget, int remainingTreasuryBudget, int? unitPrice, int expected, String? refs});
final List<CapBidQuantityScenario> capBidQuantityForBudgetsScenarios = [
  capBidQtyRow(label: 'cargo-only cap when treasury is ample', remainingCargoBudget: 4, remainingTreasuryBudget: 1000, expected: 4, refs: '#3093'),
  capBidQtyRow(label: 'treasury-only cap when cargo is ample', remainingTreasuryBudget: 90, expected: 3, refs: '#3123'),
  capBidQtyRow(label: 'zero treasury budget yields zero', bidQuantity: 5, remainingTreasuryBudget: 0, expected: 0, refs: '#3123'),
  capBidQtyRow(label: 'zero cargo budget yields zero', bidQuantity: 5, remainingCargoBudget: 0, expected: 0, refs: null),
  capBidQtyRow(label: 'null unit price applies cargo cap only', bidQuantity: 8, remainingCargoBudget: 5, remainingTreasuryBudget: 10, unitPrice: null, expected: 5, refs: null),
  capBidQtyRow(label: 'non-positive unit price applies cargo cap only', bidQuantity: 8, remainingCargoBudget: 5, remainingTreasuryBudget: 10, unitPrice: 0, expected: 5, refs: null),
  capBidQtyRow(label: 'bid quantity below both caps passes through', bidQuantity: 2, expected: 2, refs: null),
  capBidQtyRow(label: 'non-positive bid quantity yields zero', bidQuantity: 0, expected: 0, refs: null),
];
/// One row in [effectiveMarketPriceScenarios].
typedef EffectiveMarketPriceScenario = ({String label, String commodityId, Map<CommodityId, int> prices, int? expected, bool useCatalogDefault, bool expectNull, String? refs});
const Map<CommodityId, int> _richesNullPriceStoredPrices = {'gold': 1000, 'silver': 500, 'gems': 999};
final List<EffectiveMarketPriceScenario> effectiveMarketPriceScenarios = [
  effectiveMarketPriceRow(label: 'returns the integer price from worldMarketState.prices when present', commodityId: 'timber', prices: {'timber': 42}, expected: 42, refs: '#3093'),
  effectiveMarketPriceRow(label: 'falls back to ResourceRules.defaultMarketPriceForCommodityId when the prices map omits the commodity', commodityId: 'timber', useCatalogDefault: true, refs: '#3093'),
  effectiveMarketPriceRow(label: 'falls back to the catalog manufactured base price when the prices map omits the commodity (Refs #3093 manufactured-default-prices)', commodityId: 'lumber', useCatalogDefault: true, refs: '#3093'),
  effectiveMarketPriceRow(label: 'returns null only when neither prices nor catalog has a value (defensive fallback for unknown / future commodity ids)', commodityId: 'not_a_commodity', expectNull: true),
  effectiveMarketPriceRichesRow(label: 'returns null for gold riches regardless of stored prices', commodityId: 'gold', prices: _richesNullPriceStoredPrices),
  effectiveMarketPriceRichesRow(label: 'returns null for silver riches regardless of stored prices', commodityId: 'silver', prices: _richesNullPriceStoredPrices),
  effectiveMarketPriceRow(label: 'treats negative stored prices as missing and falls back to catalog', commodityId: 'timber', prices: {'timber': -5}, useCatalogDefault: true),
];
int? expectedEffectiveMarketPrice(EffectiveMarketPriceScenario scenario, data.ResourceRules rules) {
  if (scenario.expectNull) {
    return null;
  }
  if (scenario.useCatalogDefault) {
    return rules.defaultMarketPriceForCommodityId(scenario.commodityId);
  }
  return scenario.expected;
}
/// One row in [maxAffordableBidQuantityScenarios].
typedef MaxAffordableBidQuantityScenario = ({String label, int bidRemaining, double pricePerUnit, int remainingTreasuryBudget, int expected, String? refs});
final List<MaxAffordableBidQuantityScenario> maxAffordableBidQuantityScenarios = [maxAffordableBidQtyRow(label: 'floor(treasury / price) when price is positive', expected: 3, refs: '#3115'), maxAffordableBidQtyRow(label: 'zero treasury budget yields zero', remainingTreasuryBudget: 0, expected: 0, refs: '#3115'), maxAffordableBidQtyRow(label: 'missing-price free-fill returns bid remaining', bidRemaining: 8, pricePerUnit: 0.0, remainingTreasuryBudget: 10, expected: 8, refs: '#3115'), maxAffordableBidQtyRow(label: 'negative price preserves free-fill contract', bidRemaining: 5, pricePerUnit: -1.0, remainingTreasuryBudget: 0, expected: 5, refs: '#3115')];
/// One row in [decrementTreasuryForFillScenarios].
typedef DecrementTreasuryForFillScenario = ({String label, String buyerFactionId, int matchQty, double pricePerUnit, int initialTreasury, int expectedTreasury, String? refs});
final List<DecrementTreasuryForFillScenario> decrementTreasuryForFillScenarios = [decrementTreasuryFillRow(label: 'decrements running treasury tally after a priced fill', matchQty: 3, pricePerUnit: 30.0, expectedTreasury: 10, refs: '#3856'), decrementTreasuryFillRow(label: 'skips decrement on missing-price free-fill path', matchQty: 5, pricePerUnit: 0.0, expectedTreasury: 100, refs: '#3856')];
void runDecrementTreasuryForFillScenario(DecrementTreasuryForFillScenario scenario) {
  final remaining = <String, int>{scenario.buyerFactionId: scenario.initialTreasury};
  decrementTreasuryForFill(buyerFactionId: scenario.buyerFactionId, matchQty: scenario.matchQty, pricePerUnit: scenario.pricePerUnit, remainingTreasuryByBuyerFactionId: remaining);
  expect(remaining[scenario.buyerFactionId], scenario.expectedTreasury);
}
/// One row in [gpTreasuryCreditIntScenarios] / [gpTreasuryCreditDoubleScenarios].
typedef GpTreasuryCreditScenario<T extends num> = ({String label, void Function(GpTreasuryCreditAccumulator<T> acc) setup, void Function(GpTreasuryCreditAccumulator<T> acc) verify, String? refs});
GpTreasuryCreditScenario<T> gpTreasuryCreditScenarioExpect<T extends num>({required String label, void Function(GpTreasuryCreditAccumulator<T> acc)? setup, required GpTreasuryCreditExpectation<T> expect, String? refs}) => (label: label, setup: setup ?? (_) {}, verify: (acc) => assertGpTreasuryCreditExpectation(acc, expect), refs: refs);
void runGpTreasuryCreditScenario<T extends num>(GpTreasuryCreditScenario<T> scenario, T zero) {
  final acc = GpTreasuryCreditAccumulator<T>(zero);
  scenario.setup(acc);
  scenario.verify(acc);
}
List<GpTreasuryCreditScenario<int>> gpTreasuryCreditIntScenarios() => [
  gpTreasuryCreditScenarioExpect<int>(
    label: 'starts empty with a zero total',
    expect: const GpTreasuryCreditExpectation<int>(isEmpty: true, total: 0, view: {}),
  ),
  gpTreasuryCreditScenarioExpect<int>(
    label: 'add creates and accumulates entries, total stays incremental',
    setup: (acc) => acc
      ..add('gpA', 10)
      ..add('gpB', 5)
      ..add('gpA', 3),
    expect: const GpTreasuryCreditExpectation<int>(view: {'gpA': 13, 'gpB': 5}, total: 18, isEmpty: false),
  ),
  gpTreasuryCreditScenarioExpect<int>(
    label: 'view preserves first-seen insertion order',
    setup: (acc) => acc
      ..add('gpC', 1)
      ..add('gpA', 1)
      ..add('gpB', 1)
      ..add('gpA', 1),
    expect: const GpTreasuryCreditExpectation<int>(viewKeyOrder: ['gpC', 'gpA', 'gpB']),
  ),
  gpTreasuryCreditScenarioExpect<int>(label: 'view is unmodifiable', setup: (acc) => acc.add('gpA', 1), expect: const GpTreasuryCreditExpectation<int>(viewUnmodifiable: true)),
  gpTreasuryCreditScenarioExpect<int>(
    label: 'incremental total equals the naive re-summed view total',
    setup: (acc) => acc
      ..add('gpA', 7)
      ..add('gpB', 11)
      ..add('gpA', 2),
    expect: const GpTreasuryCreditExpectation<int>(totalEqualsNaiveViewSum: true),
  ),
];
List<GpTreasuryCreditScenario<double>> gpTreasuryCreditDoubleScenarios() => [
  gpTreasuryCreditScenarioExpect<double>(
    label: 'ensure records a zero entry without changing the total',
    setup: (acc) => acc
      ..add('gpA', 40.0)
      ..ensure('gpB'),
    expect: const GpTreasuryCreditExpectation<double>(view: {'gpA': 40.0, 'gpB': 0.0}, total: 40.0),
  ),
  gpTreasuryCreditScenarioExpect<double>(
    label: 'ensure is a no-op when the key already has a credit',
    setup: (acc) => acc
      ..add('gpA', 12.5)
      ..ensure('gpA'),
    expect: const GpTreasuryCreditExpectation<double>(view: {'gpA': 12.5}, total: 12.5),
  ),
  gpTreasuryCreditScenarioExpect<double>(
    label: 'total matches naive re-sum including a zero-profit entry',
    setup: (acc) => acc
      ..add('gpA', 4.6)
      ..add('gpB', 40.0)
      ..ensure('gpC')
      ..add('gpA', 0.4),
    expect: const GpTreasuryCreditExpectation<double>(totalEqualsNaiveViewSum: true, viewCloseTo: {'gpC': 0.0}),
  ),
];
void runGpTreasuryCreditIntScenario(GpTreasuryCreditScenario<int> scenario) => runGpTreasuryCreditScenario(scenario, 0);
void runGpTreasuryCreditDoubleScenario(GpTreasuryCreditScenario<double> scenario) => runGpTreasuryCreditScenario(scenario, 0.0);
// dart format on
