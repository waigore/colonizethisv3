/// Pending-order state for a civilian unit row. SPEC/ui/civilian-units-panel.md.

import 'package:colonizethis_models/colonizethis_models.dart';

class CivilianUnitsPanelUnitRowPending {
  const CivilianUnitsPanelUnitRowPending({
    required this.unit,
    required this.currentOrders,
    required this.humanPlayerId,
  });

  final Unit unit;
  final Orders currentOrders;
  final String humanPlayerId;

  List<WorkOrder> get pendingForPlayer =>
      currentOrders.workOrdersByPlayerId[humanPlayerId] ?? const [];

  MoveOrder? get pendingMoveOrder {
    final moves =
        currentOrders.moveOrdersByPlayerId[humanPlayerId] ?? const [];
    for (final o in moves) {
      if (o.unitId == unit.id) return o;
    }
    return null;
  }

  bool get isSpy => unit.type == kUnitTypeSpy;

  WorkOrder? get pendingWorkOrder {
    for (final o in pendingForPlayer) {
      if (o.unitId == unit.id) return o;
    }
    return null;
  }

  bool get hasPendingWorkOnly => pendingWorkOrder != null;

  bool get canRelocateSpy =>
      isSpy &&
      unit.status == UnitStatus.idle &&
      unit.currentWork == null &&
      !hasPendingWorkOnly;

  int? get pendingIndex {
    final list = pendingForPlayer;
    for (var i = 0; i < list.length; i++) {
      if (list[i].unitId == unit.id) return i;
    }
    return null;
  }

  bool get isIdleNoPending =>
      unit.status == UnitStatus.idle &&
      unit.currentWork == null &&
      !hasPendingWorkOnly;

  bool get hasWork =>
      unit.currentWork != null ||
      hasPendingWorkOnly ||
      pendingMoveOrder != null;
}
