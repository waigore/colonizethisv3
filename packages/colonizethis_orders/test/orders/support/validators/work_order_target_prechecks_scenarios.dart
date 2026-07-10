// Table-driven work-order target precheck scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'work_order_target_prechecks_run_rows.dart';

/// One row in [workOrderTargetPrechecksScenarios].
class WorkOrderTargetPrecheckScenario implements RefsScenario {
  const WorkOrderTargetPrecheckScenario({
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

void runWorkOrderTargetPrecheckScenario(
  WorkOrderTargetPrecheckScenario scenario,
) =>
    scenario.run();

/// Canonical scenarios for work-order target prechecks.
List<WorkOrderTargetPrecheckScenario> workOrderTargetPrechecksScenarios() =>
    const [
      WorkOrderTargetPrecheckScenario(
        label: 'registers expected work targets',
        run: wotpRunRegistersExpectedTargets,
      ),
      WorkOrderTargetPrecheckScenario(
        label: 'runWorkOrderTargetPrecheck returns null for unregistered target',
        run: wotpRunUnregisteredTargetReturnsNull,
      ),
      WorkOrderTargetPrecheckScenario(
        label: 'precheckUpgradeTown rejects without National Bureaucracy',
        run: wotpRunUpgradeTownRejectsNoNationalBureaucracy,
      ),
      WorkOrderTargetPrecheckScenario(
        label: 'precheckUpgradeTown rejects when town development is already 4',
        run: wotpRunUpgradeTownRejectsMaxDevelopment,
      ),
      WorkOrderTargetPrecheckScenario(
        label: 'kWorkTargetsSkippingDefaultForeignProvinceCheck lists dedicated targets',
        run: wotpRunSkippingDefaultForeignCheckSet,
      ),
      WorkOrderTargetPrecheckScenario(
        label: 'precheckPurchaseLand matches with or without DiplomacyFactionMembership (Refs #2394)',
        run: wotpRunPurchaseLandFactionMembershipParity,
        refs: '#2394',
      ),
      WorkOrderTargetPrecheckScenario(
        label: 'precheckBuildImprovement rejects unprospected mineral tile',
        run: wotpRunBuildImprovementRejectsUnprospectedMineral,
      ),
      WorkOrderTargetPrecheckScenario(
        label: 'precheckDefaultForeignProvince rejects builder in foreign province',
        run: wotpRunDefaultForeignProvinceRejectsBuilder,
      ),
      WorkOrderTargetPrecheckScenario(
        label: 'precheckDevExclusiveTileConflict rejects duplicate dev work tile',
        run: wotpRunDevExclusiveTileConflict,
      ),
    ];
