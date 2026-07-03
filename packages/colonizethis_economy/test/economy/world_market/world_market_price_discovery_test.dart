// Table-driven unit tests for PriceDiscovery (Refs #3856).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('PriceDiscovery.computeNextPrice', () {
    for (final scenario in priceDiscoveryNextPriceScenarios) {
      test(scenario.label, () {
        runPriceDiscoveryNextPriceScenario(scenario);
      });
    }
  });

  group('PriceDiscovery.computeMarketActivity', () {
    for (final scenario in priceDiscoveryMarketActivityScenarios()) {
      test(scenario.label, () {
        runPriceDiscoveryMarketActivityScenario(scenario);
      });
    }
  });

  group('PriceDiscovery constants', () {
    test('match SPEC values', () {
      expect(PriceDiscovery.maxDeltaPerTurn, 0.20);
      expect(PriceDiscovery.deltaCoefficient, 0.5);
      expect(PriceDiscovery.priceFloorRatio, 0.30);
    });
  });
}
