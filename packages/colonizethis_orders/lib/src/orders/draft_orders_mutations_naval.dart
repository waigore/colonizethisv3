import 'package:colonizethis_models/colonizethis_models.dart';

/// Applies a human naval mission to the turn draft: replaces any prior naval
/// mission for the same [fleetId] and removes naval move orders for that fleet.
/// SPEC/program/naval-movement-resolution.md; Refs #4213.
Orders applyNavalMissionOrderForPlayer(
  Orders orders,
  String playerId,
  NavalMissionOrder newOrder,
) {
  final nextMissions = List<NavalMissionOrder>.from(
    orders.navalMissionOrdersByPlayerId[playerId] ?? const [],
  )..removeWhere((o) => o.fleetId == newOrder.fleetId);
  nextMissions.add(newOrder);

  final nextMoves = List<NavalMoveOrder>.from(
    orders.navalMoveOrdersByPlayerId[playerId] ?? const [],
  )..removeWhere((o) => o.fleetId == newOrder.fleetId);

  return orders.copyWith(
    navalMissionOrdersByPlayerId: {
      ...orders.navalMissionOrdersByPlayerId,
      playerId: nextMissions,
    },
    navalMoveOrdersByPlayerId: {
      ...orders.navalMoveOrdersByPlayerId,
      playerId: nextMoves,
    },
  );
}

/// Removes a pending naval mission for [fleetId] from the turn draft.
/// No-op when no mission is staged. Refs #4213.
Orders removeNavalMissionOrderForPlayer(
  Orders orders,
  String playerId,
  String fleetId,
) {
  final prior =
      orders.navalMissionOrdersByPlayerId[playerId] ??
      const <NavalMissionOrder>[];
  final next = [
    for (final NavalMissionOrder o in prior)
      if (o.fleetId != fleetId) o,
  ];
  if (next.length == prior.length) return orders;
  return orders.copyWith(
    navalMissionOrdersByPlayerId: {
      ...orders.navalMissionOrdersByPlayerId,
      playerId: next,
    },
  );
}

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
      for (final o
          in navalMoveOrdersByPlayerId[playerId] ?? const <NavalMoveOrder>[])
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
