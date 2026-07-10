// Consolidated work-order target precheck runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import '../support/scenario_runner.dart';
import '../support/validators/work_order_target_prechecks_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'workOrderTargetPrechecks',
    workOrderTargetPrechecksScenarios(),
    runRunnableScenario,
  );
}
