// Compact applyBuildAndWorkOrders worker-pool phase assertions (Refs #3949 wave 3).

import 'worker_pool_phase_expectation_shorthand.dart';

/// Pins for [workerPoolPhaseScenarios] rows.
enum WorkerPoolPhaseTarget {
  acceptedRecruitPeasantOrderAdds1PeasantAndDeductsFabric,
  acceptedApprenticeTrainConsumesPeasantPaperAndTreasury,
  recruitThatFailsAffordabilityChecksDoesNotMutateThePlayerNoPartialDeduction,
  acceptedJourneymanTrainConsumesPeasantPaperAndTreasury2692S9TierCoverage,
  acceptedMasterTrainConsumesPeasantPaperAndTreasury2692S9TierCoverageAc3MasterTail,
  masterRecruitWithRequiredTechLockedIsSilentlySkipped2692S9TechGateCoverage,
  laterRecruitOrderObservesTheRunningStateOfEarlierAcceptedOrderInTheSameSubmissionList2692S9OrderingSemantics,
  middleOrderSilentlySkipsWhenPeasantsAreExhaustedLaterOrdersStillResolveAgainstTheRunningState2692S9Ac4ResolverBehavior,
  perPlayerOrderListsApplyInIsolation2692S9MultiPlayerPin,
}

void runWorkerPoolPhaseExpectation(WorkerPoolPhaseTarget target) {
  switch (target) {
    case WorkerPoolPhaseTarget
        .acceptedRecruitPeasantOrderAdds1PeasantAndDeductsFabric:
      wppExpectRecruitPeasantFromFabric();
    case WorkerPoolPhaseTarget
        .acceptedApprenticeTrainConsumesPeasantPaperAndTreasury:
      wppExpectApprenticeTrain(
        paper: 5,
        peasants: 3,
        treasury: 500,
        expectedPeasants: 2,
        expectedPaper: 3,
        expectedTreasury: 300,
      );
    case WorkerPoolPhaseTarget
        .recruitThatFailsAffordabilityChecksDoesNotMutateThePlayerNoPartialDeduction:
      wppExpectApprenticeTrainSkippedWhenUnaffordable(
        paper: 5,
        peasants: 3,
        treasury: 100,
      );
    case WorkerPoolPhaseTarget
        .acceptedJourneymanTrainConsumesPeasantPaperAndTreasury2692S9TierCoverage:
      wppExpectJourneymanTrain2692S9();
    case WorkerPoolPhaseTarget
        .acceptedMasterTrainConsumesPeasantPaperAndTreasury2692S9TierCoverageAc3MasterTail:
      wppExpectMasterTrain2692S9();
    case WorkerPoolPhaseTarget
        .masterRecruitWithRequiredTechLockedIsSilentlySkipped2692S9TechGateCoverage:
      wppExpectMasterTrainSkipped2692S9TechGate();
    case WorkerPoolPhaseTarget
        .laterRecruitOrderObservesTheRunningStateOfEarlierAcceptedOrderInTheSameSubmissionList2692S9OrderingSemantics:
      wppExpectSequentialPeasantThenApprentice2692S9();
    case WorkerPoolPhaseTarget
        .middleOrderSilentlySkipsWhenPeasantsAreExhaustedLaterOrdersStillResolveAgainstTheRunningState2692S9Ac4ResolverBehavior:
      wppExpectSequentialApprenticeSkipThenPeasant2692S9();
    case WorkerPoolPhaseTarget
        .perPlayerOrderListsApplyInIsolation2692S9MultiPlayerPin:
      wppExpectMultiPlayerApprenticeIsolation();
  }
}
