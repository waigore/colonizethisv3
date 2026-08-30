/// Projected affordability for military counsel train counts.
library;

import 'package:colonizethis_data/colonizethis_data.dart'
    show researchFundingTreasuryCost;
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Applies pending recruit, build, and research orders in resolver order and
/// returns the remaining worker pool, stockpile, and treasury.
({
  WorkerPool workers,
  Stockpile stockpile,
  int treasury,
}) militaryCounselProjectedResourcesAfterPendingOrders({
  required Player player,
  required Orders currentOrders,
}) {
  var workers = player.workerPool;
  var stockpile = player.stockpile;
  var treasury = player.treasury;

  final recruits = currentOrders.recruitWorkerOrdersByPlayerId[player.id];
  if (recruits != null) {
    for (final order in recruits) {
      final check = canAffordRecruitWorker(
        player,
        order,
        workers,
        stockpile,
        treasury,
      );
      if (!check.canAfford) continue;
      final after = applyRecruitWorkerCostDeduction(
        order,
        workers,
        stockpile,
        treasury,
      );
      workers = after.workers;
      stockpile = after.stockpile;
      treasury = after.treasury;
    }
  }

  final builds = currentOrders.buildUnitOrdersByPlayerId[player.id];
  if (builds != null) {
    for (final order in builds) {
      final check = ProjectedCostEngine.canAffordBuildOrder(
        player,
        order,
        workers,
        stockpile,
        treasury,
      );
      if (!check.canAfford) continue;
      final after = ProjectedCostEngine.applyBuildOrderCostDeduction(
        player,
        order,
        workers,
        stockpile,
        treasury,
      );
      workers = after.workers;
      stockpile = after.stockpile;
      treasury = after.treasury;
    }
  }

  final researches = currentOrders.researchOrdersByPlayerId[player.id];
  if (researches != null) {
    for (final order in researches) {
      if (order.techId.isEmpty) continue;
      final cost = researchFundingTreasuryCost(order.funding);
      if (cost <= 0 || treasury < cost) continue;
      treasury -= cost;
    }
  }

  return (workers: workers, stockpile: stockpile, treasury: treasury);
}

int militaryCounselGreedyAffordableBuildCount({
  required Player player,
  required BuildUnitOrder template,
  required Orders currentOrders,
}) {
  var projected = militaryCounselProjectedResourcesAfterPendingOrders(
    player: player,
    currentOrders: currentOrders,
  );
  var count = 0;
  while (true) {
    final check = ProjectedCostEngine.canAffordBuildOrder(
      player,
      template,
      projected.workers,
      projected.stockpile,
      projected.treasury,
    );
    if (!check.canAfford) break;
    final after = ProjectedCostEngine.applyBuildOrderCostDeduction(
      player,
      template,
      projected.workers,
      projected.stockpile,
      projected.treasury,
    );
    projected = (
      workers: after.workers,
      stockpile: after.stockpile,
      treasury: after.treasury,
    );
    count++;
  }
  return count;
}
