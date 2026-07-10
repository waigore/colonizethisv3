// Consolidated applyBuildAndWorkOrders build-unit / training runners (Refs #3949 wave 3).
//
// Merges former military_ship_skip + military/civilian_training_costs suites into
// one ≤400-line family runner with scenarios in support/.

import 'package:colonizethis_test/test.dart';

import 'support/application/build_unit_training_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  group('applyBuildAndWorkOrders build-unit training', () {
    runLabeledScenarios(buildUnitTrainingScenarios(), runRunnableScenario);
  });
}
