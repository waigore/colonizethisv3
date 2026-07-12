import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'buildQuickBattleInput',
    quickBattleBuildSiegeScenarios().take(2),
    (s) => s.run(),
  );

  runLabeledScenarioGroup(
    'siege virtual emplaced guns (COL-151)',
    quickBattleBuildSiegeScenarios().skip(2),
    (s) => s.run(),
  );
}
