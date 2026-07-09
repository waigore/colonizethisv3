part of 'incremental_candidate_validator_equivalence_test_helpers.dart';

Game moveCorpusGame() {
  const ow = 'oldWorld';
  return Game(
    id: 'g_move_eq',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
          Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
          Province(id: '$ow|P3', regionId: ow, ownerId: 'p2'),
          Province(id: '$ow|P4', regionId: ow, ownerId: 'minor1'),
        ],
        units: [
          Unit(
            id: 'u_builder',
            type: kUnitTypeBuilder,
            ownerId: 'p1',
            locationProvinceId: '$ow|P1',
            tileKey: '$ow|P1|0|0',
          ),
          Unit(
            id: 'u_explorer',
            type: kUnitTypeExplorer,
            ownerId: 'p1',
            locationProvinceId: '$ow|P1',
            tileKey: '$ow|P1|0|0',
          ),
          Unit(
            id: 'u_spy',
            type: kUnitTypeSpy,
            ownerId: 'p1',
            locationProvinceId: '$ow|P1',
            tileKey: '$ow|P1|0|0',
          ),
          Unit(
            id: 'u_pikemen',
            type: 'pikemen',
            ownerId: 'p1',
            locationProvinceId: '$ow|P1',
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: const {
        ow: {
          '$ow|P1': ['$ow|P1|0|0'],
          '$ow|P2': ['$ow|P2|0|0'],
          '$ow|P3': ['$ow|P3|0|0'],
          '$ow|P4': ['$ow|P4|0|0'],
        },
      },
      playerVisibilityByTile: const {
        'p1': {
          '$ow|P1|0|0': 'fullyVisible',
          '$ow|P2|0|0': 'fogged',
          '$ow|P3|0|0': 'fogged',
          '$ow|P4|0|0': 'fogged',
        },
      },
    ),
    players: const [
      Player(id: 'p1', displayName: 'P1', isHuman: true),
      Player(id: 'p2', displayName: 'P2', isHuman: true),
    ],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
  );
}

MapTopology moveCorpusTopology() {
  const ow = 'oldWorld';
  return MapTopology(
    nodes: const [
      TopologyNode(id: '$ow|P1', regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: '$ow|P2', regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: '$ow|P3', regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: '$ow|P4', regionId: ow, type: TopologyNodeType.province),
    ],
    edges: const [],
  );
}

Game armyCorpusGame() {
  const ow = 'oldWorld';
  Army field(String id, String stationed, String regimentId) => Army(
    id: id,
    ownerId: 'p1',
    regionId: ow,
    stationedProvinceId: stationed,
    regimentUnitIds: [regimentId],
    isHomeArmy: false,
  );
  return Game(
    id: 'g_army_eq',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
          Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
          Province(id: '$ow|P3', regionId: ow, ownerId: 'p2'),
          Province(id: '$ow|P4', regionId: ow, ownerId: 'minor1'),
        ],
        units: [
          Unit(
            id: 'r1',
            type: 'pikemen',
            ownerId: 'p1',
            locationProvinceId: '$ow|P1',
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: [field('field_a', '$ow|P1', 'r1')],
      playerVisibilityByTile: const {
        'p1': {
          '$ow|P1|0|0': 'fullyVisible',
          '$ow|P2|0|0': 'fogged',
          '$ow|P3|0|0': 'fogged',
          '$ow|P4|0|0': 'fogged',
        },
      },
      tileKeysByRegionAndProvince: const {
        ow: {
          '$ow|P1': ['$ow|P1|0|0'],
          '$ow|P2': ['$ow|P2|0|0'],
          '$ow|P3': ['$ow|P3|0|0'],
          '$ow|P4': ['$ow|P4|0|0'],
        },
      },
    ),
    players: const [
      Player(id: 'p1', displayName: 'P1', isHuman: true),
      Player(id: 'p2', displayName: 'P2', isHuman: true),
    ],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
    diplomacyRelations: const [],
  );
}

MapTopology armyCorpusTopology() {
  const ow = 'oldWorld';
  return MapTopology(
    nodes: const [
      TopologyNode(id: '$ow|P1', regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: '$ow|P2', regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: '$ow|P3', regionId: ow, type: TopologyNodeType.province),
      TopologyNode(id: '$ow|P4', regionId: ow, type: TopologyNodeType.province),
    ],
    edges: const [
      TopologyEdge(id1: '$ow|P1', id2: '$ow|P2'),
      TopologyEdge(id1: '$ow|P1', id2: '$ow|P3'),
      TopologyEdge(id1: '$ow|P1', id2: '$ow|P4'),
    ],
  );
}
