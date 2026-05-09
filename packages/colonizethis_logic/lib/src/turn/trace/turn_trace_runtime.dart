import 'package:colonizethis_models/colonizethis_models.dart';

import 'turn_trace_contracts.dart';

typedef CivilianMoveOrderTraceCallback = void Function({
  required String playerId,
  required MoveOrder order,
  required bool applied,
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
}
