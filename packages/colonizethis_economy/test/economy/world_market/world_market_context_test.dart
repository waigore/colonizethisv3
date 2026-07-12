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
    runLabeledScenarios(worldMarketContextBaseScenarios(), (scenario) {
      final ctx = buildWorldMarketContextBaseScenario(scenario);
      assertWorldMarketContextBaseExpectation(ctx, scenario.expect);
    }, labelOf: (s) => s.label);
  });

  group('worldMarketPlayerContextFromGame (Refs #3615 Cluster 2)', () {
    runLabeledScenarios(worldMarketPlayerContextSnapshotScenarios(), (
      scenario,
    ) {
      runPlayerContextScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('factory parity over the shared snapshot (single build path)', () {
    runLabeledScenarios(worldMarketPlayerContextFactoryParityScenarios(), (
      scenario,
    ) {
      runPlayerContextScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('tradeSuggestionContextFromGame concern-specific behavior', () {
    runLabeledScenarios(tradeSuggestionContextFromGameBehaviorScenarios(), (
      scenario,
    ) {
      runPlayerContextScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('PriceDiscovery.computeNextPrice', () {
    runLabeledScenarios(priceDiscoveryNextPriceScenarios, (scenario) {
      runPriceDiscoveryNextPriceScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('PriceDiscovery.computeMarketActivity', () {
    runLabeledScenarios(priceDiscoveryMarketActivityScenarios(), (scenario) {
      runPriceDiscoveryMarketActivityScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('PriceDiscovery constants', () {
    test('match SPEC values', () {
      expect(PriceDiscovery.maxDeltaPerTurn, 0.20);
      expect(PriceDiscovery.deltaCoefficient, 0.5);
      expect(PriceDiscovery.priceFloorRatio, 0.30);
    });
  });

  group('PurchasedTileAttribution value semantics', () {
    runLabeledScenarios(purchasedTileAttributionSemanticsScenarios(), (
      scenario,
    ) {
      scenario.run();
    }, labelOf: (s) => s.label);
  });

  group('PurchasedTileIndex.fromGame', () {
    runLabeledScenarios(purchasedTileIndexFromGameScenarios(), (scenario) {
      final index = runPurchasedTileIndexFromGameScenario(scenario);
      scenario.verify(index);
    }, labelOf: (s) => s.label);
  });

  group('computePurchasedTileRichesCredits — riches handoff per #2991 C5', () {
    runLabeledScenarios(purchasedTileRichesScenarios(), (scenario) {
      final game = scenario.buildGame();
      final index = PurchasedTileIndex.fromGame(game);
      final result = runPurchasedTileRichesScenario(scenario);
      scenario.verify(result, index, game);
    }, labelOf: (s) => s.label);
  });
}
