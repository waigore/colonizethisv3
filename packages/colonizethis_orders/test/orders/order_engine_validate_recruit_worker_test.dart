// Consolidated OrderEngine validateRecruitWorker runners (Refs #3949 wave 3).

import 'package:colonizethis_test/test.dart';

import 'support/engine/order_engine_validate_recruit_worker_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  group('OrderEngine validation pass — RecruitWorkerOrder (#2692 S4)', () {
    runLabeledScenarios(
      orderEngineValidateRecruitWorkerScenarios(),
      runOrderEngineValidateRecruitWorkerScenario,
    );
  });
}
