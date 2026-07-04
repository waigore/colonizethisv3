// Table-driven tests for the world-market player-context facade — Refs #3856.
//
// SPEC/program/economy-models.md § Package locations (world-market player
// context facade), SPEC/program/world-market-resolution.md § Trade order
// validation / suggestion.
//
// Verifies `worldMarketPlayerContextFromGame` is the single Game→numeric
// snapshot build path and that `tradeOrderValidationContextFromGame` and
// `tradeSuggestionContextFromGame` are thin, behavior-preserving wrappers over
// it: identical shared scalars for the same (game, player), concern-specific
// availability sources preserved, staged treasury-budget parity, and ghost-id
// guard.

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('worldMarketPlayerContextFromGame (Refs #3615 Cluster 2)', () {
    for (final scenario in worldMarketPlayerContextSnapshotScenarios()) {
      test(scenario.label, () {
        runPlayerContextScenario(scenario);
      });
    }
    // Refs #3661 step 2: the standalone twin-call "deterministic for identical
    // inputs" pin was removed. `worldMarketPlayerContextFromGame` is a pure
    // synchronous builder, and the scalars it re-asserted are already pinned
    // here (`treasuryBudgetForBids` above) and by the factory-parity group
    // below (`bidTypeCap`, `tradeCargoCapacity`), so double-invocation added no
    // coverage. Determinism that matters (sort/iteration order) is pinned by
    // dedicated ordering tests elsewhere in the suite.
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
}
