import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show WorkOrderCostCalculator;
import 'package:colonizethis_world/colonizethis_world.dart';

/// Pending [RecruitWorkerOrder] costs from [Orders.recruitWorkerOrdersByPlayerId],
/// applied **before** unit-build and material-work pending costs to mirror the
/// live Build / work resolver order (worker pool sub-phase runs before
/// [BuildUnitOrder]).
///
/// Deducts treasury, materials, and the consumed peasant per
/// [WorkerActionEconomyCatalog]; increments the order's target tier on the
/// preview clone. Re-uses [canAffordRecruitWorker] / [applyRecruitWorkerCostDeduction]
/// so the projection shares the validator/resolver cost source of truth.
/// SPEC/program/order-projections.md § Production panel stockpile preview phases.
/// Applies pending per-player [O] order costs onto a preview clone, sharing the
/// `canAfford` → `applyDeduction` → `copyWith(workerPool, stockpile, treasury)`
/// loop used by both the worker-pool (recruit) and unit-build sub-phases.
///
/// [canAffordOrder] gates each order; [applyDeduction] returns the next
/// `(workers, stockpile, treasury)` snapshot. Both close over the order-type's
/// validator/resolver so the projection shares the live cost source of truth.
/// Per-player iteration follows [Game.mapPlayers] for deterministic order.
Game _applyPendingOrderCostsForPreview<O>({
  required Game game,
  required Map<String, List<O>> ordersByPlayerId,
  required bool Function(
    Player player,
    O order,
    WorkerPool workers,
    Stockpile stockpile,
    int treasury,
  )
  canAffordOrder,
  required ({WorkerPool workers, Stockpile stockpile, int treasury}) Function(
    Player player,
    O order,
    WorkerPool workers,
    Stockpile stockpile,
    int treasury,
  )
  applyDeduction,
}) {
  if (ordersByPlayerId.isEmpty) {
    return game;
  }
  return game.mapPlayers((player) {
    final orders = ordersByPlayerId[player.id];
    if (orders == null || orders.isEmpty) {
      return player;
    }
    var workers = player.workerPool;
    var stockpile = player.stockpile;
    var treasury = player.treasury;
    for (final order in orders) {
      if (!canAffordOrder(player, order, workers, stockpile, treasury)) {
        continue;
      }
      final after = applyDeduction(player, order, workers, stockpile, treasury);
      workers = after.workers;
      stockpile = after.stockpile;
      treasury = after.treasury;
    }
    return player.copyWith(
      workerPool: workers,
      stockpile: stockpile,
      treasury: treasury,
    );
  });
}

const Set<String> _pendingStockpileWorkTargetsForPreview = {
  kWorkTargetBuildImprovement,
  kWorkTargetUpgradeTown,
  kWorkTargetBuildRoad,
  kWorkTargetBuildPort,
  kWorkTargetBuildFort,
  kWorkTargetBuildRail,
};

/// Pending material-backed work-order costs from [Orders.workOrdersByPlayerId],
/// after unit-build pending costs, mirroring [applyStandardWorkOrder] guards in
/// the work phase (unit present and idle, valid target tile key, unit type
/// allowed, sequential affordability). Non-stockpile work targets are excluded.
Game _applyPendingMaterialWorkOrderCostsForPreview({
  required Game game,
  required Orders currentOrders,
}) {
  if (currentOrders.workOrdersByPlayerId.isEmpty) {
    return game;
  }
  final tileState = game.worldState.tileState;
  return game.mapPlayers((player) {
    final orders = currentOrders.workOrdersByPlayerId[player.id];
    if (orders == null || orders.isEmpty) {
      return player;
    }
    var stockpile = player.stockpile;
    for (final order in orders) {
      final target = order.target;
      if (!_pendingStockpileWorkTargetsForPreview.contains(target)) {
        continue;
      }
      final u = game.worldState.tryGetUnitById(order.unitId);
      if (u == null || u.currentWork != null) {
        continue;
      }
      final targetTileKey = order.targetTileKey;
      if (targetTileKey.isEmpty) {
        continue;
      }
      if (!isWorkOrderTargetAllowedForUnitType(u.type, target)) {
        continue;
      }
      final province = game.worldState.tryGetProvince(u.locationProvinceId);
      final cost = WorkOrderCostCalculator(game, playerId: player.id)
          .calculateCost(
            target,
            targetTileKey,
            improvementLevel: tileState.improvementLevel(targetTileKey),
            fortLevel: province?.fortLevel ?? 0,
          );
      if (cost == null) {
        continue;
      }
      if (!ProjectedCostEngine.canAffordWorkMaterialCost(stockpile, cost)) {
        continue;
      }
      stockpile = ProjectedCostEngine.deductWorkMaterialCost(stockpile, cost);
    }
    return player.copyWith(stockpile: stockpile);
  });
}

/// Applies recruit-worker, unit-build, and material work-order pending costs
/// onto [game] for economy stockpile preview. Order matches live Build / work
/// resolver sub-phases.
Game applyPendingStockpileCostsForPreview({
  required Game game,
  required Orders currentOrders,
}) {
  final afterRecruits = _applyPendingOrderCostsForPreview<RecruitWorkerOrder>(
    game: game,
    ordersByPlayerId: currentOrders.recruitWorkerOrdersByPlayerId,
    canAffordOrder: (player, order, workers, stockpile, treasury) =>
        canAffordRecruitWorker(
          player,
          order,
          workers,
          stockpile,
          treasury,
        ).canAfford,
    applyDeduction: (player, order, workers, stockpile, treasury) =>
        applyRecruitWorkerCostDeduction(order, workers, stockpile, treasury),
  );
  final afterBuilds = _applyPendingOrderCostsForPreview<BuildUnitOrder>(
    game: afterRecruits,
    ordersByPlayerId: currentOrders.buildUnitOrdersByPlayerId,
    canAffordOrder: (player, order, workers, stockpile, treasury) =>
        ProjectedCostEngine.canAffordBuildOrder(
          player,
          order,
          workers,
          stockpile,
          treasury,
        ).canAfford,
    applyDeduction: (player, order, workers, stockpile, treasury) =>
        ProjectedCostEngine.applyBuildOrderCostDeduction(
          player,
          order,
          workers,
          stockpile,
          treasury,
        ),
  );
  return _applyPendingMaterialWorkOrderCostsForPreview(
    game: afterBuilds,
    currentOrders: currentOrders,
  );
}
