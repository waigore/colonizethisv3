part of 'incremental_candidate_validator_equivalence_test_helpers.dart';

const _iceCorpusOw = 'oldWorld';

List<Province> _iceCorpusProvinces() => const [
      Province(id: '$_iceCorpusOw|P1', regionId: _iceCorpusOw, ownerId: 'p1'),
      Province(id: '$_iceCorpusOw|P2', regionId: _iceCorpusOw, ownerId: 'p1'),
      Province(id: '$_iceCorpusOw|P3', regionId: _iceCorpusOw, ownerId: 'p2'),
      Province(id: '$_iceCorpusOw|P4', regionId: _iceCorpusOw, ownerId: 'minor1'),
    ];

Map<String, Map<String, String>> _iceCorpusVisibility() => const {
      'p1': {
        '$_iceCorpusOw|P1|0|0': 'fullyVisible',
        '$_iceCorpusOw|P2|0|0': 'fogged',
        '$_iceCorpusOw|P3|0|0': 'fogged',
        '$_iceCorpusOw|P4|0|0': 'fogged',
      },
    };

Map<String, Map<String, List<String>>> _iceCorpusTileKeys() => const {
      _iceCorpusOw: {
        '$_iceCorpusOw|P1': ['$_iceCorpusOw|P1|0|0'],
        '$_iceCorpusOw|P2': ['$_iceCorpusOw|P2|0|0'],
        '$_iceCorpusOw|P3': ['$_iceCorpusOw|P3|0|0'],
        '$_iceCorpusOw|P4': ['$_iceCorpusOw|P4|0|0'],
      },
    };

List<TopologyNode> _iceCorpusTopologyNodes() => const [
      TopologyNode(id: '$_iceCorpusOw|P1', regionId: _iceCorpusOw, type: TopologyNodeType.province),
      TopologyNode(id: '$_iceCorpusOw|P2', regionId: _iceCorpusOw, type: TopologyNodeType.province),
      TopologyNode(id: '$_iceCorpusOw|P3', regionId: _iceCorpusOw, type: TopologyNodeType.province),
      TopologyNode(id: '$_iceCorpusOw|P4', regionId: _iceCorpusOw, type: TopologyNodeType.province),
    ];

Game moveCorpusGame() {
  return Game(
    id: 'g_move_eq',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: _iceCorpusProvinces(),
        units: [
          Unit(
            id: 'u_builder',
            type: kUnitTypeBuilder,
            ownerId: 'p1',
            locationProvinceId: '$_iceCorpusOw|P1',
            tileKey: '$_iceCorpusOw|P1|0|0',
          ),
          Unit(
            id: 'u_explorer',
            type: kUnitTypeExplorer,
            ownerId: 'p1',
            locationProvinceId: '$_iceCorpusOw|P1',
            tileKey: '$_iceCorpusOw|P1|0|0',
          ),
          Unit(
            id: 'u_spy',
            type: kUnitTypeSpy,
            ownerId: 'p1',
            locationProvinceId: '$_iceCorpusOw|P1',
            tileKey: '$_iceCorpusOw|P1|0|0',
          ),
          Unit(
            id: 'u_pikemen',
            type: 'pikemen',
            ownerId: 'p1',
            locationProvinceId: '$_iceCorpusOw|P1',
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: _iceCorpusTileKeys(),
      playerVisibilityByTile: _iceCorpusVisibility(),
    ),
    players: const [
      Player(id: 'p1', displayName: 'P1', isHuman: true),
      Player(id: 'p2', displayName: 'P2', isHuman: true),
    ],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
  );
}

MapTopology moveCorpusTopology() {
  return MapTopology(
    nodes: _iceCorpusTopologyNodes(),
    edges: const [],
  );
}

Game armyCorpusGame() {
  Army field(String id, String stationed, String regimentId) => Army(
    id: id,
    ownerId: 'p1',
    regionId: _iceCorpusOw,
    stationedProvinceId: stationed,
    regimentUnitIds: [regimentId],
    isHomeArmy: false,
  );
  return Game(
    id: 'g_army_eq',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: _iceCorpusProvinces(),
        units: [
          Unit(
            id: 'r1',
            type: 'pikemen',
            ownerId: 'p1',
            locationProvinceId: '$_iceCorpusOw|P1',
          ),
        ],
      ),
      newWorld: const RegionData(),
      armies: [field('field_a', '$_iceCorpusOw|P1', 'r1')],
      playerVisibilityByTile: _iceCorpusVisibility(),
      tileKeysByRegionAndProvince: _iceCorpusTileKeys(),
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
  return MapTopology(
    nodes: _iceCorpusTopologyNodes(),
    edges: const [
      TopologyEdge(id1: '$_iceCorpusOw|P1', id2: '$_iceCorpusOw|P2'),
      TopologyEdge(id1: '$_iceCorpusOw|P1', id2: '$_iceCorpusOw|P3'),
      TopologyEdge(id1: '$_iceCorpusOw|P1', id2: '$_iceCorpusOw|P4'),
    ],
  );
}