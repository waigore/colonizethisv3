// Compact order-engine naval/build validation fixtures + shorthands (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const _nvOw = 'oldWorld';
const _nvNw = 'newWorld';
const _nvP1 = 'p1';
const _nvP2 = 'p2';
String _nvTile(String region, String localProv) => '$region|$localProv|0|0';

MapTopology _nvCrossRegionTopology() => const MapTopology(
  nodes: [
    TopologyNode(id: 'P1', regionId: _nvOw, type: TopologyNodeType.province),
    TopologyNode(id: 'P2', regionId: _nvNw, type: TopologyNodeType.province),
  ],
  edges: [],
);

Game _nvCrossRegionGame({required String unitType, required String nwOwnerId}) {
  return Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: RegionData(
        provinces: [Province(id: '$_nvOw|P1', regionId: _nvOw, ownerId: _nvP1)],
        units: [
          Unit(
            id: 'u1',
            type: unitType,
            ownerId: _nvP1,
            locationProvinceId: '$_nvOw|P1',
          ),
        ],
      ),
      newWorld: RegionData(
        provinces: [
          Province(id: '$_nvNw|P2', regionId: _nvNw, ownerId: nwOwnerId),
        ],
      ),
      playerVisibilityByTile: {
        _nvP1: {
          _nvTile(_nvOw, 'P1'): 'fullyVisible',
          _nvTile(_nvNw, 'P2'): 'fullyVisible',
        },
      },
    ),
    players: const [
      Player(id: _nvP1, displayName: 'P1', isHuman: true),
      Player(id: _nvP2, displayName: 'P2', isHuman: true),
    ],
  );
}

void nvExpectCrossRegionMove({
  required String unitType,
  required String nwOwnerId,
  required OrderValidationStatus expectedStatus,
}) {
  final engine = OrderEngine()
    ..addMoveOrder(
      _nvP1,
      MoveOrder(unitId: 'u1', destinationTileKey: _nvTile(_nvNw, 'P2')),
    );
  final results = engine.validatePlayerOrdersWithContext(
    _nvCrossRegionGame(unitType: unitType, nwOwnerId: nwOwnerId),
    _nvCrossRegionTopology(),
    _nvP1,
  );
  expect(results.single.status, expectedStatus);
}

void nvExpectInvalidWorkTargetRejected() {
  const tileKey = 'oldWorld|P1|0|0';
  final engine = OrderEngine()
    ..addWorkOrder(
      _nvP1,
      WorkOrder(unitId: 'u1', target: 'unknown_target', targetTileKey: tileKey),
    );
  final results = engine.validatePlayerOrdersWithContext(
    Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(
          provinces: [
            Province(id: '$_nvOw|P1', regionId: _nvOw, ownerId: _nvP1),
          ],
          units: [
            Unit(
              id: 'u1',
              type: kUnitTypeBuilder,
              ownerId: _nvP1,
              locationProvinceId: '$_nvOw|P1',
              tileKey: tileKey,
            ),
          ],
        ),
        newWorld: const RegionData(),
        playerVisibilityByTile: {
          _nvP1: {tileKey: 'fullyVisible'},
        },
      ),
      players: const [Player(id: _nvP1, displayName: 'P1', isHuman: true)],
    ),
    const MapTopology(
      nodes: [
        TopologyNode(
          id: 'P1',
          regionId: _nvOw,
          type: TopologyNodeType.province,
        ),
      ],
      edges: [],
    ),
    _nvP1,
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('Invalid work target'));
}

void nvExpectInitialOrdersCopyDistinct() {
  final engine = OrderEngine(
    initialOrders: Orders(
      moveOrdersByPlayerId: {
        _nvP1: [
          const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
        ],
      },
    ),
  );
  final orders1 = engine.orders;
  final orders2 = engine.orders;
  expect(orders1.moveOrdersByPlayerId[_nvP1]!.length, 1);
  expect(orders2.moveOrdersByPlayerId[_nvP1]!.length, 1);
  expect(
    identical(orders1.moveOrdersByPlayerId, orders2.moveOrdersByPlayerId),
    isFalse,
  );
  expect(
    identical(
      orders1.moveOrdersByPlayerId[_nvP1],
      orders2.moveOrdersByPlayerId[_nvP1],
    ),
    isFalse,
  );
}

void nvExpectNavalMoveFleetNotFoundRejected() {
  final engine = OrderEngine()
    ..addNavalMoveOrder(
      _nvP1,
      const NavalMoveOrder(
        fleetId: 'nonexistent_fleet',
        destinationSeaZoneId: 'sea2',
      ),
    );
  final results = engine.validatePlayerOrdersWithContext(
    Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
        fleets: const [],
      ),
      players: const [Player(id: _nvP1, displayName: 'P1', isHuman: true)],
    ),
    MapTopology(
      nodes: const [
        TopologyNode(
          id: 'P1',
          regionId: _nvOw,
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: 'sea1',
          regionId: _nvOw,
          type: TopologyNodeType.seaZone,
        ),
        TopologyNode(
          id: 'sea2',
          regionId: _nvOw,
          type: TopologyNodeType.seaZone,
        ),
      ],
      edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
    ),
    _nvP1,
  );
  expect(results.single.status, OrderValidationStatus.rejected);
  expect(results.single.reason, contains('Fleet not found'));
}

void nvExpectBlockadeMission({
  required RelationState relationState,
  required OrderValidationStatus expectedStatus,
  String? reasonContains,
}) {
  final engine = OrderEngine();
  final result = engine.addNavalMissionOrderWithContext(
    Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: RegionData(
          provinces: [
            Province(id: '$_nvOw|P1', regionId: _nvOw, ownerId: _nvP1),
            Province(id: '$_nvOw|P2', regionId: _nvOw, ownerId: _nvP2),
          ],
        ),
        newWorld: const RegionData(),
        fleets: [
          Fleet(
            id: 'f1',
            ownerId: _nvP1,
            seaZoneId: 'sea1',
            regionId: _nvOw,
            shipTypeIds: const ['carrack'],
          ),
        ],
      ),
      players: const [
        Player(id: _nvP1, displayName: 'P1', isHuman: true),
        Player(id: _nvP2, displayName: 'P2', isHuman: true),
      ],
      diplomacyRelations: [
        DiplomacyRelation(
          factionId1: _nvP1,
          factionId2: _nvP2,
          state: relationState,
        ),
      ],
    ),
    const MapTopology(
      nodes: [
        TopologyNode(
          id: 'sea1',
          regionId: _nvOw,
          type: TopologyNodeType.seaZone,
        ),
      ],
      edges: [],
    ),
    _nvP1,
    NavalMissionOrder(
      fleetId: 'f1',
      mission: FleetMission.blockade.name,
      targetProvinceId: '$_nvOw|P2',
    ),
  );
  expect(result.status, expectedStatus);
  if (reasonContains != null) {
    expect(result.reason, contains(reasonContains));
  }
}
