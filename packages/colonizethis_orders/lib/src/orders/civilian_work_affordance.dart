/// Civilian work-order cost and affordability previews at assign time. Refs #4262.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'order_work_constants.dart';
import 'validators/work_order_cost_calculator.dart';
import 'work_order_affordance_projection.dart'
    show
        PendingWorkReplayOptions,
        materialCostForWorkTargetAtTile,
        replayPendingWorkResourceProjection;

export 'work_order_affordance_projection.dart'
    show kMaterialBackedCivilianWorkTargets;

/// Work targets with no material/treasury cost preview in assign UI.
const Set<String> kFreeCivilianWorkTargets = {
  kWorkTargetExplore,
  kWorkTargetProspect,
  kWorkTargetCounterSpy,
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
  final orders = currentOrders.workOrdersByPlayerId[playerId] ?? const [];
  final projected = replayPendingWorkResourceProjection(
    game: game,
    playerId: playerId,
    orders: orders,
  );
  return (stockpile: projected.stockpile, treasury: projected.treasury);
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

  final costMap = materialCostForWorkTargetAtTile(
    game: game,
    playerId: playerId,
    workTarget: workTarget,
    targetTileKey: targetTileKey,
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
  final projected = replayPendingWorkResourceProjection(
    game: game,
    playerId: playerId,
    orders: orders,
    options: PendingWorkReplayOptions(stopBeforeUnitId: pendingOrder.unitId),
  );

  if (!orders.any((o) => o.unitId == pendingOrder.unitId)) {
    return const WorkOrderAffordPreview(canAfford: false);
  }

  return _previewSingleOrderAfford(
    game: game,
    playerId: playerId,
    stockpile: projected.stockpile,
    treasury: projected.treasury,
    order: pendingOrder,
    tileState: game.worldState.tileState,
    calculator: WorkOrderCostCalculator(game, playerId: playerId),
  );
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

  final costMap = materialCostForWorkTargetAtTile(
    game: game,
    playerId: playerId,
    workTarget: order.target,
    targetTileKey: order.targetTileKey,
    improvementLevel: order.target == kWorkTargetBuildImprovement
        ? tileState.improvementLevel(order.targetTileKey)
        : 0,
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
