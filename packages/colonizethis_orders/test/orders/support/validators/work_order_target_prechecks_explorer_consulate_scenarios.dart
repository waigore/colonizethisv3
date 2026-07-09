// Table-driven explorer consulate precheck scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'work_order_target_prechecks_explorer_consulate_expectations.dart';

class WorkOrderTargetPrechecksExplorerConsulateScenario
    implements LabeledScenario {
  const WorkOrderTargetPrechecksExplorerConsulateScenario({
    required this.label,
    required this.target,
  });

  @override
  final String label;
  final WorkOrderTargetPrechecksExplorerConsulateTarget target;
}

void runWorkOrderTargetPrechecksExplorerConsulateScenario(
  WorkOrderTargetPrechecksExplorerConsulateScenario scenario,
) {
  runWorkOrderTargetPrechecksExplorerConsulateExpectation(scenario.target);
}

List<WorkOrderTargetPrechecksExplorerConsulateScenario>
    workOrderTargetPrechecksExplorerConsulateScenarios() => const [
          WorkOrderTargetPrechecksExplorerConsulateScenario(
            label: 'precheckExplorerConsulateInMinorTribe rejects explore without Consulate',
            target: WorkOrderTargetPrechecksExplorerConsulateTarget
                .rejectsExploreWithoutConsulate,
          ),
        ];
