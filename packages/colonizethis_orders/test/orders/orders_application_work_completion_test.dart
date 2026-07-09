// Consolidated applyBuildAndWorkOrders work-completion runners (Refs #3949 wave 3).
//
// Merges former work_completion_* + completed_work_dispatch suites into one
// ≤400-line family runner with scenarios in support/.

import 'package:colonizethis_test/test.dart';

import 'support/application/work_completion_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  group('applyBuildAndWorkOrders work completion', () {
    runLabeledScenarios(workCompletionScenarios(), runWorkCompletionScenario);
  });
}
