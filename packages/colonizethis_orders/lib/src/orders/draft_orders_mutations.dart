import 'package:colonizethis_models/colonizethis_models.dart';

export 'draft_orders_mutations_naval.dart';
export 'draft_orders_mutations_trade.dart';

/// Appends one [DiplomaticOrder] for [playerId] to the turn draft.
/// SPEC/program/orders.md.
Orders ordersWithAppendedDiplomaticOrder(
  Orders orders,
  String playerId,
  DiplomaticOrder order,
) {
  final list = List<DiplomaticOrder>.from(
    orders.diplomaticOrdersByPlayerId[playerId] ?? const <DiplomaticOrder>[],
  )..add(order);
  return orders.copyWith(
    diplomaticOrdersByPlayerId: {
      ...orders.diplomaticOrdersByPlayerId,
      playerId: list,
    },
  );
}

/// Replaces any prior civilian move for the same [unitId] and clears a
/// conflicting pending [WorkOrder] for that unit (move xor work draft rule).
/// SPEC/program/orders.md.
Orders applyCivilianMoveOrderForPlayer(
  Orders orders,
  String playerId,
  MoveOrder newOrder,
) {
  final nextMoves = List<MoveOrder>.from(
    orders.moveOrdersByPlayerId[playerId] ?? const <MoveOrder>[],
  )..removeWhere((o) => o.unitId == newOrder.unitId);
  nextMoves.add(newOrder);

  final nextWorks = List<WorkOrder>.from(
    orders.workOrdersByPlayerId[playerId] ?? const <WorkOrder>[],
  )..removeWhere((o) => o.unitId == newOrder.unitId);

  return orders.copyWith(
    moveOrdersByPlayerId: {...orders.moveOrdersByPlayerId, playerId: nextMoves},
    workOrdersByPlayerId: {...orders.workOrdersByPlayerId, playerId: nextWorks},
  );
}

/// Replaces any prior army move for the same [armyId] for this turn draft.
/// SPEC/game/military-armies.md.
Orders applyArmyMoveOrderForPlayer(
  Orders orders,
  String playerId,
  ArmyMoveOrder newOrder,
) {
  final next = List<ArmyMoveOrder>.from(
    orders.armyMoveOrdersByPlayerId[playerId] ?? const [],
  )..removeWhere((o) => o.armyId == newOrder.armyId);
  next.add(newOrder);
  return orders.copyWith(
    armyMoveOrdersByPlayerId: {
      ...orders.armyMoveOrdersByPlayerId,
      playerId: next,
    },
  );
}

/// Removes the pending civilian work order at [index] for [playerId] in this
/// turn's draft [orders]. No-op if the list is missing or [index] is out of
/// range. SPEC/program/orders.md.
Orders removePendingWorkOrderAt(Orders orders, String playerId, int index) {
  final list = orders.workOrdersByPlayerId[playerId];
  if (list == null || index < 0 || index >= list.length) {
    return orders;
  }
  final next = List<WorkOrder>.from(list)..removeAt(index);
  return orders.copyWith(
    workOrdersByPlayerId: {...orders.workOrdersByPlayerId, playerId: next},
  );
}
