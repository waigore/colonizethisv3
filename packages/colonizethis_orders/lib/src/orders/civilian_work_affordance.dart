/// Civilian work-order cost and affordability previews at assign time. Refs #4262.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'order_work_constants.dart';
import 'validators/work_order_cost_calculator.dart';

/// Work targets with no material/treasury cost preview in assign UI.
const Set<String> kFreeCivilianWorkTargets = {
  kWorkTargetExplore,
  kWorkTargetProspect,
  kWorkTargetCounterSpy,
};

/// Material-backed civilian work targets for stockpile projection.
const Set<String> kMaterialBackedCivilianWorkTargets = {
  kWorkTargetBuildImprovement,
  kWorkTargetUpgradeTown,
  kWorkTargetBuildRoad,
  kWorkTargetBuildPort,
  kWorkTargetBuildFort,
  kWorkTargetBuildRail,
};

/// One commodity shortfall vs projected stockpile.
typedef WorkOrderMaterialShortfall = ({String commodityId, int quantity});

/// Cost + affordability preview for one work target at one tile.
class WorkOrderAffordPreview {
  const WorkOrderAffordPreview({
    this.materialCosts,
    this.treasuryAmount,
    required this.canAfford,
    this.materialShortfalls = const [],
    this.treasuryShortfall,
  });

  final Map<String, int>? materialCosts;
  final int? treasuryAmount;
  final bool canAfford;
  final List<WorkOrderMaterialShortfall> materialShortfalls;
  final int? treasuryShortfall;

  bool get hasCostPreview =>
      (materialCosts != null && materialCosts!.isNotEmpty) ||
      treasuryAmount != null;
}

bool isFreeCivilianWorkTarget(String workTarget) =>
    kFreeCivilianWorkTargets.contains(workTarget);

({Stockpile stockpile, int treasury}) projectPlayerResourcesAfterPendingWork({
  required Game game,
  required String playerId,
  required Orders currentOrders,
}) {
  final player = game.playerById(playerId);
  if (player == null) {
    return (stockpile: Stockpile.empty, treasury: 0);
  }

  var stockpile = player.stockpile;
  var treasury = player.treasury;
  final orders = currentOrders.workOrdersByPlayerId[playerId];
  if (orders == null || orders.isEmpty) {
    return (stockpile: stockpile, treasury: treasury);
  }

  final tileState = game.worldState.tileState;
  final calculator = WorkOrderCostCalculator(game, playerId: playerId);

  for (final order in orders) {
    final unit = game.worldState.tryGetUnitById(order.unitId);
    if (unit == null || unit.currentWork != null) continue;
    if (order.targetTileKey.isEmpty) continue;
    if (!isWorkOrderTargetAllowedForUnitType(unit.type, order.target)) continue;

    if (order.target == kWorkTargetPurchaseLand) {
      final resourceId =
          game.worldState.resourceByTileKey[order.targetTileKey];
      if (resourceId == null || resourceId.isEmpty) continue;
      final cost = purchaseLandCost(resourceId);
      if (treasury < cost) continue;
      treasury -= cost;
      continue;
    }

    if (!kMaterialBackedCivilianWorkTargets.contains(order.target)) continue;

    final provinceId = Unit.provinceIdFromTileKey(order.targetTileKey);
    final province = provinceId == null
        ? null
        : game.worldState.tryGetProvince(provinceId);
    final cost = calculator.calculateCost(
      order.target,
      order.targetTileKey,
      improvementLevel: tileState.improvementLevel(order.targetTileKey),
      fortLevel: province?.fortLevel ?? 0,
      roadLevel: tileState.roadLevel(order.targetTileKey),
    );
    if (cost == null || cost.isEmpty) continue;
    if (!ProjectedCostEngine.canAffordWorkMaterialCost(stockpile, cost)) {
      continue;
    }
    stockpile = ProjectedCostEngine.deductWorkMaterialCost(stockpile, cost);
  }

  return (stockpile: stockpile, treasury: treasury);
}

List<WorkOrderMaterialShortfall> workOrderMaterialShortfalls({
  required Stockpile stockpile,
  required Map<String, int> cost,
}) {
  final out = <WorkOrderMaterialShortfall>[];
  for (final entry in cost.entries) {
    final have = stockpile.quantityOf(entry.key);
    if (have < entry.value) {
      out.add((commodityId: entry.key, quantity: entry.value - have));
    }
  }
  return out;
}

WorkOrderAffordPreview previewWorkOrderAffordAtTile({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required String workTarget,
  required String targetTileKey,
}) {
  if (isFreeCivilianWorkTarget(workTarget)) {
    return const WorkOrderAffordPreview(canAfford: true);
  }

  final projected = projectPlayerResourcesAfterPendingWork(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
  );

  if (workTarget == kWorkTargetPurchaseLand) {
    final resourceId = game.worldState.resourceByTileKey[targetTileKey];
    if (resourceId == null || resourceId.isEmpty) {
      return const WorkOrderAffordPreview(canAfford: false);
    }
    final cost = purchaseLandCost(resourceId);
    final shortfall = projected.treasury < cost ? cost - projected.treasury : null;
    return WorkOrderAffordPreview(
      treasuryAmount: cost,
      canAfford: shortfall == null,
      treasuryShortfall: shortfall,
    );
  }

  final provinceId = Unit.provinceIdFromTileKey(targetTileKey);
  final province = provinceId == null
      ? null
      : game.worldState.tryGetProvince(provinceId);
  final tileState = game.worldState.tileState;
  final costMap = WorkOrderCostCalculator(game, playerId: playerId).calculateCost(
    workTarget,
    targetTileKey,
    improvementLevel: workTarget == kWorkTargetBuildImprovement
        ? tileState.improvementLevel(targetTileKey)
        : 0,
    fortLevel: province?.fortLevel ?? 0,
    roadLevel: tileState.roadLevel(targetTileKey),
  );

  if (costMap == null || costMap.isEmpty) {
    return const WorkOrderAffordPreview(canAfford: true);
  }

  final shortfalls = workOrderMaterialShortfalls(
    stockpile: projected.stockpile,
    cost: costMap,
  );
  return WorkOrderAffordPreview(
    materialCosts: costMap,
    canAfford: shortfalls.isEmpty,
    materialShortfalls: shortfalls,
  );
}

/// Affordability for one pending work order after earlier pending orders in
/// draft list order (skips unaffordable predecessors without deducting).
WorkOrderAffordPreview previewPendingWorkOrderAfford({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required WorkOrder pendingOrder,
}) {
  final player = game.playerById(playerId);
  if (player == null) {
    return const WorkOrderAffordPreview(canAfford: false);
  }

  final orders = currentOrders.workOrdersByPlayerId[playerId] ?? const [];
  var stockpile = player.stockpile;
  var treasury = player.treasury;
  final tileState = game.worldState.tileState;
  final calculator = WorkOrderCostCalculator(game, playerId: playerId);

  for (final order in orders) {
    if (order.unitId == pendingOrder.unitId) {
      return _previewSingleOrderAfford(
        game: game,
        playerId: playerId,
        stockpile: stockpile,
        treasury: treasury,
        order: pendingOrder,
        tileState: tileState,
        calculator: calculator,
      );
    }

    final unit = game.worldState.tryGetUnitById(order.unitId);
    if (unit == null || unit.currentWork != null) continue;
    if (order.targetTileKey.isEmpty) continue;
    if (!isWorkOrderTargetAllowedForUnitType(unit.type, order.target)) continue;

    if (order.target == kWorkTargetPurchaseLand) {
      final resourceId =
          game.worldState.resourceByTileKey[order.targetTileKey];
      if (resourceId == null || resourceId.isEmpty) continue;
      final cost = purchaseLandCost(resourceId);
      if (treasury < cost) continue;
      treasury -= cost;
      continue;
    }

    if (!kMaterialBackedCivilianWorkTargets.contains(order.target)) continue;

    final provinceId = Unit.provinceIdFromTileKey(order.targetTileKey);
    final province = provinceId == null
        ? null
        : game.worldState.tryGetProvince(provinceId);
    final cost = calculator.calculateCost(
      order.target,
      order.targetTileKey,
      improvementLevel: tileState.improvementLevel(order.targetTileKey),
      fortLevel: province?.fortLevel ?? 0,
      roadLevel: tileState.roadLevel(order.targetTileKey),
    );
    if (cost == null || cost.isEmpty) continue;
    if (!ProjectedCostEngine.canAffordWorkMaterialCost(stockpile, cost)) {
      continue;
    }
    stockpile = ProjectedCostEngine.deductWorkMaterialCost(stockpile, cost);
  }

  return const WorkOrderAffordPreview(canAfford: false);
}

WorkOrderAffordPreview _previewSingleOrderAfford({
  required Game game,
  required String playerId,
  required Stockpile stockpile,
  required int treasury,
  required WorkOrder order,
  required TileMapState tileState,
  required WorkOrderCostCalculator calculator,
}) {
  if (isFreeCivilianWorkTarget(order.target)) {
    return const WorkOrderAffordPreview(canAfford: true);
  }

  if (order.target == kWorkTargetPurchaseLand) {
    final resourceId = game.worldState.resourceByTileKey[order.targetTileKey];
    if (resourceId == null || resourceId.isEmpty) {
      return const WorkOrderAffordPreview(canAfford: false);
    }
    final cost = purchaseLandCost(resourceId);
    final shortfall = treasury < cost ? cost - treasury : null;
    return WorkOrderAffordPreview(
      treasuryAmount: cost,
      canAfford: shortfall == null,
      treasuryShortfall: shortfall,
    );
  }

  final provinceId = Unit.provinceIdFromTileKey(order.targetTileKey);
  final province = provinceId == null
      ? null
      : game.worldState.tryGetProvince(provinceId);
  final costMap = calculator.calculateCost(
    order.target,
    order.targetTileKey,
    improvementLevel: order.target == kWorkTargetBuildImprovement
        ? tileState.improvementLevel(order.targetTileKey)
        : 0,
    fortLevel: province?.fortLevel ?? 0,
    roadLevel: tileState.roadLevel(order.targetTileKey),
  );

  if (costMap == null || costMap.isEmpty) {
    return const WorkOrderAffordPreview(canAfford: true);
  }

  final shortfalls = workOrderMaterialShortfalls(
    stockpile: stockpile,
    cost: costMap,
  );
  return WorkOrderAffordPreview(
    materialCosts: costMap,
    canAfford: shortfalls.isEmpty,
    materialShortfalls: shortfalls,
  );
}
