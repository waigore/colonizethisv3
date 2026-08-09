/// Development panel material affordability after pending work. Refs #4175, #4211, #4281.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import '../civilian_work_affordance.dart' show previewWorkOrderAffordAtTile;
import '../work_order_affordance_projection.dart'
    show PendingWorkReplayOptions, replayPendingWorkResourceProjection;

/// Effective stockpile after deducting pending material work orders for
/// Development panel affordability checks (Slice B/C).
Stockpile effectiveStockpileAfterPendingDevelopmentMaterialWork({
  required Game game,
  required String playerId,
  required Orders currentOrders,
}) {
  final orders = currentOrders.workOrdersByPlayerId[playerId] ?? const [];
  return replayPendingWorkResourceProjection(
    game: game,
    playerId: playerId,
    orders: orders,
    options: const PendingWorkReplayOptions(
      deductTreasuryForPurchaseLand: false,
    ),
  ).stockpile;
}

/// Whether the player can afford a development work order after pending material
/// work is projected from the stockpile.
bool canAffordDevelopmentWorkOrder({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required String workTarget,
  required String targetTileKey,
}) {
  return previewWorkOrderAffordAtTile(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
    workTarget: workTarget,
    targetTileKey: targetTileKey,
  ).canAfford;
}
