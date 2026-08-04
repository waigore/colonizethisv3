// Shared fixtures for ship_reveal_movement_test (Refs #4252 slice C).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const shipRevealMovementNw = 'newWorld';
const shipRevealMovementOw = 'oldWorld';

MapTopology shipRevealCoastalInlandTopology({
  required String regionId,
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: 'p1',
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'p2',
        regionId: regionId,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'sea1',
        regionId: regionId,
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: 'sea2',
        regionId: regionId,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: const [
      TopologyEdge(id1: 'p1', id2: 'sea2'),
      TopologyEdge(id1: 'p2', id2: 'sea2'),
      TopologyEdge(id1: 'sea1', id2: 'sea2'),
    ],
  );
}

Game shipRevealCoastalInlandGame({
  required String id,
  required String regionId,
  required String provinceP1,
  required String provinceP2,
  required String p1CoastalTile,
  required String p1InlandTile,
  required String p2CoastalTile,
  required String sea2Bucket,
  required String sea2WaterA,
  required String sea2WaterB,
  required String fleetId,
}) {
  return Game(
    id: id,
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.movement, turnNumber: 0),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
      fleets: [
        Fleet(
          id: fleetId,
          ownerId: 'gp1',
          seaZoneId: 'sea1',
          regionId: regionId,
          shipTypeIds: ['carrack'],
        ),
      ],
      tileKeysByRegionAndProvince: {
        regionId: {
          provinceP1: [p1CoastalTile, p1InlandTile],
          provinceP2: [p2CoastalTile],
          sea2Bucket: [sea2WaterA, sea2WaterB],
        },
      },
      playerVisibilityByTile: const {'gp1': {}},
    ),
    players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
  );
}

MapTopology shipRevealRegionScopedTopology() {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: 'p1',
        regionId: shipRevealMovementNw,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'sea1',
        regionId: shipRevealMovementNw,
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: 'sea2',
        regionId: shipRevealMovementNw,
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: 'p1',
        regionId: shipRevealMovementOw,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'sea2',
        regionId: shipRevealMovementOw,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: const [
      TopologyEdge(id1: 'p1', id2: 'sea2'),
      TopologyEdge(id1: 'sea1', id2: 'sea2'),
    ],
  );
}

Game shipRevealRegionScopedGame({
  required String nwProvince,
  required String owProvince,
  required String nwCoastalTile,
  required String owTile,
  required String nwSea2,
  required String nwSea2Tile,
}) {
  return Game(
    id: 'g2',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.movement, turnNumber: 0),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
      fleets: [
        Fleet(
          id: 'f2',
          ownerId: 'gp1',
          seaZoneId: 'sea1',
          regionId: shipRevealMovementNw,
          shipTypeIds: ['carrack'],
        ),
      ],
      tileKeysByRegionAndProvince: {
        shipRevealMovementOw: {
          owProvince: [owTile],
        },
        shipRevealMovementNw: {
          nwProvince: [nwCoastalTile],
          nwSea2: [nwSea2Tile],
        },
      },
      playerVisibilityByTile: const {'gp1': {}},
    ),
    players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
  );
}

MapTopology shipRevealSequentialFleetTopology({
  required String homePort,
  required String seaA,
  required String seaB,
}) {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: homePort,
        regionId: shipRevealMovementOw,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: seaA,
        regionId: shipRevealMovementOw,
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: seaB,
        regionId: shipRevealMovementOw,
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [
      TopologyEdge(id1: homePort, id2: seaA),
      TopologyEdge(id1: seaA, id2: seaB),
    ],
  );
}

Game shipRevealSequentialFleetGame({
  required String homePort,
  required String seaA,
  required String seaB,
}) {
  return Game(
    id: 'gSequentialFleetMoves',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.movement, turnNumber: 0),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
      fleets: [
        Fleet(
          id: homeFleetIdFor('gp1'),
          ownerId: 'gp1',
          inPortAtProvinceId: homePort,
          regionId: shipRevealMovementOw,
          shipTypeIds: const ['home-ship'],
        ),
        Fleet(
          id: 'fDock',
          ownerId: 'gp1',
          seaZoneId: seaA,
          regionId: shipRevealMovementOw,
          shipTypeIds: const ['dock-ship'],
        ),
        Fleet(
          id: 'fMove',
          ownerId: 'gp1',
          seaZoneId: seaA,
          regionId: shipRevealMovementOw,
          shipTypeIds: const ['move-ship'],
        ),
      ],
      tileKeysByRegionAndProvince: {
        shipRevealMovementOw: {
          homePort: ['$homePort|0|0'],
          seaA: ['$seaA|0|0'],
          seaB: ['$seaB|0|0'],
        },
      },
      playerVisibilityByTile: const {'gp1': {}},
    ),
    players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: true)],
  );
}
