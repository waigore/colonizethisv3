// Table-driven feedstock-bootstrap waiver scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'work_order_cost_calculator_feedstock_bootstrap_run_rows.dart';

/// One row in [workOrderCostCalculatorFeedstockBootstrapScenarios].
class WorkOrderCostCalculatorFeedstockBootstrapScenario
    implements LabeledScenario {
  const WorkOrderCostCalculatorFeedstockBootstrapScenario({
    required this.label,
    required this.run,
  });

  @override
  final String label;
  final void Function() run;
}

void runWorkOrderCostCalculatorFeedstockBootstrapScenario(
  WorkOrderCostCalculatorFeedstockBootstrapScenario scenario,
) =>
    scenario.run();

List<WorkOrderCostCalculatorFeedstockBootstrapScenario>
    workOrderCostCalculatorFeedstockBootstrapScenarios() => const [
          WorkOrderCostCalculatorFeedstockBootstrapScenario(
            label:
                'omits castIron for unimproved feedstock tile when gate active and '
                'stockpile has lumber only',
            run: woccfbRunOmitsCastIronLumberOnly,
          ),
          WorkOrderCostCalculatorFeedstockBootstrapScenario(
            label:
                'keeps full cost when castIron is already affordable (negative control)',
            run: woccfbRunKeepsFullCostWhenCastIronAffordable,
          ),
          WorkOrderCostCalculatorFeedstockBootstrapScenario(
            label:
                'keeps full cost on non-feedstock tile while gate active (negative control)',
            run: woccfbRunKeepsFullCostNonFeedstock,
          ),
          WorkOrderCostCalculatorFeedstockBootstrapScenario(
            label:
                'omits lumber and castIron for unimproved feedstock tile when gate active '
                'and stockpile has neither input (Refs #2847 lumber bootstrap)',
            run: woccfbRunOmitsLumberAndCastIronNeitherInput,
          ),
          WorkOrderCostCalculatorFeedstockBootstrapScenario(
            label:
                'does not waive lumber when castIron is already affordable (negative control)',
            run: woccfbRunDoesNotWaiveLumberWhenCastIronAffordable,
          ),
        ];
