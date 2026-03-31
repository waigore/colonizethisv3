import 'package:colonizethis_models/colonizethis_models.dart';

/// Applies a human naval move to the turn draft: replaces any prior naval move for
/// the same [fleetId] and removes naval mission orders for that fleet.
/// SPEC/program/naval-movement-resolution.md.
Orders applyNavalMoveOrderForPlayer(
  Orders orders,
  String playerId,
  NavalMoveOrder newOrder,
) {
  final nextMoves = List<NavalMoveOrder>.from(
    orders.navalMoveOrdersByPlayerId[playerId] ?? const [],
  )..removeWhere((o) => o.fleetId == newOrder.fleetId);
  nextMoves.add(newOrder);

  final nextMissions = List<NavalMissionOrder>.from(
    orders.navalMissionOrdersByPlayerId[playerId] ?? const [],
  )..removeWhere((o) => o.fleetId == newOrder.fleetId);

  return orders.copyWith(
    navalMoveOrdersByPlayerId: {
      ...orders.navalMoveOrdersByPlayerId,
      playerId: nextMoves,
    },
    navalMissionOrdersByPlayerId: {
      ...orders.navalMissionOrdersByPlayerId,
      playerId: nextMissions,
    },
  );
}

/// Drops naval mission orders for fleets that have a naval move order this turn.
/// SPEC/program/naval-movement-resolution.md.
Map<String, List<NavalMissionOrder>> navalMissionOrdersRespectingNavalMoves(
  Map<String, List<NavalMissionOrder>> navalMissionOrdersByPlayerId,
  Map<String, List<NavalMoveOrder>> navalMoveOrdersByPlayerId,
) {
  final out = <String, List<NavalMissionOrder>>{};
  navalMissionOrdersByPlayerId.forEach((playerId, list) {
    final movedFleetIds = {
      for (final o in navalMoveOrdersByPlayerId[playerId] ?? const <NavalMoveOrder>[])
        o.fleetId,
    };
    final filtered = [
      for (final o in list)
        if (!movedFleetIds.contains(o.fleetId)) o,
    ];
    if (filtered.isNotEmpty) out[playerId] = filtered;
  });
  return out;
}

/// Removes the pending civilian work order at [index] for [playerId] in this
/// turn's draft [orders]. No-op if the list is missing or [index] is out of
/// range. SPEC/program/orders.md.
Orders removePendingWorkOrderAt(
  Orders orders,
  String playerId,
  int index,
) {
  final list = orders.workOrdersByPlayerId[playerId];
  if (list == null || index < 0 || index >= list.length) {
    return orders;
  }
  final next = List<WorkOrder>.from(list)..removeAt(index);
  return orders.copyWith(
    workOrdersByPlayerId: {
      ...orders.workOrdersByPlayerId,
      playerId: next,
    },
  );
}
