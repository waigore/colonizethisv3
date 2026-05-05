import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../world/player_view.dart';
import '../world/unit_lookup.dart';
import 'order_suggestion_build_research.dart';

class AvailableWorkTargetsForUnit {
  const AvailableWorkTargetsForUnit({
    required this.unitId,
    required this.assignable,
    required this.blockedReason,
    required this.validTileKeysByTarget,
  });

  final String unitId;
  final bool assignable;
  final String? blockedReason;
  final Map<String, Set<String>> validTileKeysByTarget;
}

AvailableWorkTargetsForUnit getAvailableWorkTargetsForUnit({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
  required Orders currentOrders,
  required String unitId,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final playerId = view.playerId;
  final unitsById = unitsByIdFromWorld(game.worldState);
  final unit = unitsById[unitId];
  if (unit == null || unit.ownerId != playerId) {
    return AvailableWorkTargetsForUnit(
      unitId: unitId,
      assignable: false,
      blockedReason: 'unit_not_found_or_not_owned',
      validTileKeysByTarget: const {},
    );
  }

  final existingWork =
      currentOrders.workOrdersByPlayerId[playerId] ?? const <WorkOrder>[];
  final hasPendingWorkOrderForUnit = existingWork.any(
    (o) => o.unitId == unitId,
  );
  final moveOrders =
      currentOrders.moveOrdersByPlayerId[playerId] ?? const <MoveOrder>[];
  final hasPendingMoveOrderForUnit = moveOrders.any((m) => m.unitId == unitId);

  if (unit.currentWork != null ||
      hasPendingWorkOrderForUnit ||
      hasPendingMoveOrderForUnit) {
    final reason = unit.currentWork != null
        ? 'unit_has_current_work'
        : hasPendingWorkOrderForUnit
            ? 'unit_has_pending_work_order'
            : 'unit_has_pending_move_order';
    return AvailableWorkTargetsForUnit(
      unitId: unitId,
      assignable: false,
      blockedReason: reason,
      validTileKeysByTarget: const {},
    );
  }

  final allowedTargets = workOrderTargetsByUnitType[unit.type];
  if (allowedTargets == null || allowedTargets.isEmpty) {
    return AvailableWorkTargetsForUnit(
      unitId: unitId,
      assignable: false,
      blockedReason: 'no_work_targets_for_unit_type',
      validTileKeysByTarget: const {},
    );
  }

  final validByTarget = <String, Set<String>>{};

  for (final target in allowedTargets) {
    final tiles = getValidWorkOrderTileKeysWithVisibility(
      game: game,
      topology: topology,
      view: view,
      unitId: unitId,
      workTarget: target,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
    );
    if (tiles.isNotEmpty) {
      validByTarget[target] = tiles.toSet();
    }
  }

  return AvailableWorkTargetsForUnit(
    unitId: unitId,
    assignable: validByTarget.isNotEmpty,
    blockedReason: validByTarget.isNotEmpty ? null : 'no_valid_work_targets',
    validTileKeysByTarget: validByTarget,
  );
}
