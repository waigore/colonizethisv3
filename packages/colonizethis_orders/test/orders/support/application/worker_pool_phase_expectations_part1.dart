part of 'worker_pool_phase_expectations.dart';

Game _emptyWorldGame({required List<Player> players}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: players,
  );
}

void _acceptedRecruitPeasantOrderAdds1PeasantAndDeductsFabric() {
  final game = _emptyWorldGame(
    players: [
      Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        stockpile: Stockpile(quantities: {CommodityCatalog.fabric.id: 3}),
        workerPool: const WorkerPool(peasants: 0),
      ),
    ],
  );
  final orders = Orders(
    recruitWorkerOrdersByPlayerId: {
      'p1': const [RecruitWorkerOrder(targetTier: WorkerTier.peasant)],
    },
  );
  final result = applyBuildAndWorkOrders(game, orders);
  final p = result.players.single;
  expect(p.workerPool.peasants, 1);
  expect(p.stockpile.quantityOf(CommodityCatalog.fabric.id), 1);
  expect(p.treasury, 0);
}

void _acceptedApprenticeTrainConsumesPeasantPaperAndTreasury() {
  final game = _emptyWorldGame(
    players: [
      Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 5}),
        workerPool: const WorkerPool(peasants: 3),
        treasury: 500,
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
        },
      ),
    ],
  );
  final orders = Orders(
    recruitWorkerOrdersByPlayerId: {
      'p1': const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
    },
  );
  final result = applyBuildAndWorkOrders(game, orders);
  final p = result.players.single;
  expect(p.workerPool.peasants, 2);
  expect(p.workerPool.apprentices, 1);
  expect(p.stockpile.quantityOf(CommodityCatalog.paper.id), 3);
  expect(p.treasury, 300);
}

void _recruitThatFailsAffordabilityChecksDoesNotMutateThePlayerNoPartialDeduction() {
  final game = _emptyWorldGame(
    players: [
      Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 5}),
        workerPool: const WorkerPool(peasants: 3),
        treasury: 100,
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
        },
      ),
    ],
  );
  final orders = Orders(
    recruitWorkerOrdersByPlayerId: {
      'p1': const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
    },
  );
  final result = applyBuildAndWorkOrders(game, orders);
  final p = result.players.single;
  expect(p.workerPool.peasants, 3);
  expect(p.workerPool.apprentices, 0);
  expect(p.stockpile.quantityOf(CommodityCatalog.paper.id), 5);
  expect(p.treasury, 100);
}

void _acceptedJourneymanTrainConsumesPeasantPaperAndTreasury2692S9TierCoverage() {
  final game = _emptyWorldGame(
    players: [
      Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 8}),
        workerPool: const WorkerPool(peasants: 2),
        treasury: 700,
        techUnlocked: const {
          kTechIdTrainedJourneymen: true,
          kTechIdCigarProduction: true,
        },
      ),
    ],
  );
  final orders = Orders(
    recruitWorkerOrdersByPlayerId: {
      'p1': const [RecruitWorkerOrder(targetTier: WorkerTier.journeyman)],
    },
  );
  final result = applyBuildAndWorkOrders(game, orders);
  final p = result.players.single;
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
  final game = _emptyWorldGame(
    players: [
      Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 12}),
        workerPool: const WorkerPool(peasants: 1),
        treasury: 1200,
        techUnlocked: const {
          kTechIdMasterArtisans: true,
          kTechIdHatProduction: true,
        },
      ),
    ],
  );
  final orders = Orders(
    recruitWorkerOrdersByPlayerId: {
      'p1': const [RecruitWorkerOrder(targetTier: WorkerTier.master)],
    },
  );
  final result = applyBuildAndWorkOrders(game, orders);
  final p = result.players.single;
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
  final game = _emptyWorldGame(
    players: [
      Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 12}),
        workerPool: const WorkerPool(peasants: 1),
        treasury: 1200,
        techUnlocked: const {kTechIdMasterArtisans: true},
      ),
    ],
  );
  final orders = Orders(
    recruitWorkerOrdersByPlayerId: {
      'p1': const [RecruitWorkerOrder(targetTier: WorkerTier.master)],
    },
  );
  final result = applyBuildAndWorkOrders(game, orders);
  final p = result.players.single;
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
  final game = _emptyWorldGame(
    players: [
      Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        stockpile: Stockpile(
          quantities: {
            CommodityCatalog.fabric.id: 2,
            CommodityCatalog.paper.id: 2,
          },
        ),
        workerPool: const WorkerPool(peasants: 0),
        treasury: 200,
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
        },
      ),
    ],
  );
  final orders = Orders(
    recruitWorkerOrdersByPlayerId: {
      'p1': const [
        RecruitWorkerOrder(targetTier: WorkerTier.peasant),
        RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
      ],
    },
  );
  final result = applyBuildAndWorkOrders(game, orders);
  final p = result.players.single;
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
  final game = _emptyWorldGame(
    players: [
      Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        stockpile: Stockpile(
          quantities: {
            CommodityCatalog.fabric.id: 4,
            CommodityCatalog.paper.id: 4,
          },
        ),
        workerPool: const WorkerPool(peasants: 1),
        treasury: 400,
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
        },
      ),
    ],
  );
  final orders = Orders(
    recruitWorkerOrdersByPlayerId: {
      'p1': const [
        RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
        RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
        RecruitWorkerOrder(targetTier: WorkerTier.peasant),
      ],
    },
  );
  final result = applyBuildAndWorkOrders(game, orders);
  final p = result.players.single;
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
  final game = _emptyWorldGame(
    players: [
      Player(
        id: 'p1',
        displayName: 'A',
        isHuman: true,
        stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 4}),
        workerPool: const WorkerPool(peasants: 2),
        treasury: 300,
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
        },
      ),
      Player(
        id: 'p2',
        displayName: 'B',
        isHuman: false,
        stockpile: Stockpile(quantities: {CommodityCatalog.paper.id: 4}),
        workerPool: const WorkerPool(peasants: 2),
        treasury: 300,
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
        },
      ),
    ],
  );
  final orders = Orders(
    recruitWorkerOrdersByPlayerId: {
      'p1': const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
      'p2': const [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
    },
  );
  final result = applyBuildAndWorkOrders(game, orders);
  final p1 = result.players.firstWhere((p) => p.id == 'p1');
  final p2 = result.players.firstWhere((p) => p.id == 'p2');
  expect(p1.workerPool.peasants, 1);
  expect(p1.workerPool.apprentices, 1);
  expect(p1.stockpile.quantityOf(CommodityCatalog.paper.id), 2);
  expect(p1.treasury, 100);
  expect(p2.workerPool.peasants, 1);
  expect(p2.workerPool.apprentices, 1);
  expect(p2.stockpile.quantityOf(CommodityCatalog.paper.id), 2);
  expect(p2.treasury, 100);
}
