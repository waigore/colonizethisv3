part of 'worker_pool_phase_expectations.dart';

void _acceptedRecruitPeasantOrderAdds1PeasantAndDeductsFabric() {
  wppExpectRecruitPeasantFromFabric();
}

void _recruitThatFailsAffordabilityChecksDoesNotMutateThePlayerNoPartialDeduction() {
  wppExpectApprenticeTrainSkippedWhenUnaffordable(
    paper: 5,
    peasants: 3,
    treasury: 100,
  );
}

void _acceptedApprenticeTrainConsumesPeasantPaperAndTreasury() {
  wppExpectApprenticeTrain(
    paper: 5,
    peasants: 3,
    treasury: 500,
    expectedPeasants: 2,
    expectedPaper: 3,
    expectedTreasury: 300,
  );
}

void _acceptedJourneymanTrainConsumesPeasantPaperAndTreasury2692S9TierCoverage() {
  wppExpectJourneymanTrain2692S9();
}

void _acceptedMasterTrainConsumesPeasantPaperAndTreasury2692S9TierCoverageAc3MasterTail() {
  wppExpectMasterTrain2692S9();
}

void _masterRecruitWithRequiredTechLockedIsSilentlySkipped2692S9TechGateCoverage() {
  wppExpectMasterTrainSkipped2692S9TechGate();
}

void _laterRecruitOrderObservesTheRunningStateOfEarlierAcceptedOrderInTheSameSubmissionList2692S9OrderingSemantics() {
  wppExpectSequentialPeasantThenApprentice2692S9();
}

void _middleOrderSilentlySkipsWhenPeasantsAreExhaustedLaterOrdersStillResolveAgainstTheRunningState2692S9Ac4ResolverBehavior() {
  wppExpectSequentialApprenticeSkipThenPeasant2692S9();
}

void _perPlayerOrderListsApplyInIsolation2692S9MultiPlayerPin() {
  wppExpectMultiPlayerApprenticeIsolation();
}
