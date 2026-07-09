// Compact applyBuildAndWorkOrders worker-pool phase assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'worker_pool_phase_fixtures.dart';

/// Pins for [workerPoolPhaseScenarios] rows.
part 'worker_pool_phase_expectations_part1.dart';

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
      _acceptedRecruitPeasantOrderAdds1PeasantAndDeductsFabric();
    case WorkerPoolPhaseTarget
        .acceptedApprenticeTrainConsumesPeasantPaperAndTreasury:
      _acceptedApprenticeTrainConsumesPeasantPaperAndTreasury();
    case WorkerPoolPhaseTarget
        .recruitThatFailsAffordabilityChecksDoesNotMutateThePlayerNoPartialDeduction:
      _recruitThatFailsAffordabilityChecksDoesNotMutateThePlayerNoPartialDeduction();
    case WorkerPoolPhaseTarget
        .acceptedJourneymanTrainConsumesPeasantPaperAndTreasury2692S9TierCoverage:
      _acceptedJourneymanTrainConsumesPeasantPaperAndTreasury2692S9TierCoverage();
    case WorkerPoolPhaseTarget
        .acceptedMasterTrainConsumesPeasantPaperAndTreasury2692S9TierCoverageAc3MasterTail:
      _acceptedMasterTrainConsumesPeasantPaperAndTreasury2692S9TierCoverageAc3MasterTail();
    case WorkerPoolPhaseTarget
        .masterRecruitWithRequiredTechLockedIsSilentlySkipped2692S9TechGateCoverage:
      _masterRecruitWithRequiredTechLockedIsSilentlySkipped2692S9TechGateCoverage();
    case WorkerPoolPhaseTarget
        .laterRecruitOrderObservesTheRunningStateOfEarlierAcceptedOrderInTheSameSubmissionList2692S9OrderingSemantics:
      _laterRecruitOrderObservesTheRunningStateOfEarlierAcceptedOrderInTheSameSubmissionList2692S9OrderingSemantics();
    case WorkerPoolPhaseTarget
        .middleOrderSilentlySkipsWhenPeasantsAreExhaustedLaterOrdersStillResolveAgainstTheRunningState2692S9Ac4ResolverBehavior:
      _middleOrderSilentlySkipsWhenPeasantsAreExhaustedLaterOrdersStillResolveAgainstTheRunningState2692S9Ac4ResolverBehavior();
    case WorkerPoolPhaseTarget
        .perPlayerOrderListsApplyInIsolation2692S9MultiPlayerPin:
      _perPlayerOrderListsApplyInIsolation2692S9MultiPlayerPin();
  }
}


