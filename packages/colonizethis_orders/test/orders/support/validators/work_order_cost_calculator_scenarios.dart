// Table-driven WorkOrderCostCalculator scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'work_order_cost_calculator_expectations.dart';

/// One row in [workOrderCostCalculatorScenarios].
class WorkOrderCostCalculatorScenario implements LabeledScenario {
  const WorkOrderCostCalculatorScenario({
    required this.label,
    required this.target,
  });

  @override
  final String label;
  final WorkOrderCostCalculatorTarget target;
}

void runWorkOrderCostCalculatorScenario(
  WorkOrderCostCalculatorScenario scenario,
) {
  runWorkOrderCostCalculatorExpectation(scenario.target);
}

/// Canonical scenarios for WorkOrderCostCalculator.
List<WorkOrderCostCalculatorScenario> workOrderCostCalculatorScenarios() =>
    const [
      WorkOrderCostCalculatorScenario(
        label: 'calculateCost returns null for counter_spy, purchase_land',
        target: WorkOrderCostCalculatorTarget.nullCostForCounterSpyAndPurchaseLand,
      ),
      WorkOrderCostCalculatorScenario(
        label: 'calculateCost returns cost map for build_improvement',
        target: WorkOrderCostCalculatorTarget.buildImprovementCostMap,
      ),
      WorkOrderCostCalculatorScenario(
        label: 'calculateCost for build_fort uses province fortLevel when not overridden',
        target: WorkOrderCostCalculatorTarget.buildFortUsesProvinceFortLevel,
      ),
    ];
