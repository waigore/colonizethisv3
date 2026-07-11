// Draft-work move exclusion fixtures (Refs #3949 wave 3 / #3971 wave 4).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const moveExcludesDraftWorkPlayerId = 'gp1';
const moveExcludesDraftWorkRegionId = 'oldWorld';
const moveExcludesDraftWorkP1 = '$moveExcludesDraftWorkRegionId|P1';
const moveExcludesDraftWorkP2 = '$moveExcludesDraftWorkRegionId|P2';
const moveExcludesDraftWorkTileA = '$moveExcludesDraftWorkP1|0|0';
const moveExcludesDraftWorkTileB = '$moveExcludesDraftWorkP2|0|0';

Game moveExcludesDraftWorkGame() => ordersOwRegionGame(
  id: 'g',
  turnNumber: 1,
  players: const [
    Player(
      id: moveExcludesDraftWorkPlayerId,
      displayName: 'GP',
      isHuman: false,
    ),
  ],
  oldWorld: RegionData(
    provinces: [
      Province(
        id: moveExcludesDraftWorkP1,
        regionId: moveExcludesDraftWorkRegionId,
        ownerId: moveExcludesDraftWorkPlayerId,
      ),
      Province(
        id: moveExcludesDraftWorkP2,
        regionId: moveExcludesDraftWorkRegionId,
        ownerId: moveExcludesDraftWorkPlayerId,
      ),
    ],
    units: [
      Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
        ownerId: moveExcludesDraftWorkPlayerId,
        locationProvinceId: moveExcludesDraftWorkP1,
        tileKey: moveExcludesDraftWorkTileA,
      ),
    ],
  ),
  tileKeysByRegionAndProvince: {
    moveExcludesDraftWorkRegionId: {
      moveExcludesDraftWorkP1: [moveExcludesDraftWorkTileA],
      moveExcludesDraftWorkP2: [moveExcludesDraftWorkTileB],
    },
  },
  playerVisibilityByTile: const {
    moveExcludesDraftWorkPlayerId: {
      moveExcludesDraftWorkTileA: 'fullyVisible',
      moveExcludesDraftWorkTileB: 'fullyVisible',
    },
  },
);

const moveExcludesDraftWorkTopology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'P1',
      regionId: moveExcludesDraftWorkRegionId,
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'P2',
      regionId: moveExcludesDraftWorkRegionId,
      type: TopologyNodeType.province,
    ),
  ],
  edges: [TopologyEdge(id1: 'P1', id2: 'P2')],
);

Orders moveExcludesDraftWorkOrders() => Orders(
  workOrdersByPlayerId: {
    moveExcludesDraftWorkPlayerId: [
      WorkOrder(
        unitId: 'u1',
        target: kWorkTargetExplore,
        targetTileKey: moveExcludesDraftWorkTileB,
      ),
    ],
  },
);
