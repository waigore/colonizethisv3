// Consolidated order suggestion unit availability runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'package:colonizethis_test/test.dart';

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_unit_availability_scenarios.dart';

void main() {
  suppressLogsForTests();

  runLabeledScenarioGroup(
    'getAvailableWorkTargetsForUnit (Refs #2133)',
    getAvailableWorkTargetsForUnitScenarios(),
    runRunnableScenario,
  );
}
