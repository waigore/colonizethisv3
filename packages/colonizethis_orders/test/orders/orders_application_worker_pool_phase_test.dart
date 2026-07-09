// Consolidated applyBuildAndWorkOrders worker-pool phase runners (Refs #3949 wave 3).
//
// Merges former worker_pool_phase + worker_pool_phase_s9 suites into one
// ≤400-line family runner with scenarios in support/.

import 'package:colonizethis_test/test.dart';

import 'support/application/worker_pool_phase_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  group('applyBuildAndWorkOrders worker pool sub-phase', () {
    runLabeledScenarios(
      workerPoolPhaseScenarios(),
      runWorkerPoolPhaseScenario,
    );
  });
}
