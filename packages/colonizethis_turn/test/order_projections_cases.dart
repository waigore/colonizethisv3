// Shared fixtures for order_projections_test (Refs #4168 slice B).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const String orderProjectionsLumberRecipeId = 'lumber_from_timber';

const MapTopology orderProjectionsSingleProvinceTopology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'P1',
      regionId: kRegionOldWorld,
      type: TopologyNodeType.province,
    ),
  ],
  edges: [],
);

const MapTopology orderProjectionsTwoProvinceTopology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'P1',
      regionId: kRegionOldWorld,
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'P2',
      regionId: kRegionOldWorld,
      type: TopologyNodeType.province,
    ),
  ],
  edges: [
    TopologyEdge(id1: 'P1', id2: 'P2'),
  ],
);

const MapTopology orderProjectionsCrossRegionTopology = MapTopology(
  nodes: [
    TopologyNode(
      id: 'P1',
      regionId: kRegionOldWorld,
      type: TopologyNodeType.province,
    ),
    TopologyNode(
      id: 'N1',
      regionId: kRegionNewWorld,
      type: TopologyNodeType.province,
    ),
  ],
  edges: [],
);

Game orderProjectionsEmptyGame() {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'p1', displayName: 'A', isHuman: true),
    ],
  );
}

Game orderProjectionsSingleProvinceGame({
  List<Unit> units = const [],
  Player? player,
}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: 'P1',
            regionId: kRegionOldWorld,
            ownerId: 'p1',
          ),
        ],
        units: units,
      ),
      newWorld: const RegionData(),
    ),
    players: [
      player ?? const Player(id: 'p1', displayName: 'A', isHuman: true),
    ],
  );
}

Game orderProjectionsTwoProvinceMoveGame() {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: const [
          Province(
            id: 'P1',
            regionId: kRegionOldWorld,
            ownerId: 'p1',
          ),
          Province(
            id: 'P2',
            regionId: kRegionOldWorld,
            ownerId: 'p1',
          ),
        ],
        units: [
          Unit(
            id: 'u1',
            type: 'Regiment',
            ownerId: 'p1',
            locationProvinceId: '$kRegionOldWorld|P1',
          ),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'p1', displayName: 'A', isHuman: true),
    ],
  );
}

Orders orderProjectionsMoveToP2Orders() {
  return Orders(
    moveOrdersByPlayerId: {
      'p1': const [
        MoveOrder(
          unitId: 'u1',
          destinationTileKey: '$kRegionOldWorld|P2|0|0',
        ),
      ],
    },
  );
}

Game orderProjectionsCrossRegionNwUnitGame() {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: '$kRegionOldWorld|P1',
            regionId: kRegionOldWorld,
            ownerId: 'p1',
          ),
        ],
        units: [],
      ),
      newWorld: RegionData(
        provinces: [
          Province(
            id: '$kRegionNewWorld|N1',
            regionId: kRegionNewWorld,
            ownerId: 'p1',
          ),
        ],
        units: [
          Unit(
            id: 'u1',
            type: 'Regiment',
            ownerId: 'p1',
            locationProvinceId: '$kRegionNewWorld|N1',
          ),
        ],
      ),
    ),
    players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
  );
}
