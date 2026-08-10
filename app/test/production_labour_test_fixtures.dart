// Shared fixtures for production labour helper and widget tests (Refs #4305).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const productionLabourTestPlayerId = 'gp_labour_test';

const productionLabourApprenticeTech = <String, bool>{
  kTechIdApprenticeWorkers: true,
  kTechIdSugarRefining: true,
};

const productionLabourTrainedThroughJourneymanTech = <String, bool>{
  ...productionLabourApprenticeTech,
  kTechIdTrainedJourneymen: true,
  kTechIdCigarProduction: true,
};

const productionLabourFullLabourTech = <String, bool>{
  ...productionLabourTrainedThroughJourneymanTech,
  kTechIdMasterArtisans: true,
  kTechIdHatProduction: true,
};

const productionLabourTrainedTiers = <WorkerTier>[
  WorkerTier.apprentice,
  WorkerTier.journeyman,
  WorkerTier.master,
];

Player productionLabourGpWithPool({
  String id = productionLabourTestPlayerId,
  int peasants = 0,
  int apprentices = 0,
  int journeymen = 0,
  int masters = 0,
  int treasury = 0,
  Map<String, int> stockpile = const {},
  Map<String, bool>? techUnlocked,
}) {
  return Player(
    id: id,
    displayName: 'Labour test GP',
    isHuman: true,
    workerPool: WorkerPool(
      peasants: peasants,
      apprentices: apprentices,
      journeymen: journeymen,
      masters: masters,
    ),
    stockpile: Stockpile(quantities: Map<String, int>.from(stockpile)),
    treasury: treasury,
    techUnlocked: techUnlocked,
  );
}

Orders productionLabourOrdersWithRecruits(
  List<WorkerTier> tiers, {
  String id = productionLabourTestPlayerId,
}) {
  if (tiers.isEmpty) return const Orders();
  return Orders(
    recruitWorkerOrdersByPlayerId: {
      id: [for (final t in tiers) RecruitWorkerOrder(targetTier: t)],
    },
  );
}

Orders productionLabourOrdersWithMilitaryBuilds(
  int count, {
  String id = productionLabourTestPlayerId,
}) {
  if (count <= 0) return const Orders();
  final militaryUnitType = RegimentEconomyCatalog.byId.keys.first;
  return Orders(
    buildUnitOrdersByPlayerId: {
      id: [
        for (var i = 0; i < count; i++)
          BuildUnitOrder(
            unitType: militaryUnitType,
            isMilitary: true,
            spawnProvinceId: 'province_x',
          ),
      ],
    },
  );
}

Game productionLabourEmptyGame({List<Player> players = const []}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: players,
  );
}
