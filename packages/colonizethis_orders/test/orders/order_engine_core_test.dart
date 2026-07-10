// Consolidated OrderEngine core runner (Refs #3949 wave 3).
//
// Merges former order_engine_core_part{1,2}_test.dart into one ≤400-line
// family runner with scenarios in support/.

import 'support/engine/order_engine_core_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  runLabeledScenarioGroup(
    'OrderEngine',
    orderEngineCoreScenarios(),
    runRunnableScenario,
  );
}
