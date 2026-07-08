// Consolidated world-market context and price-discovery runners (Refs #3939 phase 3 slice 2).
//
// SPEC/program/economy-models.md § Package locations (world-market player
// context facade), SPEC/game/world-market.md — issue #3396 cluster 4.

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('WorldMarketContextBase', () {
    for (final scenario in worldMarketContextBaseScenarios()) {
      test(scenario.label, () {
        final ctx = buildWorldMarketContextBaseScenario(scenario);
        assertWorldMarketContextBaseExpectation(ctx, scenario.expect);
      });
    }
  });

  group('worldMarketPlayerContextFromGame (Refs #3615 Cluster 2)', () {
    for (final scenario in worldMarketPlayerContextSnapshotScenarios()) {
      test(scenario.label, () {
        runPlayerContextScenario(scenario);
      });
    }
  });

  group('factory parity over the shared snapshot (single build path)', () {
    for (final scenario in worldMarketPlayerContextFactoryParityScenarios()) {
      test(scenario.label, () {
        runPlayerContextScenario(scenario);
      });
    }
  });

  group('tradeSuggestionContextFromGame concern-specific behavior', () {
    for (final scenario in tradeSuggestionContextFromGameBehaviorScenarios()) {
      test(scenario.label, () {
        runPlayerContextScenario(scenario);
      });
    }
  });

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
