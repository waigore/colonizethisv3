// Table-driven WorkOrderCostCalculator scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'work_order_cost_calculator_run_rows.dart';

/// One row in [workOrderCostCalculatorScenarios].
class WorkOrderCostCalculatorScenario implements LabeledScenario {
  const WorkOrderCostCalculatorScenario({
    required this.label,
    required this.run,
  });

  @override
  final String label;
  final void Function() run;
}

void runWorkOrderCostCalculatorScenario(
  WorkOrderCostCalculatorScenario scenario,
) =>
    scenario.run();

/// Canonical scenarios for WorkOrderCostCalculator.
List<WorkOrderCostCalculatorScenario> workOrderCostCalculatorScenarios() =>
    const [
      WorkOrderCostCalculatorScenario(
        label: 'calculateCost returns null for counter_spy, purchase_land',
        run: woccRunNullCostForCounterSpyAndPurchaseLand,
      ),
      WorkOrderCostCalculatorScenario(
        label: 'calculateCost returns cost map for build_improvement',
        run: woccRunBuildImprovementCostMap,
      ),
      WorkOrderCostCalculatorScenario(
        label: 'calculateCost for build_fort uses province fortLevel when not overridden',
        run: woccRunBuildFortUsesProvinceFortLevel,
      ),
    ];
