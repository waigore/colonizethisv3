// Consolidated appendMilitaryRegimentToArmy armiesById runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'package:colonizethis_test/test.dart';

import 'support/application/append_military_regiment_armies_by_id_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  suppressLogsForTests();

  runLabeledScenarioGroup(
    'appendMilitaryRegimentToArmy armiesById equivalence (Refs #2394)',
    appendMilitaryRegimentArmiesByIdScenarios(),
    runRunnableScenario,
  );
}
