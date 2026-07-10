// Consolidated remaining work handler runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import '../support/scenario_runner.dart';
import '../support/work_handlers/remaining_work_handlers_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'SimpleWorkOrderHandler counter_spy',
    remainingWorkHandlersScenarios().take(2),
    runRemainingWorkHandlersScenario,
  );
  runLabeledScenarioGroup(
    'SimpleWorkOrderHandler prospect',
    remainingWorkHandlersScenarios().skip(2).take(2),
    runRemainingWorkHandlersScenario,
  );
  runLabeledScenarioGroup(
    'applyStandardWorkOrder',
    remainingWorkHandlersScenarios().skip(4).take(1),
    runRemainingWorkHandlersScenario,
  );
  runLabeledScenarioGroup(
    'shouldSkipBuildFortForMissingTech',
    remainingWorkHandlersScenarios().skip(5).take(1),
    runRemainingWorkHandlersScenario,
  );
  runLabeledScenarioGroup(
    'StandardBuildWorkOrderHandler',
    remainingWorkHandlersScenarios().skip(6).take(1),
    runRemainingWorkHandlersScenario,
  );
  runLabeledScenarioGroup(
    'workOrderHandlersByTarget',
    remainingWorkHandlersScenarios().skip(7).take(1),
    runRemainingWorkHandlersScenario,
  );
  runLabeledScenarioGroup(
    'SimpleWorkOrderHandler',
    remainingWorkHandlersScenarios().skip(8),
    runRemainingWorkHandlersScenario,
  );
}
