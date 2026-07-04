// Covers bindGeneralsForCombatPhase pre-combat binding across multiple battle
// contexts (Refs #3290 Phase 1 combat extraction; test additions to reach the
// >=90% per-package coverage gate are in scope per issue F5).
import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('bindGeneralsForCombatPhase', () {
    for (final scenario in battleGeneralAssignmentBindPhaseScenarios()) {
      test(
        scenario.label,
        () => runBattleGeneralAssignmentBindPhaseScenario(scenario),
      );
    }
  });
}
