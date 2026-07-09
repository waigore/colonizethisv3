part of 'worker_pool_phase_expectations.dart';

void _acceptedRecruitPeasantOrderAdds1PeasantAndDeductsFabric() {
  final p = wppAfter(
    wppPlayer(stockpile: wppStock({CommodityCatalog.fabric.id: 3})),
    [WorkerTier.peasant],
  );
  wppExpect(
    p,
    peasants: 1,
    stock: {CommodityCatalog.fabric.id: 1},
    treasury: 0,
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

void _recruitThatFailsAffordabilityChecksDoesNotMutateThePlayerNoPartialDeduction() {
  final p = wppAfter(
    wppPlayer(
      stockpile: wppStock({CommodityCatalog.paper.id: 5}),
      workerPool: const WorkerPool(peasants: 3),
      treasury: 100,
      techUnlocked: wppApprenticeTech,
    ),
    [WorkerTier.apprentice],
  );
  wppExpect(
    p,
    peasants: 3,
    apprentices: 0,
    stock: {CommodityCatalog.paper.id: 5},
    treasury: 100,
  );
}

void _acceptedJourneymanTrainConsumesPeasantPaperAndTreasury2692S9TierCoverage() {
  final p = wppAfter(
    wppPlayer(
      stockpile: wppStock({CommodityCatalog.paper.id: 8}),
      workerPool: const WorkerPool(peasants: 2),
      treasury: 700,
      techUnlocked: wppJourneymanTech,
    ),
    [WorkerTier.journeyman],
  );
  wppExpect(
    p,
    peasants: 1,
    journeymen: 1,
    stock: {CommodityCatalog.paper.id: 3},
    treasury: 200,
    peasantsReason: 'one peasant consumed',
    journeymenReason: 'one journeyman added',
    stockReasons: {
      CommodityCatalog.paper.id: '5 paper deducted per SPEC § Recruiting cost table',
    },
    treasuryReason: '500 ducats deducted per SPEC § Recruiting cost table',
  );
}

void _acceptedMasterTrainConsumesPeasantPaperAndTreasury2692S9TierCoverageAc3MasterTail() {
  final p = wppAfter(
    wppPlayer(
      stockpile: wppStock({CommodityCatalog.paper.id: 12}),
      workerPool: const WorkerPool(peasants: 1),
      treasury: 1200,
      techUnlocked: wppMasterTech,
    ),
    [WorkerTier.master],
  );
  wppExpect(
    p,
    peasants: 0,
    masters: 1,
    stock: {CommodityCatalog.paper.id: 2},
    treasury: 200,
    peasantsReason: 'one peasant consumed',
    mastersReason: 'one master added',
    stockReasons: {
      CommodityCatalog.paper.id: '10 paper deducted per SPEC § Recruiting cost table',
    },
    treasuryReason: '1000 ducats deducted per SPEC § Recruiting cost table',
  );
}

void _masterRecruitWithRequiredTechLockedIsSilentlySkipped2692S9TechGateCoverage() {
  final p = wppAfter(
    wppPlayer(
      stockpile: wppStock({CommodityCatalog.paper.id: 12}),
      workerPool: const WorkerPool(peasants: 1),
      treasury: 1200,
      techUnlocked: const {kTechIdMasterArtisans: true},
    ),
    [WorkerTier.master],
  );
  wppExpect(
    p,
    peasants: 1,
    masters: 0,
    stock: {CommodityCatalog.paper.id: 12},
    treasury: 1200,
    peasantsReason: 'peasant not consumed',
    mastersReason: 'master not added',
    stockReasons: {CommodityCatalog.paper.id: 'no paper deducted'},
    treasuryReason: 'no treasury deducted',
  );
}

void _laterRecruitOrderObservesTheRunningStateOfEarlierAcceptedOrderInTheSameSubmissionList2692S9OrderingSemantics() {
  final p = wppAfter(
    wppPlayer(
      stockpile: wppStock({
        CommodityCatalog.fabric.id: 2,
        CommodityCatalog.paper.id: 2,
      }),
      treasury: 200,
      techUnlocked: wppApprenticeTech,
    ),
    [WorkerTier.peasant, WorkerTier.apprentice],
  );
  wppExpect(
    p,
    peasants: 0,
    apprentices: 1,
    stock: {CommodityCatalog.fabric.id: 0, CommodityCatalog.paper.id: 0},
    treasury: 0,
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
  final p = wppAfter(
    wppPlayer(
      stockpile: wppStock({
        CommodityCatalog.fabric.id: 4,
        CommodityCatalog.paper.id: 4,
      }),
      workerPool: const WorkerPool(peasants: 1),
      treasury: 400,
      techUnlocked: wppApprenticeTech,
    ),
    [WorkerTier.apprentice, WorkerTier.apprentice, WorkerTier.peasant],
  );
  wppExpect(
    p,
    peasants: 1,
    apprentices: 1,
    stock: {CommodityCatalog.paper.id: 2, CommodityCatalog.fabric.id: 2},
    treasury: 200,
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
  final apprenticePlayer = wppPlayer(
    stockpile: wppStock({CommodityCatalog.paper.id: 4}),
    workerPool: const WorkerPool(peasants: 2),
    treasury: 300,
    techUnlocked: wppApprenticeTech,
  );
  final game = wppEmptyWorldGame(
    players: [
      apprenticePlayer,
      wppPlayer(
        id: WppIds.player2,
        displayName: 'B',
        isHuman: false,
        stockpile: wppStock({CommodityCatalog.paper.id: 4}),
        workerPool: const WorkerPool(peasants: 2),
        treasury: 300,
        techUnlocked: wppApprenticeTech,
      ),
    ],
  );
  final orders = Orders(
    recruitWorkerOrdersByPlayerId: {
      WppIds.player1: const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
      WppIds.player2: const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
    },
  );
  final result = wppApply(game, orders);
  for (final playerId in [WppIds.player1, WppIds.player2]) {
    final p = result.players.firstWhere((p) => p.id == playerId);
    wppExpect(
      p,
      peasants: 1,
      apprentices: 1,
      stock: {CommodityCatalog.paper.id: 2},
      treasury: 100,
    );
  }
}
