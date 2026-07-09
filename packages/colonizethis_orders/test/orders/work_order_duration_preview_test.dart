// Consolidated work-order duration preview runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'support/scenario_runner.dart';
import 'support/application/work_order_duration_preview_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'previewTotalTurnsForPendingWorkOrder',
    workOrderDurationPreviewScenarios(),
    runWorkOrderDurationPreviewScenario,
  );
}
