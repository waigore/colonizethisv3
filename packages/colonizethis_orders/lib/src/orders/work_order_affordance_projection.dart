/// Canonical pending-work replay for civilian assign affordability. Refs #4281.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'order_work_constants.dart';
import 'province_tile_lookup.dart';
import 'validators/work_order_cost_calculator.dart';

/// Material-backed civilian work targets for stockpile projection.
const Set<String> kMaterialBackedCivilianWorkTargets = {
  kWorkTargetBuildImprovement,
  kWorkTargetUpgradeTown,
  kWorkTargetBuildRoad,
  kWorkTargetBuildPort,
  kWorkTargetBuildFort,
  kWorkTargetBuildRail,
};

/// Projected stockpile and treasury after replaying pending work orders.
class PendingWorkResourceProjection {
  const PendingWorkResourceProjection({
    required this.stockpile,
    required this.treasury,
  });

  final Stockpile stockpile;
  final int treasury;
}

/// Controls how [replayPendingWorkResourceProjection] treats treasury orders.
class PendingWorkReplayOptions {
  const PendingWorkReplayOptions({
    this.deductTreasuryForPurchaseLand = true,
    this.stopBeforeUnitId,
  });

  /// When false, [kWorkTargetPurchaseLand] orders are skipped (stockpile-only).
  final bool deductTreasuryForPurchaseLand;

  /// When set, replay stops before processing the order for this unit id.
  final String? stopBeforeUnitId;
}

/// Replays pending work orders in draft list order, skipping in-progress units
/// and unaffordable predecessors without deducting (Refs #4262, #4281).
PendingWorkResourceProjection replayPendingWorkResourceProjection({
  required Game game,
  required String playerId,
  required List<WorkOrder> orders,
  PendingWorkReplayOptions options = const PendingWorkReplayOptions(),
}) {
  final player = game.playerById(playerId);
  if (player == null) {
    return const PendingWorkResourceProjection(
      stockpile: Stockpile.empty,
      treasury: 0,
    );
  }

  var stockpile = player.stockpile;
  var treasury = player.treasury;
  if (orders.isEmpty) {
    return PendingWorkResourceProjection(stockpile: stockpile, treasury: treasury);
  }

  final tileState = game.worldState.tileState;
  final calculator = WorkOrderCostCalculator(game, playerId: playerId);
  final stopBefore = options.stopBeforeUnitId;

  for (final order in orders) {
    if (stopBefore != null && order.unitId == stopBefore) {
      break;
    }

    final unit = game.worldState.tryGetUnitById(order.unitId);
    if (unit == null || unit.currentWork != null) continue;
    if (order.targetTileKey.isEmpty) continue;
    if (!isWorkOrderTargetAllowedForUnitType(unit.type, order.target)) continue;

    if (order.target == kWorkTargetPurchaseLand) {
      if (!options.deductTreasuryForPurchaseLand) continue;
      final resourceId =
          game.worldState.resourceByTileKey[order.targetTileKey];
      if (resourceId == null || resourceId.isEmpty) continue;
      final cost = purchaseLandCost(resourceId);
      if (treasury < cost) continue;
      treasury -= cost;
      continue;
    }

    if (!kMaterialBackedCivilianWorkTargets.contains(order.target)) continue;

    final cost = _materialCostForPendingOrder(
      game: game,
      calculator: calculator,
      order: order,
      tileState: tileState,
    );
    if (cost == null || cost.isEmpty) continue;
    if (!ProjectedCostEngine.canAffordWorkMaterialCost(stockpile, cost)) {
      continue;
    }
    stockpile = ProjectedCostEngine.deductWorkMaterialCost(stockpile, cost);
  }

  return PendingWorkResourceProjection(stockpile: stockpile, treasury: treasury);
}

Map<String, int>? _materialCostForPendingOrder({
  required Game game,
  required WorkOrderCostCalculator calculator,
  required WorkOrder order,
  required TileMapState tileState,
}) {
  final province =
      tryGetProvinceAtTileKey(game.worldState, order.targetTileKey);
  return calculator.calculateCost(
    order.target,
    order.targetTileKey,
    improvementLevel: tileState.improvementLevel(order.targetTileKey),
    fortLevel: province?.fortLevel ?? 0,
    roadLevel: tileState.roadLevel(order.targetTileKey),
  );
}

Map<String, int>? materialCostForWorkTargetAtTile({
  required Game game,
  required String playerId,
  required String workTarget,
  required String targetTileKey,
  int? improvementLevel,
}) {
  final tileState = game.worldState.tileState;
  final province = tryGetProvinceAtTileKey(game.worldState, targetTileKey);
  final level = improvementLevel ??
      (workTarget == kWorkTargetBuildImprovement
          ? tileState.improvementLevel(targetTileKey)
          : 0);
  return WorkOrderCostCalculator(game, playerId: playerId).calculateCost(
    workTarget,
    targetTileKey,
    improvementLevel: level,
    fortLevel: province?.fortLevel ?? 0,
    roadLevel: tileState.roadLevel(targetTileKey),
  );
}
