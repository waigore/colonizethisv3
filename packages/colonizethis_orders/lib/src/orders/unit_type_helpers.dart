import 'package:colonizethis_models/colonizethis_models.dart'
    show
        Game,
        Orders,
        WorldState,
        kUnitTypeBuilder,
        kUnitTypeEngineer,
        kUnitTypeMerchant;

import 'order_work_constants.dart';
import 'package:colonizethis_world/src/world/unit_lookup.dart' show allUnitsFromWorld;

/// Shared unit-type and work-target predicates for orders. SPEC/program/orders.md § Work orders.
/// Used by WorkOrderValidator and OrderEngine for dev-exclusive tile tracking.

/// True for Builder, Engineer, Merchant: at most one work order per tile per player.
bool isDevExclusiveUnitType(String type) =>
    type == kUnitTypeBuilder ||
    type == kUnitTypeEngineer ||
    type == kUnitTypeMerchant;

/// True for work targets that participate in per-tile exclusivity (one order per tile per player).
/// Used with [isDevExclusiveUnitType] to enforce Builder/Engineer/Merchant tile exclusivity.
bool isDevExclusiveWorkTarget(String target) =>
    target == kWorkTargetBuildImprovement ||
    target == kWorkTargetUpgradeTown ||
    target == kWorkTargetBuildRoad ||
    target == kWorkTargetBuildPort ||
    target == kWorkTargetBuildFort ||
    target == kWorkTargetPurchaseLand;

/// Tile keys already reserved by [playerId]'s Builder/Engineer/Merchant currentWork.
/// Used for per-player tile exclusivity (SPEC/game/civilian-units.md, SPEC/program/orders.md).
Set<String> devExclusiveTilesFromWorld(WorldState world, String playerId) {
  final tiles = <String>{};
  for (final u in allUnitsFromWorld(world)) {
    final w = u.currentWork;
    if (u.ownerId == playerId &&
        isDevExclusiveUnitType(u.type) &&
        w != null &&
        w.tileKey.isNotEmpty) {
      tiles.add(w.tileKey);
    }
  }
  return tiles;
}

/// Tiles reserved for Builder/Engineer/Merchant per-tile exclusivity for [playerId].
///
/// Union of [devExclusiveTilesFromWorld] and `targetTileKey` for each pending
/// [WorkOrder] in [orders] for that player whose target is [isDevExclusiveWorkTarget].
///
/// When [ignorePendingWorkOrderUnitId] is set, pending orders whose [WorkOrder.unitId]
/// equals that value are **omitted** from the pending contribution (in-progress
/// work from the world is unchanged). Used when listing valid tiles for the **same**
/// unit’s tile picker so a tile already chosen in the pending list stays selectable;
/// [suggestWorkOrders] uses the full set (no ignore) so a second unit does not see
/// tiles reserved by another unit’s pending order.
///
/// SPEC/program/orders.md § WorkOrder per-tile exclusivity; order-suggestions.md.
Set<String> devExclusiveReservedTileKeysForPlayer(
  Game game,
  Orders orders,
  String playerId, {
  String? ignorePendingWorkOrderUnitId,
}) {
  final tiles = devExclusiveTilesFromWorld(game.worldState, playerId);
  final workList = orders.workOrdersByPlayerId[playerId] ?? const [];
  for (final o in workList) {
    if (!isDevExclusiveWorkTarget(o.target)) continue;
    if (o.targetTileKey.isEmpty) continue;
    if (ignorePendingWorkOrderUnitId != null &&
        o.unitId == ignorePendingWorkOrderUnitId) {
      continue;
    }
    tiles.add(o.targetTileKey);
  }
  return tiles;
}
