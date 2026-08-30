import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/src/trace/turn_trace_runtime.dart';
import 'move_order_apply_logging.dart';
import 'movement_civilian_apply_order.dart';
import 'province_lookup.dart';
import 'region_unit_lists.dart';

/// Civilian tile-move order application pipeline.
/// SPEC/program/movement.md; issue #1877.

/// Applies civilian [MoveOrder]s (tile destinations) across both world regions.
/// Ignores military units and invalid payloads. Resolution assumes orders passed validation.
/// Returns [game.worldState] with updated unit lists via [WorldState.mapBothRegionUnits].
WorldState applyCivilianTileMoveOrdersToWorldRegions(
  Game game,
  Map<String, List<MoveOrder>> moveOrdersByPlayerId, {
  CivilianMoveOrderTraceCallback? onCivilianMoveOrderTrace,
}) {
  if (moveOrdersByPlayerId.isEmpty) return game.worldState;
  final result = _applyCivilianMoveOrders(
    game,
    moveOrdersByPlayerId,
    onCivilianMoveOrderTrace: onCivilianMoveOrderTrace,
  );
  logMoveOrderApplySummary(
    message:
        'civilian tile movement apply orders=${result.totals.ordersSeen} '
        'applied=${result.totals.applied} ignored=${result.totals.ignored}',
    applied: result.totals.applied,
    ignored: result.totals.ignored,
  );
  return game.worldState.mapBothRegionUnits(
    (regionId, _) => result.lists.unitListForRegion(regionId),
  );
}

CivilianMovePlayerOutcome _applyCivilianMoveOrders(
  Game game,
  Map<String, List<MoveOrder>> moveOrdersByPlayerId, {
  CivilianMoveOrderTraceCallback? onCivilianMoveOrderTrace,
}) {
  var lists = game.worldState.mutableRegionUnitLists();
  var totals = _zeroMoveTotals();
  final sortedPlayers = moveOrdersByPlayerId.keys.toList()..sort();
  for (final playerId in sortedPlayers) {
    final forPlayer = _applyCivilianMoveOrdersForPlayer(
      lists: lists,
      playerId: playerId,
      orders: moveOrdersByPlayerId[playerId] ?? const [],
      onCivilianMoveOrderTrace: onCivilianMoveOrderTrace,
    );
    lists = forPlayer.lists;
    totals = _sumMoveTotals(totals, forPlayer.totals);
  }
  return (lists: lists, totals: totals);
}

CivilianMoveTotals _zeroMoveTotals() => (ordersSeen: 0, applied: 0, ignored: 0);

CivilianMoveTotals _sumMoveTotals(
  CivilianMoveTotals totals,
  CivilianMoveTotals update,
) => (
  ordersSeen: totals.ordersSeen + update.ordersSeen,
  applied: totals.applied + update.applied,
  ignored: totals.ignored + update.ignored,
);

CivilianMovePlayerOutcome _applyCivilianMoveOrdersForPlayer({
  required RegionUnitLists lists,
  required String playerId,
  required List<MoveOrder> orders,
  CivilianMoveOrderTraceCallback? onCivilianMoveOrderTrace,
}) {
  var localLists = lists;
  var totals = _zeroMoveTotals();
  for (final order in orders) {
    final one = applyOneCivilianMoveOrder(
      localLists,
      playerId,
      order,
      onCivilianMoveOrderTrace: onCivilianMoveOrderTrace,
    );
    localLists = one.lists;
    totals = _sumPerOrderTotals(totals, one);
  }
  return (lists: localLists, totals: totals);
}

CivilianMoveTotals _sumPerOrderTotals(
  CivilianMoveTotals totals,
  CivilianMoveOrderOutcome one,
) => (
  ordersSeen: totals.ordersSeen + 1,
  applied: totals.applied + one.applied,
  ignored: totals.ignored + one.ignored,
);
