import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('isCapitalSiege', () {
    for (final scenario in isCapitalSiegeScenarios()) {
      test(scenario.label, () => runCombatModeSelectionScenario(scenario));
    }
  });

  group('resolveCombatModeForBattle', () {
    for (final scenario in resolveCombatModeForBattleScenarios()) {
      test(scenario.label, () => runCombatModeSelectionScenario(scenario));
    }
  });
}
