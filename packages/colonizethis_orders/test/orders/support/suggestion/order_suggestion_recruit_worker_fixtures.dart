// Shared recruit-worker suggestion fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_suggestion_recruit_worker_test_support.dart';

Game recruitWorkerInclusionPeasantAndApprenticeGame() =>
    recruitWorkerTestGameWith(
      player: Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        stockpile: Stockpile(
          quantities: {
            CommodityCatalog.fabric.id: 4,
            CommodityCatalog.paper.id: 5,
          },
        ),
        workerPool: const WorkerPool(peasants: 1),
        treasury: 500,
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
        },
      ),
    );

Game recruitWorkerInclusionTechLockedGame() => recruitWorkerTestGameWith(
      player: Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        stockpile: Stockpile(
          quantities: {
            CommodityCatalog.fabric.id: 10,
            CommodityCatalog.paper.id: 50,
          },
        ),
        workerPool: const WorkerPool(peasants: 5),
        treasury: 5000,
      ),
    );

Game recruitWorkerInclusionInsufficientFabricGame() =>
    recruitWorkerTestGameWith(
      player: Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        stockpile: Stockpile(
          quantities: {CommodityCatalog.fabric.id: 1},
        ),
      ),
    );

Game recruitWorkerInclusionLowTreasuryGame() => recruitWorkerTestGameWith(
      player: Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        stockpile: Stockpile(
          quantities: {CommodityCatalog.paper.id: 5},
        ),
        workerPool: const WorkerPool(peasants: 1),
        treasury: 100,
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
        },
      ),
    );

Game recruitWorkerInclusionEmptyPeasantPoolGame() =>
    recruitWorkerTestGameWith(
      player: Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        stockpile: Stockpile(
          quantities: {CommodityCatalog.paper.id: 5},
        ),
        workerPool: const WorkerPool(),
        treasury: 500,
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
        },
      ),
    );

Game recruitWorkerParityAllTiersGame() => recruitWorkerTestGameWith(
      player: Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        stockpile: Stockpile(
          quantities: {
            CommodityCatalog.fabric.id: 4,
            CommodityCatalog.paper.id: 50,
          },
        ),
        workerPool: const WorkerPool(peasants: 3),
        treasury: 5000,
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
          kTechIdTrainedJourneymen: true,
          kTechIdCigarProduction: true,
          kTechIdMasterArtisans: true,
          kTechIdHatProduction: true,
        },
      ),
    );

Game recruitWorkerParityPeasantReservationGame() =>
    recruitWorkerTestGameWith(
      player: Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        stockpile: Stockpile(
          quantities: {
            CommodityCatalog.fabric.id: 4,
            CommodityCatalog.paper.id: 50,
          },
        ),
        workerPool: const WorkerPool(peasants: 1),
        treasury: 5000,
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
        },
      ),
    );

const recruitWorkerParityPeasantReservationOrders = Orders(
  recruitWorkerOrdersByPlayerId: {
    'p1': [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
  },
);

Game recruitWorkerParityPartialTechFixtureGame() =>
    recruitWorkerTestGameWith(
      player: Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
        stockpile: Stockpile(
          quantities: {
            CommodityCatalog.fabric.id: 4,
            CommodityCatalog.paper.id: 50,
          },
        ),
        workerPool: const WorkerPool(peasants: 1),
        treasury: 250,
        techUnlocked: const {
          kTechIdApprenticeWorkers: true,
          kTechIdSugarRefining: true,
          kTechIdTrainedJourneymen: true,
          kTechIdCigarProduction: true,
          kTechIdMasterArtisans: true,
          kTechIdHatProduction: true,
        },
      ),
    );

Game recruitWorkerParityEmptyPlayerGame() => recruitWorkerTestGameWith(
      player: Player(
        id: 'p1',
        displayName: 'P',
        isHuman: true,
      ),
    );
