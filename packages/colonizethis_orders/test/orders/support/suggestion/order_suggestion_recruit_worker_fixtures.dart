// Shared recruit-worker suggestion fixtures (Refs #3949 / #3971).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_suggestion_recruit_worker_test_support.dart';

// dart format off
const _rwApprenticeTech = {kTechIdApprenticeWorkers: true, kTechIdSugarRefining: true};
const _rwAllTierTech = {
  kTechIdApprenticeWorkers: true,
  kTechIdSugarRefining: true,
  kTechIdTrainedJourneymen: true,
  kTechIdCigarProduction: true,
  kTechIdMasterArtisans: true,
  kTechIdHatProduction: true,
};

Player _rwPlayer({
  Map<String, int> stock = const {},
  int peasants = 0,
  int treasury = 0,
  Map<String, bool>? tech,
}) => Player(
  id: 'p1',
  displayName: 'P',
  isHuman: true,
  stockpile: Stockpile(quantities: stock),
  workerPool: WorkerPool(peasants: peasants),
  treasury: treasury,
  techUnlocked: tech,
);

Game recruitWorkerInclusionPeasantAndApprenticeGame() => recruitWorkerTestGameWith(
  player: _rwPlayer(
    stock: {CommodityCatalog.fabric.id: 4, CommodityCatalog.paper.id: 5},
    peasants: 1,
    treasury: 500,
    tech: _rwApprenticeTech,
  ),
);

Game recruitWorkerInclusionTechLockedGame() => recruitWorkerTestGameWith(
  player: _rwPlayer(
    stock: {CommodityCatalog.fabric.id: 10, CommodityCatalog.paper.id: 50},
    peasants: 5,
    treasury: 5000,
  ),
);

Game recruitWorkerInclusionInsufficientFabricGame() => recruitWorkerTestGameWith(
  player: _rwPlayer(stock: {CommodityCatalog.fabric.id: 1}),
);

Game recruitWorkerInclusionLowTreasuryGame() => recruitWorkerTestGameWith(
  player: _rwPlayer(
    stock: {CommodityCatalog.paper.id: 5},
    peasants: 1,
    treasury: 100,
    tech: _rwApprenticeTech,
  ),
);

Game recruitWorkerInclusionEmptyPeasantPoolGame() => recruitWorkerTestGameWith(
  player: _rwPlayer(
    stock: {CommodityCatalog.paper.id: 5},
    treasury: 500,
    tech: _rwApprenticeTech,
  ),
);

Game recruitWorkerParityAllTiersGame() => recruitWorkerTestGameWith(
  player: _rwPlayer(
    stock: {CommodityCatalog.fabric.id: 4, CommodityCatalog.paper.id: 50},
    peasants: 3,
    treasury: 5000,
    tech: _rwAllTierTech,
  ),
);

Game recruitWorkerParityPeasantReservationGame() => recruitWorkerTestGameWith(
  player: _rwPlayer(
    stock: {CommodityCatalog.fabric.id: 4, CommodityCatalog.paper.id: 50},
    peasants: 1,
    treasury: 5000,
    tech: _rwApprenticeTech,
  ),
);

const recruitWorkerParityPeasantReservationOrders = Orders(
  recruitWorkerOrdersByPlayerId: {
    'p1': [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
  },
);

Game recruitWorkerParityPartialTechFixtureGame() => recruitWorkerTestGameWith(
  player: _rwPlayer(
    stock: {CommodityCatalog.fabric.id: 4, CommodityCatalog.paper.id: 50},
    peasants: 1,
    treasury: 250,
    tech: _rwAllTierTech,
  ),
);

Game recruitWorkerParityEmptyPlayerGame() =>
    recruitWorkerTestGameWith(player: _rwPlayer());
// dart format on
