// Shared army-move picker destination fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const armyMovePickerGp = 'gp1';
const armyMovePickerCap = 'oldWorld|cap';
const armyMovePickerP1 = 'oldWorld|p1';
const armyMovePickerP2 = 'oldWorld|p2';
const armyMovePickerNw = 'newWorld|col';

Game armyMovePickerGameTwoNeighborsWithNw({required String id}) => Game(
  id: id,
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: [
        Province(
          id: armyMovePickerCap,
          regionId: 'oldWorld',
          ownerId: armyMovePickerGp,
          townTileKey: 'oldWorld|cap|0|0',
        ),
        Province(
          id: armyMovePickerP1,
          regionId: 'oldWorld',
          ownerId: armyMovePickerGp,
        ),
        Province(
          id: armyMovePickerP2,
          regionId: 'oldWorld',
          ownerId: armyMovePickerGp,
        ),
      ],
      units: const [],
    ),
    newWorld: RegionData(
      provinces: [
        Province(
          id: armyMovePickerNw,
          regionId: 'newWorld',
          ownerId: armyMovePickerGp,
        ),
      ],
    ),
    armies: [
      Army(
        id: 'field_a',
        ownerId: armyMovePickerGp,
        regionId: 'oldWorld',
        stationedProvinceId: armyMovePickerP1,
        regimentUnitIds: const [],
        isHomeArmy: false,
      ),
    ],
    tileKeysByRegionAndProvince: const {},
  ),
  players: [
    Player(
      id: armyMovePickerGp,
      displayName: 'T',
      isHuman: true,
      capitalProvinceId: armyMovePickerCap,
    ),
  ],
);

Game armyMovePickerGameMinimal({required String id}) => Game(
  id: id,
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: [
        Province(
          id: armyMovePickerCap,
          regionId: 'oldWorld',
          ownerId: armyMovePickerGp,
          townTileKey: 'oldWorld|cap|0|0',
        ),
        Province(
          id: armyMovePickerP1,
          regionId: 'oldWorld',
          ownerId: armyMovePickerGp,
        ),
      ],
      units: const [],
    ),
    newWorld: const RegionData(),
    armies: [
      Army(
        id: 'field_a',
        ownerId: armyMovePickerGp,
        regionId: 'oldWorld',
        stationedProvinceId: armyMovePickerP1,
        regimentUnitIds: const [],
        isHomeArmy: false,
      ),
    ],
    tileKeysByRegionAndProvince: const {},
  ),
  players: [
    Player(
      id: armyMovePickerGp,
      displayName: 'T',
      isHuman: true,
      capitalProvinceId: armyMovePickerCap,
    ),
  ],
);

Game armyMovePickerGameTwoNeighborsOnly({required String id}) => Game(
  id: id,
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: [
        Province(
          id: armyMovePickerCap,
          regionId: 'oldWorld',
          ownerId: armyMovePickerGp,
          townTileKey: 'oldWorld|cap|0|0',
        ),
        Province(
          id: armyMovePickerP1,
          regionId: 'oldWorld',
          ownerId: armyMovePickerGp,
        ),
        Province(
          id: armyMovePickerP2,
          regionId: 'oldWorld',
          ownerId: armyMovePickerGp,
        ),
      ],
      units: const [],
    ),
    newWorld: const RegionData(),
    armies: [
      Army(
        id: 'field_a',
        ownerId: armyMovePickerGp,
        regionId: 'oldWorld',
        stationedProvinceId: armyMovePickerP1,
        regimentUnitIds: const [],
        isHomeArmy: false,
      ),
    ],
    tileKeysByRegionAndProvince: const {},
  ),
  players: [
    Player(
      id: armyMovePickerGp,
      displayName: 'T',
      isHuman: true,
      capitalProvinceId: armyMovePickerCap,
    ),
  ],
);

MapTopology armyMovePickerTopologyFourProvinces() => MapTopology(
  nodes: const [
    TopologyNode(
      id: 'oldWorld|cap',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'oldWorld|p1',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'oldWorld|p2',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'newWorld|col',
      regionId: 'newWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|p2')],
);

MapTopology armyMovePickerTopologyThreeProvinces() => MapTopology(
  nodes: const [
    TopologyNode(
      id: 'oldWorld|cap',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'oldWorld|p1',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'oldWorld|p2',
      regionId: 'oldWorld',
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [TopologyEdge(id1: 'oldWorld|p1', id2: 'oldWorld|p2')],
);

const armyMovePickerEmptyTopology = MapTopology(nodes: [], edges: []);

Army armyMovePickerFieldArmy(Game game) => game.worldState.armies.first;
