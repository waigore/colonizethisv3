// Consolidated explorer consulate precheck runner (Refs #3949 wave 3 slice 96).

import '../support/scenario_runner.dart';
import '../support/validators/work_order_target_prechecks_explorer_consulate_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'workOrderTargetPrechecks explorer consulate',
    workOrderTargetPrechecksExplorerConsulateScenarios(),
    runRunnableScenario,
  );
}
