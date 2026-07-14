import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'detectNavalConflicts',
    detectNavalConflictsScenarios(),
    (s) => s.run(),
  );

  runLabeledScenarioGroup(
    'normalizeNavalBattleSidesForAttacker',
    normalizeNavalBattleSidesScenarios(),
    (s) => s.run(),
  );

  runLabeledScenarioGroup(
    'navalStrength',
    navalStrengthScenarios(),
    (s) => s.run(),
  );
}
