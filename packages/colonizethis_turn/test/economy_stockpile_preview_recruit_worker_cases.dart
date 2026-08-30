// Shared fixtures for economy_stockpile_preview_recruit_worker_test
// (Refs #4168 slice B, #4342 Slice C).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

Player economyPreviewRecruitWorkerPlayer({
  String id = 'p1',
  Stockpile stockpile = const Stockpile(),
  WorkerPool workerPool = const WorkerPool(),
  int treasury = 0,
  Map<String, bool>? techUnlocked,
}) {
  return Player(
    id: id,
    displayName: 'A',
    isHuman: true,
    stockpile: stockpile,
    workerPool: workerPool,
    treasury: treasury,
    techUnlocked: techUnlocked,
  );
}

const economyPreviewRecruitApprenticeTechUnlocked = {
  kTechIdApprenticeWorkers: true,
  kTechIdSugarRefining: true,
};

Orders recruitWorkerOrdersFor(WorkerTier tier, {int count = 1}) => Orders(
  recruitWorkerOrdersByPlayerId: {
    'p1': List<RecruitWorkerOrder>.filled(
      count,
      RecruitWorkerOrder(targetTier: tier),
    ),
  },
);

({
  Game game,
  Map<String, int> delta,
  Map<EconomyPreviewStockpilePhase, Map<String, int>> phases,
  Game preview,
})
runRecruitWorkerPreview({required Player player, required Orders orders}) {
  final game = TestFixtures.singlePlayerGame(player);
  final inputs = economyPreviewInputs(currentOrders: orders);
  return (
    game: game,
    delta: previewStockpileNetDeltaByCommodityForPlayer(
      game: game,
      topology: const MapTopology(),
      playerId: 'p1',
      inputs: inputs,
    ),
    phases: previewStockpilePhaseDeltasByCommodityForPlayer(
      game: game,
      topology: const MapTopology(),
      playerId: 'p1',
      inputs: inputs,
    ),
    preview: applyEconomyPhasesForPreview(
      game: game,
      topology: const MapTopology(),
      inputs: inputs,
    ),
  );
}

Game recruitWorkerBuildUnitParityGame() {
  const ownedProvinceId = 'oldWorld|p1';
  final player = Player(
    id: 'p1',
    displayName: 'A',
    isHuman: true,
    capitalProvinceId: ownedProvinceId,
    stockpile: const Stockpile()
        .applyDelta(CommodityCatalog.fabric.id, 5)
        .applyDelta(CommodityCatalog.paper.id, 5),
    workerPool: const WorkerPool(peasants: 1),
    treasury: 5000,
    techUnlocked: economyPreviewRecruitApprenticeTechUnlocked,
  );
  return TestFixtures.minimalGame(
    players: [player],
    oldWorld: const RegionData(
      provinces: [
        Province(id: ownedProvinceId, regionId: 'oldWorld', ownerId: 'p1'),
      ],
    ),
  );
}

Orders recruitThenBuildPeasantLeviesOrders() {
  const ownedProvinceId = 'oldWorld|p1';
  return const Orders(
    recruitWorkerOrdersByPlayerId: {
      'p1': [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
    },
    buildUnitOrdersByPlayerId: {
      'p1': [
        BuildUnitOrder(
          unitType: 'peasant_levies',
          isMilitary: true,
          spawnProvinceId: ownedProvinceId,
        ),
      ],
    },
  );
}
