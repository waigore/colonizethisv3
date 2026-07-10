// Table-driven explorer consulate precheck scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'work_order_target_prechecks_explorer_consulate_run_rows.dart';

class WorkOrderTargetPrechecksExplorerConsulateScenario
    implements LabeledScenario {
  const WorkOrderTargetPrechecksExplorerConsulateScenario({
    required this.label,
    required this.run,
  });

  @override
  final String label;
  final void Function() run;
}

void runWorkOrderTargetPrechecksExplorerConsulateScenario(
  WorkOrderTargetPrechecksExplorerConsulateScenario scenario,
) =>
    scenario.run();

List<WorkOrderTargetPrechecksExplorerConsulateScenario>
    workOrderTargetPrechecksExplorerConsulateScenarios() => const [
          WorkOrderTargetPrechecksExplorerConsulateScenario(
            label: 'precheckExplorerConsulateInMinorTribe rejects explore without Consulate',
            run: wotpecRunRejectsExploreWithoutConsulate,
          ),
        ];
