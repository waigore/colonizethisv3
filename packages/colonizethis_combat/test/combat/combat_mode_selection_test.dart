import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'isCapitalSiege',
    isCapitalSiegeScenarios(),
    (s) => s.run(),
  );

  runLabeledScenarioGroup(
    'resolveCombatModeForBattle',
    resolveCombatModeForBattleScenarios(),
    (s) => s.run(),
  );
}
