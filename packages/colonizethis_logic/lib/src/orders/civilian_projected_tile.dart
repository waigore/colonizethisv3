import 'package:colonizethis_models/colonizethis_models.dart';

/// Resolves the single projected tile for a civilian unit in UI surfaces.
///
/// Priority order matches map marker projection:
/// 1) pending draft work-order target tile for [playerId] (if any),
/// 2) non-empty [Unit.assignedTileKey],
/// 3) [Unit.tileKey].
String? projectedCivilianTileKey({
  required Unit unit,
  required String playerId,
  required Orders orders,
}) {
  final pending = pendingWorkOrderForUnit(
    playerId: playerId,
    unitId: unit.id,
    orders: orders,
  );
  if (pending != null) {
    final pendingTile = pending.targetTileKey;
    if (pendingTile.isNotEmpty) {
      return pendingTile;
    }
  }
  final assigned = unit.assignedTileKey;
  if (assigned != null && assigned.isNotEmpty) {
    return assigned;
  }
  return unit.tileKey;
}

/// Returns pending draft work order for one [unitId], if present.
WorkOrder? pendingWorkOrderForUnit({
  required String playerId,
  required String unitId,
  required Orders orders,
}) {
  final pending = orders.workOrdersByPlayerId[playerId] ?? const <WorkOrder>[];
  for (final order in pending) {
    if (order.unitId == unitId) {
      return order;
    }
  }
  return null;
}
