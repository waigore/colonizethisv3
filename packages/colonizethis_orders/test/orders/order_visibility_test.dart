// Consolidated order-visibility runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'support/application/order_visibility_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  runLabeledScenarioGroup(
    'provinceHasAtLeastVisibility',
    provinceHasAtLeastVisibilityScenarios(),
    runRunnableScenario,
  );
  runLabeledScenarioGroup(
    'tileHasAtLeastVisibility',
    tileHasAtLeastVisibilityScenarios(),
    runRunnableScenario,
  );
  runLabeledScenarioGroup(
    'moveSourceVisibilityOk',
    moveSourceVisibilityOkScenarios(),
    runRunnableScenario,
  );
  runLabeledScenarioGroup(
    'moveDestVisibilityOk',
    moveDestVisibilityOkScenarios(),
    runRunnableScenario,
  );
  runLabeledScenarioGroup(
    'workOrderVisibilityOk',
    workOrderVisibilityOkScenarios(),
    runRunnableScenario,
  );
}
