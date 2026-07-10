// Consolidated world-market context, price-discovery, and purchased-tile runners
// (Refs #3939 phase 3 slice 2 + slice 30).
//
// SPEC/program/economy-models.md § Package locations (world-market player
// context facade), SPEC/game/world-market.md — issue #3396 cluster 4.
// SPEC/game/world-market-first-right-of-refusal.md § Purchased-tile index (D1)
// SPEC/game/world-market.md § Purchased-tile riches handoff

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

  group('PurchasedTileAttribution value semantics', () {
    for (final scenario in purchasedTileAttributionSemanticsScenarios()) {
      test(scenario.label, scenario.run);
    }
  });

  group('PurchasedTileIndex.fromGame', () {
    for (final scenario in purchasedTileIndexFromGameScenarios()) {
      test(scenario.label, () {
        final index = runPurchasedTileIndexFromGameScenario(scenario);
        scenario.verify(index);
      });
    }
  });

  group('computePurchasedTileRichesCredits — riches handoff per #2991 C5', () {
    for (final scenario in purchasedTileRichesScenarios()) {
      test(scenario.label, () {
        final game = scenario.buildGame();
        final index = PurchasedTileIndex.fromGame(game);
        final result = runPurchasedTileRichesScenario(scenario);
        scenario.verify(result, index, game);
      });
    }
  });
}
