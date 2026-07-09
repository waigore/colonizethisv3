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
  wppExpectJourneymanTrain(
    paper: 8,
    peasants: 2,
    treasury: 700,
    expectedPeasants: 1,
    expectedPaper: 3,
    expectedTreasury: 200,
    peasantsReason: 'one peasant consumed',
    journeymenReason: 'one journeyman added',
    stockReasons: {
      CommodityCatalog.paper.id: '5 paper deducted per SPEC § Recruiting cost table',
    },
    treasuryReason: '500 ducats deducted per SPEC § Recruiting cost table',
  );
}

void _acceptedMasterTrainConsumesPeasantPaperAndTreasury2692S9TierCoverageAc3MasterTail() {
  wppExpectMasterTrain(
    paper: 12,
    peasants: 1,
    treasury: 1200,
    expectedPeasants: 0,
    expectedPaper: 2,
    expectedTreasury: 200,
    peasantsReason: 'one peasant consumed',
    mastersReason: 'one master added',
    stockReasons: {
      CommodityCatalog.paper.id: '10 paper deducted per SPEC § Recruiting cost table',
    },
    treasuryReason: '1000 ducats deducted per SPEC § Recruiting cost table',
  );
}

void _masterRecruitWithRequiredTechLockedIsSilentlySkipped2692S9TechGateCoverage() {
  wppExpectMasterTrainSkipped(
    paper: 12,
    peasants: 1,
    treasury: 1200,
    techUnlocked: const {kTechIdMasterArtisans: true},
  );
}

void _laterRecruitOrderObservesTheRunningStateOfEarlierAcceptedOrderInTheSameSubmissionList2692S9OrderingSemantics() {
  wppExpectSequentialTiers(
    stock: {
      CommodityCatalog.fabric.id: 2,
      CommodityCatalog.paper.id: 2,
    },
    peasants: 0,
    treasury: 200,
    tiers: [WorkerTier.peasant, WorkerTier.apprentice],
    expectedPeasants: 0,
    expectedApprentices: 1,
    expectedStock: {
      CommodityCatalog.fabric.id: 0,
      CommodityCatalog.paper.id: 0,
    },
    expectedTreasury: 0,
    peasantsReason:
        'recruited peasant immediately consumed by the apprentice train',
    apprenticesReason: 'one apprentice added',
    stockReasons: {
      CommodityCatalog.fabric.id: 'peasant recruit consumed 2 fabric',
      CommodityCatalog.paper.id: 'apprentice train consumed 2 paper',
    },
    treasuryReason: 'apprentice train consumed 200 ducats',
  );
}

void _middleOrderSilentlySkipsWhenPeasantsAreExhaustedLaterOrdersStillResolveAgainstTheRunningState2692S9Ac4ResolverBehavior() {
  wppExpectSequentialTiers(
    stock: {
      CommodityCatalog.fabric.id: 4,
      CommodityCatalog.paper.id: 4,
    },
    peasants: 1,
    treasury: 400,
    tiers: [WorkerTier.apprentice, WorkerTier.apprentice, WorkerTier.peasant],
    expectedPeasants: 1,
    expectedApprentices: 1,
    expectedStock: {
      CommodityCatalog.paper.id: 2,
      CommodityCatalog.fabric.id: 2,
    },
    expectedTreasury: 200,
    peasantsReason:
        'apprentice consumed initial peasant; peasant recruit added 1',
    apprenticesReason: 'only the first apprentice train fired; second skipped',
    stockReasons: {
      CommodityCatalog.paper.id: 'one apprentice consumed 2 paper; second order did not',
      CommodityCatalog.fabric.id: 'trailing peasant recruit still consumed 2 fabric',
    },
    treasuryReason: 'only one apprentice train deducted treasury',
  );
}

void _perPlayerOrderListsApplyInIsolation2692S9MultiPlayerPin() {
  wppExpectMultiPlayerApprenticeIsolation();
}
