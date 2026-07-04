/// Regression tests covering the performance-related refactors in
/// `quick_battle_resolver_*.dart` (Refs #2316 P1 #8 and P1 #9).
///
/// Table-driven scenarios in `colonizethis_combat_test_support` pin observable
/// outcomes through the public `resolveQuickBattle` entrypoint.
library;

import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('round-robin gun HP damage stays deterministic when guns die mid-round', () {
    for (final scenario in quickBattlePerfInvariantScenarios().take(2)) {
      test(scenario.label, () => runQuickBattlePerfInvariantScenario(scenario));
    }
  });

  group('effective-strength caching preserves outcomes across initiative branches', () {
    for (final scenario in quickBattlePerfInvariantScenarios().skip(2)) {
      test(scenario.label, () => runQuickBattlePerfInvariantScenario(scenario));
    }
  });
}
