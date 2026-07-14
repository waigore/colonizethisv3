// Shared OrderEngine civilian move XOR work scenario fixtures (Refs #3949 / #3971).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../common/game_graphs.dart';

const ocmxwRegionId = 'oldWorld';
const ocmxwP1 = '$ocmxwRegionId|P1';
const ocmxwP2 = '$ocmxwRegionId|P2';
const ocmxwTileA = '$ocmxwP1|0|0';
const ocmxwTileB = '$ocmxwP2|0|0';
const ocmxwTileB2 = '$ocmxwP2|1|0';
const ocmxwExploreTargetTile = '$ocmxwRegionId|P2|0|0';

// dart format off
MapTopology ocmxwTwoProvinceTopology() => const MapTopology(
  nodes: [
    TopologyNode(id: 'P1', regionId: ocmxwRegionId, type: TopologyNodeType.province),
    TopologyNode(id: 'P2', regionId: ocmxwRegionId, type: TopologyNodeType.province),
  ],
  edges: [TopologyEdge(id1: 'P1', id2: 'P2')],
);
// dart format on

Game ocmxwExplorerOnP1Game() => ordersOwRegionGame(
  id: 'g',
  turnNumber: 1,
  players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
  oldWorld: RegionData(
    provinces: [
      Province(id: ocmxwP1, regionId: ocmxwRegionId, ownerId: 'p1'),
      Province(id: ocmxwP2, regionId: ocmxwRegionId, ownerId: 'p1'),
    ],
    units: [
      Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
        ownerId: 'p1',
        locationProvinceId: ocmxwP1,
        tileKey: ocmxwTileA,
      ),
    ],
  ),
  tileKeysByRegionAndProvince: const {
    ocmxwRegionId: {
      ocmxwP1: [ocmxwTileA],
      ocmxwP2: [ocmxwTileB, ocmxwTileB2],
    },
  },
  playerVisibilityByTile: const {
    'p1': {ocmxwTileA: 'fullyVisible', ocmxwTileB: 'fullyVisible'},
  },
);
