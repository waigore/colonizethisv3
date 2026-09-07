// Sequential-fleet fixtures for ship_reveal_movement_test (Refs #4740 Slice C).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'ship_reveal_movement_cases.dart';

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
