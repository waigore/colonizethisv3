/// Table-driven unit tests for `computePurchasedTileRichesCredits` (Refs #3856).
///
/// SPEC anchors:
///   - SPEC/game/world-market.md § First right of refusal § Riches handoff
///   - SPEC/game/world-market.md § Acceptance criteria — Purchased-tile
///     riches handoff (credit / non-riches resource / unimproved tile /
///     post-conquest filter).
///   - SPEC/program/turn-resolution-phase-details.md § Riches to treasury
///     (purchased-tile credits paragraph).
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
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
