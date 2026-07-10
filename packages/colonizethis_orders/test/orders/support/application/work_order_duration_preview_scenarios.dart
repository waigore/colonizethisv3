// Table-driven work-order duration preview scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'work_order_duration_preview_run_rows.dart';

/// One row in [workOrderDurationPreviewScenarios].
class WorkOrderDurationPreviewScenario implements RefsScenario {
  const WorkOrderDurationPreviewScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runWorkOrderDurationPreviewScenario(
  WorkOrderDurationPreviewScenario scenario,
) {
  scenario.run();
}

/// Canonical scenarios for work_order_duration_preview family tests.
List<WorkOrderDurationPreviewScenario> workOrderDurationPreviewScenarios() =>
    const [
      WorkOrderDurationPreviewScenario(
        label: 'returns scaled explore turns from province size',
        run: wodpRunScaledExploreTurnsFromProvinceSize,
      ),
      WorkOrderDurationPreviewScenario(
        label: 'returns fort-level scaled turns for build_fort',
        run: wodpRunFortLevelScaledTurnsForBuildFort,
      ),
      WorkOrderDurationPreviewScenario(
        label: 'returns one turn for counter_spy',
        run: wodpRunOneTurnForCounterSpy,
      ),
      WorkOrderDurationPreviewScenario(
        label: 'returns improvement-level scaled turns for build_improvement',
        run: wodpRunImprovementLevelScaledTurnsForBuildImprovement,
      ),
      WorkOrderDurationPreviewScenario(
        label: 'returns minimum one turn for prospect and purchase_land',
        run: wodpRunMinimumOneTurnForProspectAndPurchaseLand,
      ),
    ];
