import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const _ow = 'oldWorld';
const _p1 = 'oldWorld|a';
const _p2 = 'oldWorld|b';

MapTopology _twoProvinceTopology({bool adjacent = true}) => MapTopology(
  nodes: const [
    TopologyNode(id: _p1, regionId: _ow, type: TopologyNodeType.province),
    TopologyNode(id: _p2, regionId: _ow, type: TopologyNodeType.province),
  ],
  edges: adjacent
      ? const [TopologyEdge(id1: _p1, id2: _p2)]
      : const <TopologyEdge>[],
);

Game _gameWithSingleArmy({
  String playerId = 'gp1',
  String armyId = 'afield',
  String stationedProvinceId = _p1,
  String otherProvinceId = _p2,
  bool isHomeArmy = false,
}) => Game(
  id: 'g',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: [
        Province(id: stationedProvinceId, regionId: _ow, ownerId: playerId),
        Province(id: otherProvinceId, regionId: _ow, ownerId: playerId),
      ],
      units: [
        Unit(
          id: 'r1',
          type: 'musketeers',
          ownerId: playerId,
          locationProvinceId: stationedProvinceId,
        ),
      ],
    ),
    newWorld: const RegionData(),
    armies: [
      Army(
        id: armyId,
        ownerId: playerId,
        regionId: _ow,
        stationedProvinceId: stationedProvinceId,
        regimentUnitIds: const ['r1'],
        isHomeArmy: isHomeArmy,
      ),
    ],
  ),
  players: [
    Player(
      id: playerId,
      displayName: 'P',
      isHuman: true,
      capitalProvinceId: stationedProvinceId,
    ),
  ],
);

TurnTracePhaseTrace _runMovementForOrders({
  required Game game,
  required MapTopology topology,
  required Orders orders,
  TurnTraceRuntime? runtime,
}) {
  final traces = <TurnTracePhaseTrace>[];
  resolveTurnForGameWithConfig(
    game: game,
    config: TurnResolverConfig(
      topology: topology,
      orders: orders,
      onTurnTracePhase: traces.add,
      turnTraceRuntime: runtime,
    ),
  );
  return traces.firstWhere((t) => t.phaseId == TurnPhase.movement.name);
}

List<TurnTraceOrderEvent> _armyEventsFor(
  TurnTracePhaseTrace trace,
  String orderId,
) => trace.orderEvents.where((e) => e.orderId == orderId).toList();

void main() {
  suppressLogsForTests();

  group('TurnTraceRuntime army move payloads', () {
    test('records army_move_applied event with regionId and destination', () {
      final runtime = TurnTraceRuntime();
      runtime.handleArmyMoveOrderTrace(
        playerId: 'gp1',
        order: const ArmyMoveOrder(
          armyId: 'afield',
          destinationProvinceId: _p2,
        ),
        applied: true,
        regionId: _ow,
        destinationProvinceId: _p2,
      );

      final event = runtime.snapshotPhaseOrderEvents().single;
      expect(event.eventType, 'army_move_applied');
      expect(event.orderId, 'army_move:gp1:afield');
      expect(event.payload?['destinationProvinceId'], _p2);
      expect(event.payload?['regionId'], _ow);
      expect(event.payload?.containsKey('ignoreReason'), isFalse);
    });

    test('records army_move_ignored event with ignoreReason', () {
      final runtime = TurnTraceRuntime();
      runtime.handleArmyMoveOrderTrace(
        playerId: 'gp1',
        order: const ArmyMoveOrder(
          armyId: 'afield',
          destinationProvinceId: _p2,
        ),
        applied: false,
        ignoreReason: 'army_not_found',
      );

      final event = runtime.snapshotPhaseOrderEvents().single;
      expect(event.eventType, 'army_move_ignored');
      expect(event.orderId, 'army_move:gp1:afield');
      expect(event.payload?['ignoreReason'], 'army_not_found');
      expect(event.payload?['destinationProvinceId'], _p2);
      expect(event.payload?.containsKey('regionId'), isFalse);
    });
  });

  group('runMovementPhase army move trace events', () {
    test('emits army_move_applied for adjacent same-region move', () {
      final movementTrace = _runMovementForOrders(
        game: _gameWithSingleArmy(),
        topology: _twoProvinceTopology(),
        orders: const Orders(
          armyMoveOrdersByPlayerId: {
            'gp1': [
              ArmyMoveOrder(armyId: 'afield', destinationProvinceId: _p2),
            ],
          },
        ),
        runtime: TurnTraceRuntime(),
      );

      final events = _armyEventsFor(movementTrace, 'army_move:gp1:afield');
      expect(events, hasLength(1));
      expect(events.single.eventType, 'army_move_applied');
      expect(events.single.payload?['regionId'], _ow);
      expect(events.single.payload?['destinationProvinceId'], _p2);
    });

    test('emits exactly one army_move_ignored for missing army', () {
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: _p1, regionId: _ow, ownerId: 'gp1'),
              Province(id: _p2, regionId: _ow, ownerId: 'gp1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'gp1', displayName: 'P', isHuman: true)],
      );

      final movementTrace = _runMovementForOrders(
        game: game,
        topology: _twoProvinceTopology(),
        orders: const Orders(
          armyMoveOrdersByPlayerId: {
            'gp1': [
              ArmyMoveOrder(armyId: 'ghost_army', destinationProvinceId: _p2),
            ],
          },
        ),
        runtime: TurnTraceRuntime(),
      );

      final events = _armyEventsFor(movementTrace, 'army_move:gp1:ghost_army');
      expect(events, hasLength(1));
      expect(events.single.eventType, 'army_move_ignored');
      expect(events.single.payload?['ignoreReason'], 'army_not_found');
    });

    test('emits army_move_ignored with home_army_locked reason once', () {
      final hid = homeArmyIdFor('gp1');
      final movementTrace = _runMovementForOrders(
        game: _gameWithSingleArmy(armyId: hid, isHomeArmy: true),
        topology: _twoProvinceTopology(),
        orders: Orders(
          armyMoveOrdersByPlayerId: {
            'gp1': [ArmyMoveOrder(armyId: hid, destinationProvinceId: _p2)],
          },
        ),
        runtime: TurnTraceRuntime(),
      );

      final events = _armyEventsFor(movementTrace, 'army_move:gp1:$hid');
      expect(events, hasLength(1));
      expect(events.single.eventType, 'army_move_ignored');
      expect(events.single.payload?['ignoreReason'], 'home_army_locked');
    });

    test('emits army_move_ignored with invalid_adjacency reason', () {
      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: _p1, regionId: _ow, ownerId: 'gp1'),
              Province(id: _p2, regionId: _ow, ownerId: 'gp2'),
            ],
            units: [
              Unit(
                id: 'r1',
                type: 'musketeers',
                ownerId: 'gp1',
                locationProvinceId: _p1,
              ),
            ],
          ),
          newWorld: const RegionData(),
          armies: [
            Army(
              id: 'afield',
              ownerId: 'gp1',
              regionId: _ow,
              stationedProvinceId: _p1,
              regimentUnitIds: const ['r1'],
              isHomeArmy: false,
            ),
          ],
        ),
        players: const [
          Player(id: 'gp1', displayName: 'P1', isHuman: true),
          Player(id: 'gp2', displayName: 'P2', isHuman: false),
        ],
      );

      final movementTrace = _runMovementForOrders(
        game: game,
        topology: _twoProvinceTopology(adjacent: false),
        orders: const Orders(
          armyMoveOrdersByPlayerId: {
            'gp1': [
              ArmyMoveOrder(armyId: 'afield', destinationProvinceId: _p2),
            ],
          },
        ),
        runtime: TurnTraceRuntime(),
      );

      final events = _armyEventsFor(movementTrace, 'army_move:gp1:afield');
      expect(events, hasLength(1));
      expect(events.single.eventType, 'army_move_ignored');
      expect(events.single.payload?['ignoreReason'], 'invalid_adjacency');
      expect(events.single.payload?['regionId'], _ow);
    });

    test('does not emit army move events when runtime is not provided', () {
      final movementTrace = _runMovementForOrders(
        game: _gameWithSingleArmy(),
        topology: _twoProvinceTopology(),
        orders: const Orders(
          armyMoveOrdersByPlayerId: {
            'gp1': [
              ArmyMoveOrder(armyId: 'afield', destinationProvinceId: _p2),
            ],
          },
        ),
      );

      expect(movementTrace.orderEvents, isEmpty);
    });
  });
}
