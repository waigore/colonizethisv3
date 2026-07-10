// Consolidated WorkOrderCostCalculator runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import '../support/scenario_runner.dart';
import '../support/validators/work_order_cost_calculator_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'WorkOrderCostCalculator',
    workOrderCostCalculatorScenarios(),
    runWorkOrderCostCalculatorScenario,
  );
}
