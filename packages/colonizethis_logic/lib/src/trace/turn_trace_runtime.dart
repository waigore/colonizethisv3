import 'package:colonizethis_models/colonizethis_models.dart';

import 'turn_trace_contracts.dart';

typedef CivilianMoveOrderTraceCallback =
    void Function({
      required String playerId,
      required MoveOrder order,
      required bool applied,
      String? ignoreReason,
    });

typedef BundledWorkMoveTraceCallback =
    void Function({
      required String playerId,
      required WorkOrder order,
      required bool applied,
      String? destinationProvinceId,
      String? destinationTileKey,
      String? ignoreReason,
    });

typedef WorkOrderTraceCallback =
    void Function({
      required String playerId,
      required WorkOrder order,
      required bool applied,
      String? ignoreReason,
    });

typedef ArmyMoveOrderTraceCallback =
    void Function({
      required String playerId,
      required ArmyMoveOrder order,
      required bool applied,
      String? regionId,
      String? destinationProvinceId,
      String? ignoreReason,
    });

/// Mutable per-turn-resolution buffer for order-level trace events within the
/// current phase. Cleared at each phase boundary by [turn_phase_runner]; read
/// via [snapshotPhaseOrderEvents] when emitting [TurnTracePhaseTrace].
class TurnTraceRuntime {
  final List<TurnTraceOrderEvent> _phaseOrderEvents = <TurnTraceOrderEvent>[];
  int _nextSequence = 0;

  void clearPhaseOrderEvents() {
    _phaseOrderEvents.clear();
    _nextSequence = 0;
  }

  List<TurnTraceOrderEvent> snapshotPhaseOrderEvents() =>
      List<TurnTraceOrderEvent>.unmodifiable(
        List<TurnTraceOrderEvent>.from(_phaseOrderEvents),
      );

  /// Records one civilian [MoveOrder] application attempt in movement phase order.
  void handleCivilianMoveOrderTrace({
    required String playerId,
    required MoveOrder order,
    required bool applied,
    String? ignoreReason,
  }) {
    _phaseOrderEvents.add(
      TurnTraceOrderEvent(
        sequence: _nextSequence++,
        orderId: 'move:$playerId:${order.unitId}',
        eventType: applied ? 'civilian_move_applied' : 'civilian_move_ignored',
        payload: <String, Object?>{
          'destinationTileKey': order.destinationTileKey,
          if (ignoreReason != null) 'ignoreReason': ignoreReason,
        },
      ),
    );
  }

  /// Records one implicit move leg generated for a civilian [WorkOrder].
  void handleBundledWorkMoveTrace({
    required String playerId,
    required WorkOrder order,
    required bool applied,
    String? destinationProvinceId,
    String? destinationTileKey,
    String? ignoreReason,
  }) {
    _phaseOrderEvents.add(
      TurnTraceOrderEvent(
        sequence: _nextSequence++,
        orderId: 'work:$playerId:${order.unitId}:${order.target}',
        eventType: applied
            ? 'bundled_work_move_applied'
            : 'bundled_work_move_skipped',
        payload: <String, Object?>{
          'targetTileKey': order.targetTileKey,
          if (destinationProvinceId != null)
            'destinationProvinceId': destinationProvinceId,
          if (destinationTileKey != null)
            'destinationTileKey': destinationTileKey,
          if (ignoreReason != null) 'ignoreReason': ignoreReason,
        },
      ),
    );
  }

  /// Records one [ArmyMoveOrder] application attempt in movement phase order.
  ///
  /// Used for both same-region applies (with [regionId] set) and cross-region
  /// owned-province applies (with [regionId] left null).
  void handleArmyMoveOrderTrace({
    required String playerId,
    required ArmyMoveOrder order,
    required bool applied,
    String? regionId,
    String? destinationProvinceId,
    String? ignoreReason,
  }) {
    _phaseOrderEvents.add(
      TurnTraceOrderEvent(
        sequence: _nextSequence++,
        orderId: 'army_move:$playerId:${order.armyId}',
        eventType: applied ? 'army_move_applied' : 'army_move_ignored',
        payload: <String, Object?>{
          'destinationProvinceId':
              destinationProvinceId ?? order.destinationProvinceId,
          if (regionId != null) 'regionId': regionId,
          if (ignoreReason != null) 'ignoreReason': ignoreReason,
        },
      ),
    );
  }

  /// Records one work-order handling decision in build/work phase order.
  void handleWorkOrderTrace({
    required String playerId,
    required WorkOrder order,
    required bool applied,
    String? ignoreReason,
  }) {
    _phaseOrderEvents.add(
      TurnTraceOrderEvent(
        sequence: _nextSequence++,
        orderId: 'work:$playerId:${order.unitId}:${order.target}',
        eventType: applied ? 'work_order_applied' : 'work_order_skipped',
        payload: <String, Object?>{
          'targetTileKey': order.targetTileKey,
          if (ignoreReason != null) 'ignoreReason': ignoreReason,
        },
      ),
    );
  }
}
