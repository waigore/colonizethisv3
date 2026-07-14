/// Regression tests covering the performance-related refactors in
/// `quick_battle_resolver_*.dart` (Refs #2316 P1 #8 and P1 #9).
///
/// Table-driven scenarios in `colonizethis_combat_test_support` pin observable
/// outcomes through the public `resolveQuickBattle` entrypoint.
library;

import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'round-robin gun HP damage stays deterministic when guns die mid-round',
    quickBattlePerfInvariantScenarios().take(2),
    (s) => s.run(),
  );

  runLabeledScenarioGroup(
    'effective-strength caching preserves outcomes across initiative branches',
    quickBattlePerfInvariantScenarios().skip(2),
    (s) => s.run(),
  );
}
