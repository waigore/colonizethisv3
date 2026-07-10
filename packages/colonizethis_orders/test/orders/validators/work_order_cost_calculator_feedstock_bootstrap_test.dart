// Consolidated feedstock-bootstrap waiver runner (Refs #3949 wave 3 slice 95).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import '../support/scenario_runner.dart';
import '../support/validators/work_order_cost_calculator_feedstock_bootstrap_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'WorkOrderCostCalculator feedstock bootstrap castIron waiver',
    workOrderCostCalculatorFeedstockBootstrapScenarios(),
    runWorkOrderCostCalculatorFeedstockBootstrapScenario,
  );
}
