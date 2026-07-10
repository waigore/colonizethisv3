// Consolidated OrderEngine civilian move XOR work runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'support/engine/order_engine_civilian_move_xor_work_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  runLabeledScenarioGroup(
    'civilian MoveOrder xor WorkOrder',
    orderEngineCivilianMoveXorWorkScenarios(),
    runRunnableScenario,
  );
}
