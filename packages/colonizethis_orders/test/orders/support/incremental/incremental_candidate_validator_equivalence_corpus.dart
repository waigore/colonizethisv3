// Incremental equivalence corpus games (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

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

Game _iceCorpusGame({
  required String id,
  required RegionData oldWorld,
  List<Army> armies = const [],
}) =>
    Game(
      id: id,
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: oldWorld,
        newWorld: const RegionData(),
        armies: armies,
        tileKeysByRegionAndProvince: _iceCorpusTileKeys(),
        playerVisibilityByTile: _iceCorpusVisibility(),
      ),
      players: const [
        Player(id: 'p1', displayName: 'P1', isHuman: true),
        Player(id: 'p2', displayName: 'P2', isHuman: true),
      ],
      minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
    );

Game moveCorpusGame() {
  return _iceCorpusGame(
    id: 'g_move_eq',
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
  return _iceCorpusGame(
    id: 'g_army_eq',
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
    armies: [field('field_a', '$_iceCorpusOw|P1', 'r1')],
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

Game navalCorpusGame() {
  const ow = _iceCorpusOw;
  return Game(
    id: 'g_naval_eq',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$ow|coastA', regionId: ow, ownerId: 'p1'),
          Province(id: '$ow|coastB', regionId: ow, ownerId: 'p1'),
        ],
      ),
      newWorld: const RegionData(),
      fleets: [
        Fleet(
          id: 'fleet_atSea',
          ownerId: 'p1',
          regionId: ow,
          seaZoneId: '$ow|sea1',
          shipTypeIds: const ['carrack'],
        ),
        Fleet(
          id: 'fleet_inPort',
          ownerId: 'p1',
          regionId: ow,
          inPortAtProvinceId: '$ow|coastA',
          shipTypeIds: const ['carrack'],
        ),
      ],
      tileKeysByRegionAndProvince: const {
        ow: {
          '$ow|coastA': ['$ow|coastA|0|0'],
          '$ow|coastB': ['$ow|coastB|0|0'],
        },
      },
    ),
    players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
  );
}

MapTopology navalCorpusTopology() {
  const ow = _iceCorpusOw;
  return MapTopology(
    nodes: const [
      TopologyNode(
        id: '$ow|coastA',
        regionId: ow,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: '$ow|coastB',
        regionId: ow,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: '$ow|sea1',
        regionId: ow,
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: '$ow|sea2',
        regionId: ow,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: const [
      TopologyEdge(id1: '$ow|sea1', id2: '$ow|sea2'),
      TopologyEdge(id1: '$ow|sea1', id2: '$ow|coastA'),
      TopologyEdge(id1: '$ow|sea2', id2: '$ow|coastB'),
    ],
  );
}
