// Table-driven feedstock-bootstrap waiver scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'work_order_cost_calculator_feedstock_bootstrap_expectations.dart';

/// One row in [workOrderCostCalculatorFeedstockBootstrapScenarios].
class WorkOrderCostCalculatorFeedstockBootstrapScenario
    implements LabeledScenario {
  const WorkOrderCostCalculatorFeedstockBootstrapScenario({
    required this.label,
    required this.target,
  });

  @override
  final String label;
  final WorkOrderCostCalculatorFeedstockBootstrapTarget target;
}

void runWorkOrderCostCalculatorFeedstockBootstrapScenario(
  WorkOrderCostCalculatorFeedstockBootstrapScenario scenario,
) {
  runWorkOrderCostCalculatorFeedstockBootstrapExpectation(scenario.target);
}

List<WorkOrderCostCalculatorFeedstockBootstrapScenario>
    workOrderCostCalculatorFeedstockBootstrapScenarios() => const [
          WorkOrderCostCalculatorFeedstockBootstrapScenario(
            label:
                'omits castIron for unimproved feedstock tile when gate active and '
                'stockpile has lumber only',
            target: WorkOrderCostCalculatorFeedstockBootstrapTarget
                .omitsCastIronLumberOnly,
          ),
          WorkOrderCostCalculatorFeedstockBootstrapScenario(
            label:
                'keeps full cost when castIron is already affordable (negative control)',
            target: WorkOrderCostCalculatorFeedstockBootstrapTarget
                .keepsFullCostWhenCastIronAffordable,
          ),
          WorkOrderCostCalculatorFeedstockBootstrapScenario(
            label:
                'keeps full cost on non-feedstock tile while gate active (negative control)',
            target: WorkOrderCostCalculatorFeedstockBootstrapTarget
                .keepsFullCostNonFeedstock,
          ),
          WorkOrderCostCalculatorFeedstockBootstrapScenario(
            label:
                'omits lumber and castIron for unimproved feedstock tile when gate active '
                'and stockpile has neither input (Refs #2847 lumber bootstrap)',
            target: WorkOrderCostCalculatorFeedstockBootstrapTarget
                .omitsLumberAndCastIronNeitherInput,
          ),
          WorkOrderCostCalculatorFeedstockBootstrapScenario(
            label:
                'does not waive lumber when castIron is already affordable (negative control)',
            target: WorkOrderCostCalculatorFeedstockBootstrapTarget
                .doesNotWaiveLumberWhenCastIronAffordable,
          ),
        ];
