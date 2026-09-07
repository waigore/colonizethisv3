// Shared fixtures for turn_resolution_snapshot_test (Refs #4252 slice C).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

const turnSnapshotOw = 'oldWorld';

MapTopology turnSnapshotThreeProvinceTopology() {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: 'P1',
        regionId: turnSnapshotOw,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'P2',
        regionId: turnSnapshotOw,
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'P3',
        regionId: turnSnapshotOw,
        type: TopologyNodeType.province,
      ),
    ],
    edges: [
      TopologyEdge(id1: 'P1', id2: 'P2'),
      TopologyEdge(id1: 'P2', id2: 'P3'),
    ],
  );
}

Game turnSnapshotExtractionMovementGame() {
  return Game(
    id: 'char-turn',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$turnSnapshotOw|P1', regionId: turnSnapshotOw, ownerId: 'p1'),
          Province(id: '$turnSnapshotOw|P2', regionId: turnSnapshotOw, ownerId: 'p1'),
          Province(id: '$turnSnapshotOw|P3', regionId: turnSnapshotOw, ownerId: 'p2'),
        ],
        units: [
          Unit(
            id: 'inf1',
            type: kUnitTypeExplorer,
            ownerId: 'p1',
            locationProvinceId: '$turnSnapshotOw|P1',
            medals: 2,
          ),
          Unit(
            id: 'def1',
            type: 'peasant_levies',
            ownerId: 'p2',
            locationProvinceId: '$turnSnapshotOw|P3',
          ),
        ],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        turnSnapshotOw: {
          '$turnSnapshotOw|P1': ['$turnSnapshotOw|P1|0|0'],
          '$turnSnapshotOw|P2': ['$turnSnapshotOw|P2|0|0'],
          '$turnSnapshotOw|P3': ['$turnSnapshotOw|P3|0|0'],
        },
      },
      playerVisibilityByTile: {
        'p1': {
          '$turnSnapshotOw|P1|0|0': 'fullyVisible',
          '$turnSnapshotOw|P2|0|0': 'fullyVisible',
          '$turnSnapshotOw|P3|0|0': 'fullyVisible',
        },
      },
    ),
    players: [
      Player(
        id: 'p1',
        displayName: 'Attacker',
        isHuman: true,
        stockpile: const Stockpile(quantities: {'grain': 10}),
        workerPool: const WorkerPool(peasants: 5),
        treasury: 1000,
      ),
      Player(
        id: 'p2',
        displayName: 'Defender',
        isHuman: false,
        stockpile: const Stockpile(quantities: {'grain': 5}),
        workerPool: const WorkerPool(peasants: 2),
        treasury: 500,
      ),
    ],
  );
}

Orders turnSnapshotExtractionMovementOrders() {
  return Orders(
    moveOrdersByPlayerId: {
      'p1': [
        MoveOrder(
          unitId: 'inf1',
          destinationTileKey: '$turnSnapshotOw|P2|0|0',
        ),
      ],
    },
  );
}

Map<String, Map<String, int>> turnSnapshotExtractionByPlayer() {
  return {
    'p1': {'grain': 3},
    'p2': {'grain': 1},
  };
}

MapTopology turnSnapshotEmptyTurnTopology() {
  return MapTopology(
    nodes: [
      TopologyNode(
        id: 'P1',
        regionId: turnSnapshotOw,
        type: TopologyNodeType.province,
      ),
    ],
    edges: [],
  );
}

Game turnSnapshotEmptyTurnGame() {
  return Game(
    id: 'empty-turn',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 5),
      oldWorld: RegionData(
        provinces: [
          Province(id: '$turnSnapshotOw|P1', regionId: turnSnapshotOw, ownerId: 'p1'),
        ],
      ),
      newWorld: const RegionData(),
    ),
    players: const [
      Player(id: 'p1', displayName: 'Solo', isHuman: true),
    ],
  );
}
