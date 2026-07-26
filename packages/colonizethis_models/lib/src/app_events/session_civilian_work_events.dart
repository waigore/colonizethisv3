/// Civilian work session commands (Refs #4136 Slice B).

import '../orders.dart';
import 'session_command_event_base.dart';

/// Remove pending civilian work order at [index] for [playerId] in current-turn
/// draft. Shell listener applies the canonical mutation from colonizethis_logic.
class RemovePendingWorkOrderRequestedEvent extends SessionCommandEvent {
  RemovePendingWorkOrderRequestedEvent({
    required this.playerId,
    required this.index,
  });

  final String playerId;
  final int index;
}

/// Clear in-progress civilian work for [unitId] (no refund). Shell listener
/// applies the canonical mutation from colonizethis_logic and persists game.
class CancelInProgressCivilianWorkRequestedEvent extends SessionCommandEvent {
  CancelInProgressCivilianWorkRequestedEvent({required this.unitId});

  final String unitId;
}

/// Upsert one pending civilian [workOrder] for [playerId] in current-turn draft.
/// Replaces any existing pending work for the same unit and clears conflicting
/// pending move order for that unit (work-order draft xor rule).
class UpsertPendingCivilianWorkOrderRequestedEvent extends SessionCommandEvent {
  UpsertPendingCivilianWorkOrderRequestedEvent({
    required this.playerId,
    required this.workOrder,
  });

  final String playerId;
  final WorkOrder workOrder;
}
