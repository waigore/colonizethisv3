/// Development panel material affordability after pending work. Refs #4175.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'order_work_constants.dart';
import 'unit_type_helpers.dart';
import 'validators/work_order_cost_calculator.dart';

/// Effective stockpile after deducting pending material work orders for
/// Development panel affordability checks (Slice B/C).
Stockpile effectiveStockpileAfterPendingDevelopmentMaterialWork({
  required Game game,
  required String playerId,
  required Orders currentOrders,
}) {
  final player = game.playerById(playerId);
  if (player == null) return Stockpile.empty;

  final orders = currentOrders.workOrdersByPlayerId[playerId];
  if (orders == null || orders.isEmpty) return player.stockpile;

  var stockpile = player.stockpile;
  final tileState = game.worldState.tileState;
  for (final order in orders) {
    if (!_developmentPanelPendingMaterialWorkTargets.contains(order.target)) {
      continue;
    }
    final unit = game.worldState.tryGetUnitById(order.unitId);
    if (unit == null || unit.currentWork != null) continue;
    if (order.targetTileKey.isEmpty) continue;
    if (!isWorkOrderTargetAllowedForUnitType(unit.type, order.target)) continue;

    final provinceId = Unit.provinceIdFromTileKey(order.targetTileKey);
    final province = provinceId == null
        ? null
        : game.worldState.tryGetProvince(provinceId);
    final cost = WorkOrderCostCalculator(game, playerId: playerId).calculateCost(
      order.target,
      order.targetTileKey,
      improvementLevel: tileState.improvementLevel(order.targetTileKey),
      fortLevel: province?.fortLevel ?? 0,
    );
    if (cost == null) continue;
    if (!ProjectedCostEngine.canAffordWorkMaterialCost(stockpile, cost)) {
      continue;
    }
    stockpile = ProjectedCostEngine.deductWorkMaterialCost(stockpile, cost);
  }
  return stockpile;
}

const Set<String> _developmentPanelPendingMaterialWorkTargets = {
  kWorkTargetBuildImprovement,
  kWorkTargetUpgradeTown,
  kWorkTargetBuildRoad,
  kWorkTargetBuildPort,
  kWorkTargetBuildFort,
  kWorkTargetBuildRail,
};
