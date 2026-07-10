// Consolidated explore work handler runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import '../support/scenario_runner.dart';
import '../support/work_handlers/explore_work_handler_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'exploreWorkOrderHandler',
    exploreWorkHandlerScenarios().take(1),
    runRunnableScenario,
  );
  runLabeledScenarioGroup(
    'tryApplyExploreWorkOrder',
    exploreWorkHandlerScenarios().skip(1),
    runRunnableScenario,
  );
}
