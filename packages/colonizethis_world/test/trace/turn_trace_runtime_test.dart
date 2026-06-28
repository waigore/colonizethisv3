import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/trace/turn_trace_contracts.dart';
import 'package:colonizethis_world/src/trace/turn_trace_runtime.dart';
import 'package:colonizethis_test/test.dart';

/// Coverage uplift for `colonizethis_world` (Refs #3290 Phase 1 follow-up).
///
/// Exercises the per-phase order-event buffer in
/// `lib/src/trace/turn_trace_runtime.dart`. SPEC/program/logging/turn-resolution.md.
void main() {
  group('TurnTraceRuntime', () {
    late TurnTraceRuntime runtime;

    setUp(() => runtime = TurnTraceRuntime());

    test('snapshot is empty before any events', () {
      expect(runtime.snapshotPhaseOrderEvents(), isEmpty);
    });

    test('records civilian move applied/ignored with sequencing', () {
      runtime.handleCivilianMoveOrderTrace(
        playerId: 'p1',
        order: const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|p1|0|0'),
        applied: true,
      );
      runtime.handleCivilianMoveOrderTrace(
        playerId: 'p1',
        order: const MoveOrder(unitId: 'u2', destinationTileKey: 'oldWorld|p2|0|0'),
        applied: false,
        ignoreReason: 'owner_mismatch',
      );
      final events = runtime.snapshotPhaseOrderEvents();
      expect(events.map((e) => e.sequence), [0, 1]);
      expect(events[0].eventType, 'civilian_move_applied');
      expect(events[0].orderId, 'move:p1:u1');
      expect(events[1].eventType, 'civilian_move_ignored');
      expect(events[1].payload!['ignoreReason'], 'owner_mismatch');
    });

    test('records bundled work move with optional destination fields', () {
      runtime.handleBundledWorkMoveTrace(
        playerId: 'p1',
        order: const WorkOrder(
          unitId: 'u1',
          target: 'farm',
          targetTileKey: 'oldWorld|p1|0|0',
        ),
        applied: true,
        destinationProvinceId: 'oldWorld|p1',
        destinationTileKey: 'oldWorld|p1|0|0',
      );
      final event = runtime.snapshotPhaseOrderEvents().single;
      expect(event.eventType, 'bundled_work_move_applied');
      expect(event.payload!['destinationProvinceId'], 'oldWorld|p1');
      expect(event.payload!['destinationTileKey'], 'oldWorld|p1|0|0');
    });

    test('records army move with explicit and fallback destinations', () {
      runtime.handleArmyMoveOrderTrace(
        playerId: 'p1',
        order: const ArmyMoveOrder(
          armyId: 'a1',
          destinationProvinceId: 'oldWorld|p2',
        ),
        applied: true,
        regionId: 'oldWorld',
        destinationProvinceId: 'oldWorld|p2',
      );
      runtime.handleArmyMoveOrderTrace(
        playerId: 'p1',
        order: const ArmyMoveOrder(
          armyId: 'a2',
          destinationProvinceId: 'oldWorld|p9',
        ),
        applied: false,
        ignoreReason: 'invalid_adjacency',
      );
      final events = runtime.snapshotPhaseOrderEvents();
      expect(events[0].eventType, 'army_move_applied');
      expect(events[0].payload!['regionId'], 'oldWorld');
      // Falls back to the order's destination when none is supplied.
      expect(events[1].payload!['destinationProvinceId'], 'oldWorld|p9');
      expect(events[1].payload!.containsKey('regionId'), isFalse);
      expect(events[1].payload!['ignoreReason'], 'invalid_adjacency');
    });

    test('records work-order applied/skipped', () {
      runtime.handleWorkOrderTrace(
        playerId: 'p1',
        order: const WorkOrder(
          unitId: 'u1',
          target: 'mine',
          targetTileKey: 'oldWorld|p1|0|0',
        ),
        applied: false,
        ignoreReason: 'not_prospectable',
      );
      final event = runtime.snapshotPhaseOrderEvents().single;
      expect(event.eventType, 'work_order_skipped');
      expect(event.orderId, 'work:p1:u1:mine');
      expect(event.payload!['ignoreReason'], 'not_prospectable');
    });

    test('clear resets the buffer and the sequence counter', () {
      runtime.handleWorkOrderTrace(
        playerId: 'p1',
        order: const WorkOrder(unitId: 'u1', target: 't', targetTileKey: 'k'),
        applied: true,
      );
      runtime.clearPhaseOrderEvents();
      expect(runtime.snapshotPhaseOrderEvents(), isEmpty);
      runtime.handleWorkOrderTrace(
        playerId: 'p1',
        order: const WorkOrder(unitId: 'u2', target: 't', targetTileKey: 'k'),
        applied: true,
      );
      expect(runtime.snapshotPhaseOrderEvents().single.sequence, 0);
    });

    test('snapshot returns an unmodifiable copy', () {
      runtime.handleWorkOrderTrace(
        playerId: 'p1',
        order: const WorkOrder(unitId: 'u1', target: 't', targetTileKey: 'k'),
        applied: true,
      );
      final snapshot = runtime.snapshotPhaseOrderEvents();
      expect(
        () => snapshot.add(
          const TurnTraceOrderEvent(
            sequence: 9,
            orderId: 'x',
            eventType: 'y',
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
