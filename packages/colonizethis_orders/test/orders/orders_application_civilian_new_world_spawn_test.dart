// Consolidated civilian / New World spawn runners (Refs #3949 wave 3).

import 'package:colonizethis_test/test.dart';

import 'support/application/civilian_spawn_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  group('applyBuildAndWorkOrders civilian and New World spawn', () {
    runLabeledScenarios(civilianSpawnScenarios(), runRunnableScenario);
  });
}
