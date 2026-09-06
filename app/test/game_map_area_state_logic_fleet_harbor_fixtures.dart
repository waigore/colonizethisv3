// Fixtures for in-port harbor anchoring fleet marker projection tests.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;

const fleetHarborTestHumanId = 'gp1';

final capitalPortOwMap = TileMapResult(
  width: 2,
  height: 2,
  grid: [
    ['p1', 's1'],
    ['p1', 'p1'],
  ],
);

final stubNwMap = TileMapResult(
  width: 1,
  height: 1,
  grid: [
    ['p1'],
  ],
);

const capitalPortOwTopology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'p1',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 's1',
      regionId: 'oldWorld',
      type: TopologyNodeType.seaZone,
    ),
  ],
  edges: [TopologyEdge(id1: 'p1', id2: 's1')],
);

const stubNwTopology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'p1',
      regionId: 'newWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: [],
);

Map<String, TileMapResult> capitalPortTiles() => {
  'oldWorld': capitalPortOwMap,
  'newWorld': stubNwMap,
};

Map<String, MapTopology> capitalPortTopologies() => {
  'oldWorld': capitalPortOwTopology,
  'newWorld': stubNwTopology,
};

ct_models.Game capitalPortHarborGame({
  required List<ct_models.Fleet> fleets,
}) {
  return ct_models.Game(
    id: 'g',
    worldState: ct_models.WorldState(
      turnState: const ct_models.TurnState(
        phase: ct_models.TurnPhase.orders,
        turnNumber: 0,
      ),
      oldWorld: ct_models.RegionData(
        provinces: [
          ct_models.Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            ownerId: fleetHarborTestHumanId,
            townTileKey: 'oldWorld|p1|1|1',
          ),
        ],
        units: const [],
      ),
      newWorld: const ct_models.RegionData(provinces: [], units: []),
      portsByProvinceSeaboard: {'oldWorld|p1|sb': 'oldWorld|p1|0|0'},
      fleets: fleets,
    ),
    players: const [
      ct_models.Player(
        id: fleetHarborTestHumanId,
        displayName: 'Human',
        isHuman: true,
      ),
    ],
    minorNations: const [],
    tribes: const [],
  );
}
