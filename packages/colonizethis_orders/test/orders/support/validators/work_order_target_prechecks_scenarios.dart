// Table-driven work-order target precheck scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'work_order_target_prechecks_expectations.dart';

/// One row in [workOrderTargetPrechecksScenarios].
class WorkOrderTargetPrecheckScenario implements RefsScenario {
  const WorkOrderTargetPrecheckScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final WorkOrderTargetPrecheckTarget target;
  @override
  final String? refs;
}

void runWorkOrderTargetPrecheckScenario(
  WorkOrderTargetPrecheckScenario scenario,
) {
  runWorkOrderTargetPrecheckExpectation(scenario.target);
}

/// Canonical scenarios for work-order target prechecks.
List<WorkOrderTargetPrecheckScenario> workOrderTargetPrechecksScenarios() =>
    const [
      WorkOrderTargetPrecheckScenario(
        label: 'registers expected work targets',
        target: WorkOrderTargetPrecheckTarget.registersExpectedTargets,
      ),
      WorkOrderTargetPrecheckScenario(
        label: 'runWorkOrderTargetPrecheck returns null for unregistered target',
        target: WorkOrderTargetPrecheckTarget.unregisteredTargetReturnsNull,
      ),
      WorkOrderTargetPrecheckScenario(
        label: 'precheckUpgradeTown rejects without National Bureaucracy',
        target: WorkOrderTargetPrecheckTarget.upgradeTownRejectsNoNationalBureaucracy,
      ),
      WorkOrderTargetPrecheckScenario(
        label: 'precheckUpgradeTown rejects when town development is already 4',
        target: WorkOrderTargetPrecheckTarget.upgradeTownRejectsMaxDevelopment,
      ),
      WorkOrderTargetPrecheckScenario(
        label: 'kWorkTargetsSkippingDefaultForeignProvinceCheck lists dedicated targets',
        target: WorkOrderTargetPrecheckTarget.skippingDefaultForeignCheckSet,
      ),
      WorkOrderTargetPrecheckScenario(
        label: 'precheckPurchaseLand matches with or without DiplomacyFactionMembership (Refs #2394)',
        target: WorkOrderTargetPrecheckTarget.purchaseLandFactionMembershipParity,
        refs: '#2394',
      ),
      WorkOrderTargetPrecheckScenario(
        label: 'precheckBuildImprovement rejects unprospected mineral tile',
        target: WorkOrderTargetPrecheckTarget.buildImprovementRejectsUnprospectedMineral,
      ),
      WorkOrderTargetPrecheckScenario(
        label: 'precheckDefaultForeignProvince rejects builder in foreign province',
        target: WorkOrderTargetPrecheckTarget.defaultForeignProvinceRejectsBuilder,
      ),
      WorkOrderTargetPrecheckScenario(
        label: 'precheckDevExclusiveTileConflict rejects duplicate dev work tile',
        target: WorkOrderTargetPrecheckTarget.devExclusiveTileConflict,
      ),
    ];
