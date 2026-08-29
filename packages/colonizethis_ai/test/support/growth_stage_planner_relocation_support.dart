// Relocation / reserved-bootstrap fixtures (Refs #3371 / #4602 Slice E).

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
