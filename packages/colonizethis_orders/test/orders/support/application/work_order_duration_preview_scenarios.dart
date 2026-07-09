// Table-driven work-order duration preview scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'work_order_duration_preview_expectations.dart';

/// One row in [workOrderDurationPreviewScenarios].
class WorkOrderDurationPreviewScenario implements RefsScenario {
  const WorkOrderDurationPreviewScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final WorkOrderDurationPreviewTarget target;
  @override
  final String? refs;
}

void runWorkOrderDurationPreviewScenario(
  WorkOrderDurationPreviewScenario scenario,
) {
  runWorkOrderDurationPreviewExpectation(scenario.target);
}

/// Canonical scenarios for work_order_duration_preview family tests.
List<WorkOrderDurationPreviewScenario> workOrderDurationPreviewScenarios() =>
    const [
      WorkOrderDurationPreviewScenario(
        label: 'returns scaled explore turns from province size',
        target: WorkOrderDurationPreviewTarget.scaledExploreTurnsFromProvinceSize,
      ),
      WorkOrderDurationPreviewScenario(
        label: 'returns fort-level scaled turns for build_fort',
        target: WorkOrderDurationPreviewTarget.fortLevelScaledTurnsForBuildFort,
      ),
      WorkOrderDurationPreviewScenario(
        label: 'returns one turn for counter_spy',
        target: WorkOrderDurationPreviewTarget.oneTurnForCounterSpy,
      ),
      WorkOrderDurationPreviewScenario(
        label: 'returns improvement-level scaled turns for build_improvement',
        target: WorkOrderDurationPreviewTarget
            .improvementLevelScaledTurnsForBuildImprovement,
      ),
      WorkOrderDurationPreviewScenario(
        label: 'returns minimum one turn for prospect and purchase_land',
        target:
            WorkOrderDurationPreviewTarget.minimumOneTurnForProspectAndPurchaseLand,
      ),
    ];
