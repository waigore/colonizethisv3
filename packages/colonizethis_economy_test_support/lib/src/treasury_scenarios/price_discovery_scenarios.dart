// dart format off
// Table-driven PriceDiscovery scenarios (Refs #3856).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'price_discovery_expectations.dart';

/// One row in [priceDiscoveryNextPriceScenarios].
typedef PriceDiscoveryNextPriceScenario = ({String label, double oldPrice, int basePrice, int newBidQuantity, int newOfferQuantity, double expectedPrice, double tolerance, String? refs});

/// Canonical scenarios for [PriceDiscovery.computeNextPrice].
const List<PriceDiscoveryNextPriceScenario> priceDiscoveryNextPriceScenarios = [
  (label: 'zero volume returns oldPrice unchanged', oldPrice: 100.0, basePrice: 100, newBidQuantity: 0, newOfferQuantity: 0, expectedPrice: 100.0, tolerance: 0.0, refs: null),
  (label: 'bid 20 / offer 10 / oldPrice 100 / base 100 -> ~116.6666 (under cap)', oldPrice: 100.0, basePrice: 100, newBidQuantity: 20, newOfferQuantity: 10, expectedPrice: 100.0 * (1.0 + 1.0 / 6.0), tolerance: 1e-9, refs: null),
  (label: 'extreme bid (1000 vs 0) caps delta at +0.20 -> 120.0', oldPrice: 100.0, basePrice: 100, newBidQuantity: 1000, newOfferQuantity: 0, expectedPrice: 120.0, tolerance: 1e-9, refs: null),
  (label: 'extreme offer (0 vs 1000) caps delta at -0.20 -> 80.0', oldPrice: 100.0, basePrice: 100, newBidQuantity: 0, newOfferQuantity: 1000, expectedPrice: 80.0, tolerance: 1e-9, refs: null),
  (label: 'floor clamp: oldPrice 32 with base 100 stays at 30.0', oldPrice: 32.0, basePrice: 100, newBidQuantity: 0, newOfferQuantity: 1000, expectedPrice: 30.0, tolerance: 0.0, refs: null),
  (label: 'floor clamp: oldPrice 30 (already at floor) stays at 30.0', oldPrice: 30.0, basePrice: 100, newBidQuantity: 0, newOfferQuantity: 1000, expectedPrice: 30.0, tolerance: 0.0, refs: null),
  (label: 'zero oldPrice (defensive) recovers to floor on positive volume', oldPrice: 0.0, basePrice: 100, newBidQuantity: 5, newOfferQuantity: 5, expectedPrice: 30.0, tolerance: 0.0, refs: null),
  (label: 'balanced bid==offer keeps oldPrice (delta = 0)', oldPrice: 50.0, basePrice: 50, newBidQuantity: 7, newOfferQuantity: 7, expectedPrice: 50.0, tolerance: 0.0, refs: null),
  (label: 'negative-leaning ratio applies symmetric formula', oldPrice: 100.0, basePrice: 100, newBidQuantity: 10, newOfferQuantity: 20, expectedPrice: 100.0 * (1.0 - 1.0 / 6.0), tolerance: 1e-9, refs: null),
];

/// One row in [priceDiscoveryMarketActivityScenarios].
typedef PriceDiscoveryMarketActivityScenario = ({String label, double oldPrice, int basePrice, int newBidQuantity, int newOfferQuantity, int filledQuantity, PriceDiscoveryMarketActivityExpectation expect, String? refs});

/// Canonical scenarios for [PriceDiscovery.computeMarketActivity].
List<PriceDiscoveryMarketActivityScenario> priceDiscoveryMarketActivityScenarios() => [
  (label: 'records new totals and computes priceChangePercent', oldPrice: 100.0, basePrice: 100, newBidQuantity: 20, newOfferQuantity: 10, filledQuantity: 10, expect: const PriceDiscoveryMarketActivityExpectation(totalBidQuantity: 20, totalOfferQuantity: 10, filledQuantity: 10, priceChangePercentCloseTo: 1.0 / 6.0), refs: null),
  (label: 'zero volume yields 0 priceChangePercent', oldPrice: 100.0, basePrice: 100, newBidQuantity: 0, newOfferQuantity: 0, filledQuantity: 0, expect: const PriceDiscoveryMarketActivityExpectation(priceChangePercent: 0.0), refs: null),
  (label: 'zero oldPrice (defensive) yields 0 priceChangePercent', oldPrice: 0.0, basePrice: 100, newBidQuantity: 5, newOfferQuantity: 5, filledQuantity: 5, expect: const PriceDiscoveryMarketActivityExpectation(priceChangePercent: 0.0), refs: null),
  (label: 'returns MarketActivity instance compatible with empty equality', oldPrice: 100.0, basePrice: 100, newBidQuantity: 0, newOfferQuantity: 0, filledQuantity: 0, expect: const PriceDiscoveryMarketActivityExpectation(equalsEmpty: true), refs: null),
];

/// Runs a [PriceDiscovery.computeNextPrice] scenario row.
void runPriceDiscoveryNextPriceScenario(PriceDiscoveryNextPriceScenario scenario) {
  final price = PriceDiscovery.computeNextPrice((oldPrice: scenario.oldPrice, basePrice: scenario.basePrice, newBidQuantity: scenario.newBidQuantity, newOfferQuantity: scenario.newOfferQuantity));
  if (scenario.tolerance > 0) {
    expect(price, closeTo(scenario.expectedPrice, scenario.tolerance));
  } else {
    expect(price, scenario.expectedPrice);
  }
}

/// Runs a [PriceDiscovery.computeMarketActivity] scenario row.
void runPriceDiscoveryMarketActivityScenario(PriceDiscoveryMarketActivityScenario scenario) {
  final activity = PriceDiscovery.computeMarketActivity((oldPrice: scenario.oldPrice, basePrice: scenario.basePrice, newBidQuantity: scenario.newBidQuantity, newOfferQuantity: scenario.newOfferQuantity), filledQuantity: scenario.filledQuantity);
  assertPriceDiscoveryMarketActivityExpectation(activity, scenario.expect);
}
// dart format on
