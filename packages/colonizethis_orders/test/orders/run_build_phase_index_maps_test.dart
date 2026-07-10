// Consolidated runBuildPhase O(1) index-map runner (Refs #3949 wave 3 slice 95).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'package:colonizethis_test/test.dart';

import 'support/application/run_build_phase_index_maps_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  suppressLogsForTests();

  runLabeledScenarioGroup(
    'runBuildPhase O(1) maps end-to-end (Refs #2394)',
    runBuildPhaseIndexMapsScenarios(),
    runRunnableScenario,
  );
}
