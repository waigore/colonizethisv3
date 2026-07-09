// Consolidated OrderEngine move/work-context runner (Refs #3949 wave 3).
//
// Merges former order_engine_move_and_work_context_part{1,2,3}_test.dart into
// one ≤400-line family runner with scenarios in support/.

import 'support/engine/order_engine_move_and_work_context_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  runLabeledScenarioGroup(
    'OrderEngine',
    orderEngineMoveAndWorkContextScenarios(),
    runOrderEngineMoveAndWorkContextScenario,
  );
}
