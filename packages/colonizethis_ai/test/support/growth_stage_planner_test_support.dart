// Shared fixtures for growth-stage planner tests (Refs #3371).
// SPEC/ai/growth-stage-planner.md. Kept in a non-test support file so the
// per-file non-comment line budget stays within repo-lint limits.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_test_fake_api.dart';
const kTestTopology = MapTopology(nodes: [], edges: []);
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

const kGrowthStageRelocationOw = 'oldWorld';
const kGrowthStageRelocationPGrain = '$kGrowthStageRelocationOw|p_grain';
const kGrowthStageRelocationPWool = '$kGrowthStageRelocationOw|p_wool';
const kGrowthStageRelocationTileGrain = '$kGrowthStageRelocationPGrain|0|0';
const kGrowthStageRelocationTileWool = '$kGrowthStageRelocationPWool|0|0';

const kGrowthStageRelocationTwoProvinceTopology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'p_grain',
      regionId: kGrowthStageRelocationOw,
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'p_wool',
      regionId: kGrowthStageRelocationOw,
      type: TopologyNodeType.province,
    ),
  ],
  edges: [TopologyEdge(id1: 'p_grain', id2: 'p_wool')],
);

/// Bootstrap GP with grain-capital Builder and unimproved wool feedstock tile.
Game growthStageRelocationFeedstockGame() => Game(
  id: 'g-3371-reloc',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: [
        Province(
          id: kGrowthStageRelocationPGrain,
          regionId: kGrowthStageRelocationOw,
          ownerId: 'gp1',
        ),
        Province(
          id: kGrowthStageRelocationPWool,
          regionId: kGrowthStageRelocationOw,
          ownerId: 'gp1',
        ),
      ],
      units: [
        Unit(
          id: 'b1',
          type: kUnitTypeBuilder,
          ownerId: 'gp1',
          locationProvinceId: kGrowthStageRelocationPGrain,
          tileKey: kGrowthStageRelocationTileGrain,
          status: UnitStatus.idle,
        ),
      ],
    ),
    newWorld: const RegionData(),
    resourceByTileKey: const {
      kGrowthStageRelocationTileGrain: 'grain',
      kGrowthStageRelocationTileWool: 'wool',
    },
    playerVisibilityByTile: const {
      'gp1': {
        kGrowthStageRelocationTileGrain: 'fullyVisible',
        kGrowthStageRelocationTileWool: 'fullyVisible',
      },
    },
    tileKeysByRegionAndProvince: {
      kGrowthStageRelocationOw: {
        kGrowthStageRelocationPGrain: [kGrowthStageRelocationTileGrain],
        kGrowthStageRelocationPWool: [kGrowthStageRelocationTileWool],
      },
    },
  ),
  players: [
    Player(
      id: 'gp1',
      displayName: 'GP1',
      isHuman: false,
      capitalProvinceId: kGrowthStageRelocationPGrain,
      stockpile: const Stockpile(),
      workerPool: const WorkerPool(peasants: 4),
    ),
  ],
);

/// Bootstrap GP for AC14 anti-thrash: low labour, fabric feedstock stage active.
Game growthStageReservedBootstrapGame() => growthStageRelocationFeedstockGame()
    .copyWith(id: 'g-3371-ac14');

/// Mature GP for AC14 negative: no active feedstock preference.
Game growthStageReservedMatureGame() {
  const tiles = [
    '$kGrowthStageRelocationOw|p0|0|0',
    '$kGrowthStageRelocationOw|p0|1|0',
    '$kGrowthStageRelocationOw|p0|2|0',
    '$kGrowthStageRelocationOw|p0|3|0',
    '$kGrowthStageRelocationOw|p0|4|0',
  ];
  return Game(
    id: 'g-3371-ac14-mature',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: '$kGrowthStageRelocationOw|p0',
            regionId: kGrowthStageRelocationOw,
            ownerId: 'gp1',
          ),
        ],
        units: [
          Unit(
            id: 'b1',
            type: kUnitTypeBuilder,
            ownerId: 'gp1',
            locationProvinceId: '$kGrowthStageRelocationOw|p0',
            tileKey: tiles.first,
            status: UnitStatus.idle,
          ),
        ],
      ),
      newWorld: const RegionData(),
      resourceByTileKey: {for (final t in tiles) t: 'timber'},
      tileState: TileMapState(
        improvementByTile: {for (final t in tiles) t: 1},
      ),
    ),
    players: [
      Player(
        id: 'gp1',
        displayName: 'GP1',
        isHuman: false,
        capitalProvinceId: '$kGrowthStageRelocationOw|p0',
        stockpile: const Stockpile().applyDelta(
          CommodityCatalog.fabric.id,
          kReserveTarget,
        ),
        workerPool: const WorkerPool(peasants: 30),
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
