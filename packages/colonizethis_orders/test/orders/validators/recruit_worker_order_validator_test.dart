// Consolidated RecruitWorkerOrderValidator runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import '../support/scenario_runner.dart';
import '../support/validators/recruit_worker_order_validator_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'RecruitWorkerOrderValidator (#2692 S4)',
    recruitWorkerOrderValidatorScenarios(),
    runRecruitWorkerOrderValidatorScenario,
  );
}
