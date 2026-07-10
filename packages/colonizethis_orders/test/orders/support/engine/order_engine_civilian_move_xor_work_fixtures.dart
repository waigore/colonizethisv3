// Shared OrderEngine civilian move XOR work scenario fixtures (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const ocmxwRegionId = 'oldWorld';
const ocmxwP1 = '$ocmxwRegionId|P1';
const ocmxwP2 = '$ocmxwRegionId|P2';
const ocmxwTileA = '$ocmxwP1|0|0';
const ocmxwTileB = '$ocmxwP2|0|0';
const ocmxwTileB2 = '$ocmxwP2|1|0';
const ocmxwExploreTargetTile = '$ocmxwRegionId|P2|0|0';

MapTopology ocmxwTwoProvinceTopology() => MapTopology(
  nodes: const [
    TopologyNode(
      id: 'P1',
      regionId: ocmxwRegionId,
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'P2',
      regionId: ocmxwRegionId,
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
);

Game ocmxwExplorerOnP1Game() => Game(
  id: 'g',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
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
    newWorld: const RegionData(),
    tileKeysByRegionAndProvince: {
      ocmxwRegionId: {
        ocmxwP1: [ocmxwTileA],
        ocmxwP2: [ocmxwTileB, ocmxwTileB2],
      },
    },
    playerVisibilityByTile: const {
      'p1': {ocmxwTileA: 'fullyVisible', ocmxwTileB: 'fullyVisible'},
    },
  ),
  players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
);
