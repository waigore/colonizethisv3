// Consolidated purchased-tile runners (Refs #3939 phase 3 slice 2).
//
// SPEC: SPEC/game/world-market-first-right-of-refusal.md § Purchased-tile index (D1)
// SPEC/game/world-market.md § Purchased-tile riches handoff

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
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
