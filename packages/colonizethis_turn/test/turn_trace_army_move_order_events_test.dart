import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/turn_trace_order_events_test_support.dart';
import 'turn_trace_army_move_order_events_cases.dart';

void main() {
  suppressLogsForTests();

  group('TurnTraceRuntime army move payloads', () {
    test('records army_move_applied event with regionId and destination', () {
      final runtime = TurnTraceRuntime();
      runtime.handleArmyMoveOrderTrace(
        playerId: 'gp1',
        order: const ArmyMoveOrder(
          armyId: 'afield',
          destinationProvinceId: armyMoveTraceP2,
        ),
        applied: true,
        regionId: armyMoveTraceOw,
        destinationProvinceId: armyMoveTraceP2,
      );

      final event = runtime.snapshotPhaseOrderEvents().single;
      expect(event.eventType, 'army_move_applied');
      expect(event.orderId, 'army_move:gp1:afield');
      expect(event.payload?['destinationProvinceId'], armyMoveTraceP2);
      expect(event.payload?['regionId'], armyMoveTraceOw);
      expect(event.payload?.containsKey('ignoreReason'), isFalse);
    });

    test('records army_move_ignored event with ignoreReason', () {
      final runtime = TurnTraceRuntime();
      runtime.handleArmyMoveOrderTrace(
        playerId: 'gp1',
        order: const ArmyMoveOrder(
          armyId: 'afield',
          destinationProvinceId: armyMoveTraceP2,
        ),
        applied: false,
        ignoreReason: 'army_not_found',
      );

      final event = runtime.snapshotPhaseOrderEvents().single;
      expect(event.eventType, 'army_move_ignored');
      expect(event.orderId, 'army_move:gp1:afield');
      expect(event.payload?['ignoreReason'], 'army_not_found');
      expect(event.payload?['destinationProvinceId'], armyMoveTraceP2);
      expect(event.payload?.containsKey('regionId'), isFalse);
    });
  });

  group('runMovementPhase army move trace events', () {
    test('emits army_move_applied for adjacent same-region move', () {
      final movementTrace = runMovementTraceForOrders(
        game: armyMoveTraceGameWithSingleArmy(),
        topology: armyMoveTraceTwoProvinceTopology(),
        orders: const Orders(
          armyMoveOrdersByPlayerId: {
            'gp1': [
              ArmyMoveOrder(
                armyId: 'afield',
                destinationProvinceId: armyMoveTraceP2,
              ),
            ],
          },
        ),
        runtime: TurnTraceRuntime(),
      );

      final events = orderEventsFor(movementTrace, 'army_move:gp1:afield');
      expect(events, hasLength(1));
      expect(events.single.eventType, 'army_move_applied');
      expect(events.single.payload?['regionId'], armyMoveTraceOw);
      expect(events.single.payload?['destinationProvinceId'], armyMoveTraceP2);
    });

    test('emits exactly one army_move_ignored for missing army', () {
      final movementTrace = runMovementTraceForOrders(
        game: armyMoveTraceGhostArmyGame(),
        topology: armyMoveTraceTwoProvinceTopology(),
        orders: const Orders(
          armyMoveOrdersByPlayerId: {
            'gp1': [
              ArmyMoveOrder(
                armyId: 'ghost_army',
                destinationProvinceId: armyMoveTraceP2,
              ),
            ],
          },
        ),
        runtime: TurnTraceRuntime(),
      );

      final events = orderEventsFor(movementTrace, 'army_move:gp1:ghost_army');
      expect(events, hasLength(1));
      expect(events.single.eventType, 'army_move_ignored');
      expect(events.single.payload?['ignoreReason'], 'army_not_found');
    });

    test('emits army_move_ignored with home_army_locked reason once', () {
      final hid = homeArmyIdFor('gp1');
      final movementTrace = runMovementTraceForOrders(
        game: armyMoveTraceGameWithSingleArmy(armyId: hid, isHomeArmy: true),
        topology: armyMoveTraceTwoProvinceTopology(),
        orders: Orders(
          armyMoveOrdersByPlayerId: {
            'gp1': [
              ArmyMoveOrder(armyId: hid, destinationProvinceId: armyMoveTraceP2),
            ],
          },
        ),
        runtime: TurnTraceRuntime(),
      );

      final events = orderEventsFor(movementTrace, 'army_move:gp1:$hid');
      expect(events, hasLength(1));
      expect(events.single.eventType, 'army_move_ignored');
      expect(events.single.payload?['ignoreReason'], 'home_army_locked');
    });

    test('emits army_move_ignored with invalid_adjacency reason', () {
      final movementTrace = runMovementTraceForOrders(
        game: armyMoveTraceInvalidAdjacencyGame(),
        topology: armyMoveTraceTwoProvinceTopology(adjacent: false),
        orders: const Orders(
          armyMoveOrdersByPlayerId: {
            'gp1': [
              ArmyMoveOrder(
                armyId: 'afield',
                destinationProvinceId: armyMoveTraceP2,
              ),
            ],
          },
        ),
        runtime: TurnTraceRuntime(),
      );

      final events = orderEventsFor(movementTrace, 'army_move:gp1:afield');
      expect(events, hasLength(1));
      expect(events.single.eventType, 'army_move_ignored');
      expect(events.single.payload?['ignoreReason'], 'invalid_adjacency');
      expect(events.single.payload?['regionId'], armyMoveTraceOw);
    });

    test('does not emit army move events when runtime is not provided', () {
      final movementTrace = runMovementTraceForOrders(
        game: armyMoveTraceGameWithSingleArmy(),
        topology: armyMoveTraceTwoProvinceTopology(),
        orders: const Orders(
          armyMoveOrdersByPlayerId: {
            'gp1': [
              ArmyMoveOrder(
                armyId: 'afield',
                destinationProvinceId: armyMoveTraceP2,
              ),
            ],
          },
        ),
      );

      expect(movementTrace.orderEvents, isEmpty);
    });
  });
}
