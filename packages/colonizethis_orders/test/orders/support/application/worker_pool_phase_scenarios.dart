// Table-driven applyBuildAndWorkOrders worker-pool phase scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'worker_pool_phase_run_rows.dart';

/// One row in [workerPoolPhaseScenarios].
class WorkerPoolPhaseScenario implements RefsScenario {
  const WorkerPoolPhaseScenario({
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

void runWorkerPoolPhaseScenario(WorkerPoolPhaseScenario scenario) {
  scenario.run();
}

/// Canonical scenarios for worker-pool S4 + S9 family tests.
/// Labels match former suite descriptions (joined to single-line `label:` for CI).
List<WorkerPoolPhaseScenario> workerPoolPhaseScenarios() => const [
  // dart format off
  WorkerPoolPhaseScenario(
    label: 'accepted recruit peasant order adds 1 peasant and deducts fabric',
    run: wppRunAcceptedRecruitPeasantOrderAdds1PeasantAndDeductsFabric,
    refs: '#2692',
  ),
  WorkerPoolPhaseScenario(
    label: 'accepted apprentice train consumes peasant, paper, and treasury',
    run: wppRunAcceptedApprenticeTrainConsumesPeasantPaperAndTreasury,
    refs: '#2692',
  ),
  WorkerPoolPhaseScenario(
    label: 'recruit that fails affordability checks does not mutate the player (no partial deduction)',
    run: wppRunRecruitThatFailsAffordabilityChecksDoesNotMutateThePlayerNoPartialDeduction,
    refs: '#2692',
  ),
  WorkerPoolPhaseScenario(
    label: 'accepted journeyman train consumes peasant, paper, and treasury (#2692 S9 tier coverage)',
    run: wppRunAcceptedJourneymanTrainConsumesPeasantPaperAndTreasury2692S9TierCoverage,
    refs: '#2692',
  ),
  WorkerPoolPhaseScenario(
    label: 'accepted master train consumes peasant, paper, and treasury (#2692 S9 tier coverage; AC #3 master tail)',
    run: wppRunAcceptedMasterTrainConsumesPeasantPaperAndTreasury2692S9TierCoverageAc3MasterTail,
    refs: '#2692',
  ),
  WorkerPoolPhaseScenario(
    label: 'master recruit with required tech locked is silently skipped (#2692 S9 tech-gate coverage)',
    run: wppRunMasterRecruitWithRequiredTechLockedIsSilentlySkipped2692S9TechGateCoverage,
    refs: '#2692',
  ),
  WorkerPoolPhaseScenario(
    label: 'later recruit order observes the running state of earlier accepted order in the same submission list (#2692 S9 ordering semantics)',
    run: wppRunLaterRecruitOrderObservesTheRunningStateOfEarlierAcceptedOrderInTheSameSubmissionList2692S9OrderingSemantics,
    refs: '#2692',
  ),
  WorkerPoolPhaseScenario(
    label: 'middle order silently skips when peasants are exhausted; later orders still resolve against the running state (#2692 S9; AC #4 resolver behavior)',
    run: wppRunMiddleOrderSilentlySkipsWhenPeasantsAreExhaustedLaterOrdersStillResolveAgainstTheRunningState2692S9Ac4ResolverBehavior,
    refs: '#2692',
  ),
  WorkerPoolPhaseScenario(
    label: 'per-player order lists apply in isolation (#2692 S9 multi-player pin)',
    run: wppRunPerPlayerOrderListsApplyInIsolation2692S9MultiPlayerPin,
    refs: '#2692',
  ),
  // dart format on
];
