part of 'worker_pool_phase_expectations.dart';

void _acceptedRecruitPeasantOrderAdds1PeasantAndDeductsFabric() {
  final game = wppEmptyWorldGame(
    players: [
      wppPlayer(
        stockpile: Stockpile(quantities: {CommodityCatalog.fabric.id: 3}),
      ),
    ],
  );
  final p = wppPlayerAfter(
    game,
    wppRecruitOrders(WppIds.player1, [WorkerTier.peasant]),
    WppIds.player1,
  );
  expect(p.workerPool.peasants, 1);
  expect(p.stockpile.quantityOf(CommodityCatalog.fabric.id), 1);
  expect(p.treasury, 0);
}

void _acceptedApprenticeTrainConsumesPeasantPaperAndTreasury() {
  final game = wppEmptyWorldGame(
    players: [
      wppPlayer(
        stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 5}),
        workerPool: const WorkerPool(peasants: 3),
        treasury: 500,
        techUnlocked: wppApprenticeTech,
      ),
    ],
  );
  final p = wppPlayerAfter(
    game,
    wppRecruitOrders(WppIds.player1, [WorkerTier.apprentice]),
    WppIds.player1,
  );
  expect(p.workerPool.peasants, 2);
  expect(p.workerPool.apprentices, 1);
  expect(p.stockpile.quantityOf(CommodityCatalog.paper.id), 3);
  expect(p.treasury, 300);
}

void _recruitThatFailsAffordabilityChecksDoesNotMutateThePlayerNoPartialDeduction() {
  final game = wppEmptyWorldGame(
    players: [
      wppPlayer(
        stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 5}),
        workerPool: const WorkerPool(peasants: 3),
        treasury: 100,
        techUnlocked: wppApprenticeTech,
      ),
    ],
  );
  final p = wppPlayerAfter(
    game,
    wppRecruitOrders(WppIds.player1, [WorkerTier.apprentice]),
    WppIds.player1,
  );
  expect(p.workerPool.peasants, 3);
  expect(p.workerPool.apprentices, 0);
  expect(p.stockpile.quantityOf(CommodityCatalog.paper.id), 5);
  expect(p.treasury, 100);
}

void _acceptedJourneymanTrainConsumesPeasantPaperAndTreasury2692S9TierCoverage() {
  final game = wppEmptyWorldGame(
    players: [
      wppPlayer(
        stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 8}),
        workerPool: const WorkerPool(peasants: 2),
        treasury: 700,
        techUnlocked: wppJourneymanTech,
      ),
    ],
  );
  final p = wppPlayerAfter(
    game,
    wppRecruitOrders(WppIds.player1, [WorkerTier.journeyman]),
    WppIds.player1,
  );
  expect(p.workerPool.peasants, 1, reason: 'one peasant consumed');
  expect(p.workerPool.journeymen, 1, reason: 'one journeyman added');
  expect(
    p.stockpile.quantityOf(CommodityCatalog.paper.id),
    3,
    reason: '5 paper deducted per SPEC § Recruiting cost table',
  );
  expect(
    p.treasury,
    200,
    reason: '500 ducats deducted per SPEC § Recruiting cost table',
  );
}

void _acceptedMasterTrainConsumesPeasantPaperAndTreasury2692S9TierCoverageAc3MasterTail() {
  final game = wppEmptyWorldGame(
    players: [
      wppPlayer(
        stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 12}),
        workerPool: const WorkerPool(peasants: 1),
        treasury: 1200,
        techUnlocked: wppMasterTech,
      ),
    ],
  );
  final p = wppPlayerAfter(
    game,
    wppRecruitOrders(WppIds.player1, [WorkerTier.master]),
    WppIds.player1,
  );
  expect(p.workerPool.peasants, 0, reason: 'one peasant consumed');
  expect(p.workerPool.masters, 1, reason: 'one master added');
  expect(
    p.stockpile.quantityOf(CommodityCatalog.paper.id),
    2,
    reason: '10 paper deducted per SPEC § Recruiting cost table',
  );
  expect(
    p.treasury,
    200,
    reason: '1000 ducats deducted per SPEC § Recruiting cost table',
  );
}

void _masterRecruitWithRequiredTechLockedIsSilentlySkipped2692S9TechGateCoverage() {
  final game = wppEmptyWorldGame(
    players: [
      wppPlayer(
        stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 12}),
        workerPool: const WorkerPool(peasants: 1),
        treasury: 1200,
        techUnlocked: const {kTechIdMasterArtisans: true},
      ),
    ],
  );
  final p = wppPlayerAfter(
    game,
    wppRecruitOrders(WppIds.player1, [WorkerTier.master]),
    WppIds.player1,
  );
  expect(p.workerPool.peasants, 1, reason: 'peasant not consumed');
  expect(p.workerPool.masters, 0, reason: 'master not added');
  expect(
    p.stockpile.quantityOf(CommodityCatalog.paper.id),
    12,
    reason: 'no paper deducted',
  );
  expect(p.treasury, 1200, reason: 'no treasury deducted');
}

void _laterRecruitOrderObservesTheRunningStateOfEarlierAcceptedOrderInTheSameSubmissionList2692S9OrderingSemantics() {
  final game = wppEmptyWorldGame(
    players: [
      wppPlayer(
        stockpile: Stockpile(
          quantities: {
            CommodityCatalog.fabric.id: 2,
            CommodityCatalog.paper.id: 2,
          },
        ),
        workerPool: const WorkerPool(peasants: 0),
        treasury: 200,
        techUnlocked: wppApprenticeTech,
      ),
    ],
  );
  final p = wppPlayerAfter(
    game,
    wppRecruitOrders(WppIds.player1, [
      WorkerTier.peasant,
      WorkerTier.apprentice,
    ]),
    WppIds.player1,
  );
  expect(
    p.workerPool.peasants,
    0,
    reason: 'recruited peasant immediately consumed by the apprentice train',
  );
  expect(p.workerPool.apprentices, 1, reason: 'one apprentice added');
  expect(
    p.stockpile.quantityOf(CommodityCatalog.fabric.id),
    0,
    reason: 'peasant recruit consumed 2 fabric',
  );
  expect(
    p.stockpile.quantityOf(CommodityCatalog.paper.id),
    0,
    reason: 'apprentice train consumed 2 paper',
  );
  expect(p.treasury, 0, reason: 'apprentice train consumed 200 ducats');
}

void _middleOrderSilentlySkipsWhenPeasantsAreExhaustedLaterOrdersStillResolveAgainstTheRunningState2692S9Ac4ResolverBehavior() {
  final game = wppEmptyWorldGame(
    players: [
      wppPlayer(
        stockpile: Stockpile(
          quantities: {
            CommodityCatalog.fabric.id: 4,
            CommodityCatalog.paper.id: 4,
          },
        ),
        workerPool: const WorkerPool(peasants: 1),
        treasury: 400,
        techUnlocked: wppApprenticeTech,
      ),
    ],
  );
  final p = wppPlayerAfter(
    game,
    wppRecruitOrders(WppIds.player1, [
      WorkerTier.apprentice,
      WorkerTier.apprentice,
      WorkerTier.peasant,
    ]),
    WppIds.player1,
  );
  expect(
    p.workerPool.peasants,
    1,
    reason: 'apprentice consumed initial peasant; peasant recruit added 1',
  );
  expect(
    p.workerPool.apprentices,
    1,
    reason: 'only the first apprentice train fired; second skipped',
  );
  expect(
    p.stockpile.quantityOf(CommodityCatalog.paper.id),
    2,
    reason: 'one apprentice consumed 2 paper; second order did not',
  );
  expect(
    p.stockpile.quantityOf(CommodityCatalog.fabric.id),
    2,
    reason: 'trailing peasant recruit still consumed 2 fabric',
  );
  expect(
    p.treasury,
    200,
    reason: 'only one apprentice train deducted treasury',
  );
}

void _perPlayerOrderListsApplyInIsolation2692S9MultiPlayerPin() {
  final apprenticePlayer = wppPlayer(
    stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 4}),
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
        stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 4}),
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
  final p1 = result.players.firstWhere((p) => p.id == WppIds.player1);
  final p2 = result.players.firstWhere((p) => p.id == WppIds.player2);
  expect(p1.workerPool.peasants, 1);
  expect(p1.workerPool.apprentices, 1);
  expect(p1.stockpile.quantityOf(CommodityCatalog.paper.id), 2);
  expect(p1.treasury, 100);
  expect(p2.workerPool.peasants, 1);
  expect(p2.workerPool.apprentices, 1);
  expect(p2.stockpile.quantityOf(CommodityCatalog.paper.id), 2);
  expect(p2.treasury, 100);
}
