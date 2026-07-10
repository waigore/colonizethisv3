// Consolidated OrderEngine naval/build validation runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'support/engine/order_engine_naval_build_validation_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  runLabeledScenarioGroup(
    'OrderEngine',
    orderEngineNavalBuildValidationScenarios(),
    runRunnableScenario,
  );
}
