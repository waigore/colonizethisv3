import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'resolveSeaBattle',
    resolveSeaBattleScenarios(),
    (s) => s.run(),
  );

  runLabeledScenarioGroup(
    'applyNavalBattleResults',
    applyNavalBattleResultsScenarios(),
    (s) => s.run(),
  );

  runLabeledScenarioGroup(
    'navalInterceptProbability',
    navalInterceptProbabilityScenarios(),
    (s) => s.run(),
  );
}
