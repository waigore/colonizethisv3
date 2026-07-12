import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'combatLossProfileForStrengthRatio',
    combatLossProfileForStrengthRatioScenarios(),
    (s) => s.run(),
  );
  runLabeledScenarioGroup(
    'classifyCombatStrengthRatioBand (shared #3448 thresholds)',
    classifyCombatStrengthRatioBandScenarios(),
    (s) => s.run(),
  );
  runLabeledScenarioGroup(
    'combatCasualtyCount',
    combatCasualtyCountScenarios(),
    (s) => s.run(),
  );
}
