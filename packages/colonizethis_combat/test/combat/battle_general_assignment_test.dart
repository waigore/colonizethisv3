import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('assignGeneralsForBattleContext + CombatPhaseGeneralLedger', () {
    for (final scenario in battleGeneralAssignmentScenarios()) {
      test(scenario.label, () => runBattleGeneralAssignmentScenario(scenario));
    }
  });
}
