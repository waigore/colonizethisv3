// Table-driven unit tests for PurchasedTileIndex (Refs #3856).

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

/// SPEC: SPEC/game/world-market-first-right-of-refusal.md
/// § Acceptance criteria → Purchased-tile index (D1) ACs D1-1 through D1-7.
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
}
