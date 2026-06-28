// Shared fixtures for growth-stage planner tests (Refs #3371).
// SPEC/ai/growth-stage-planner.md. Kept in a non-test support file so the
// per-file non-comment line budget stays within repo-lint limits.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_test_fake_api.dart';
import 'planner_test_helpers.dart' show kTestAiConfig;

const kTestTopology = MapTopology(nodes: [], edges: []);

/// Alias to the single shared default AI config (`kTestAiConfig`,
/// `planner_test_helpers.dart`) so the growth-stage suites reuse one constant
/// rather than duplicating the literal `AIConfig` (Refs #3749).
const kTestConfig = kTestAiConfig;
final kTestSeeds = AISeedBundle.fromTurnSeed(3371);

Game gameWithPlayer(Player player) => Game(
  id: 'g1',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: const RegionData(provinces: [], units: []),
    newWorld: const RegionData(provinces: [], units: []),
  ),
  players: [player],
);

OrderSuggestionAPI buildFakeApi({
  List<RecruitWorkerOrder> recruit = const [],
  List<BuildUnitOrder> build = const [],
}) {
  return FakeOrderSuggestionAPIForDomainPlannerTests(
    work: const [],
    build: build,
    move: const [],
    research: const [],
    navalMove: const [],
    navalMission: const [],
    recruitWorker: recruit,
  );
}

int labourForRecipe(EconomyPlan plan, String recipeId) {
  for (final a in plan.productionAssignments) {
    if (a.recipeId == recipeId) return a.assignedLabour;
  }
  return 0;
}

Game bootstrapFabricGame() {
  const ow = 'oldWorld';
  return Game(
    id: 'g-3371-ac1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(
        provinces: [
          Province(id: '$ow|p0', regionId: ow, ownerId: 'gp1'),
        ],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: const {'$ow|p0|1|0': 'wool'},
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP1',
        isHuman: false,
        capitalProvinceId: '$ow|p0',
        stockpile: const Stockpile()
            .applyDelta(CommodityCatalog.grain.id, 40)
            .applyDelta(CommodityCatalog.wool.id, 10),
        workerPool: const WorkerPool(peasants: 4),
      ),
    ],
  );
}

Game matureCastIronGame({int castIronHeld = 0}) {
  const ow = 'oldWorld';
  return Game(
    id: 'g-3371-ac2',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(
        provinces: [
          Province(id: '$ow|p0', regionId: ow, ownerId: 'gp1'),
          Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
        ],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: const {
        '$ow|p0|1|0': 'timber',
        '$ow|p1|1|0': 'iron',
      },
      tileState: const TileMapState(
        improvementByTile: {
          '$ow|p0|1|0': 1,
          '$ow|p1|1|0': 1,
        },
      ),
      playerProspectedTiles: const {
        'gp1': {'$ow|p1|1|0'},
      },
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP1',
        isHuman: false,
        capitalProvinceId: '$ow|p0',
        stockpile: Stockpile()
            .applyDelta(CommodityCatalog.grain.id, 80)
            .applyDelta(CommodityCatalog.timber.id, 30)
            .applyDelta(CommodityCatalog.iron.id, 10)
            .applyDelta(CommodityCatalog.castIron.id, castIronHeld),
        workerPool: const WorkerPool(peasants: 12),
      ),
    ],
  );
}

AIWorldSnapshot atWarSnapshot(String playerId) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: const ThreatSummary(
      atWarWith: ['gp2'],
      neighborProvincesHostile: 1,
      capitalThreatened: false,
    ),
    opportunities: const OpportunitySummary(),
    conquest: const ConquestSummary(
      oldWorldProvincesOwned: 2,
      provincesToVictory: 29,
      invadableProvinceIdsSorted: ['oldWorld|enemy'],
    ),
    economy: const EconomySummary(
      workerCount: 4,
      treasury: 100,
      ownProvinceCount: 2,
    ),
    relations: const {},
  );
}
