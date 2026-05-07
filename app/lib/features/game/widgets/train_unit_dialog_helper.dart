import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared train-dialog helper for order/count orchestration.
///
/// Used by both `TrainCiviliansDialog` and `TrainMilitaryDialog` to keep
/// count initialization and order materialization logic consistent.
Map<String, int> initialTrainDialogCountsFromOrders({
  required Iterable<String> unitTypeIds,
  required Orders currentOrders,
  required String humanPlayerId,
  required String? capitalProvinceId,
  required bool isMilitary,
}) {
  final next = {for (final id in unitTypeIds) id: 0};
  if (capitalProvinceId == null) return next;
  final allowedUnitTypes = unitTypeIds.toSet();
  final list =
      currentOrders.buildUnitOrdersByPlayerId[humanPlayerId] ??
      const <BuildUnitOrder>[];
  for (final order in list) {
    if (order.isMilitary != isMilitary) continue;
    if (!allowedUnitTypes.contains(order.unitType)) continue;
    if (order.spawnProvinceId != capitalProvinceId) continue;
    next[order.unitType] = (next[order.unitType] ?? 0) + 1;
  }
  return next;
}

List<BuildUnitOrder> materializeTrainDialogOrdersFromCounts({
  required Iterable<String> orderedUnitTypeIds,
  required Map<String, int> counts,
  required String? capitalProvinceId,
  required bool isMilitary,
}) {
  if (capitalProvinceId == null) return const <BuildUnitOrder>[];
  final orders = <BuildUnitOrder>[];
  for (final unitType in orderedUnitTypeIds) {
    final count = counts[unitType] ?? 0;
    for (var i = 0; i < count; i++) {
      orders.add(
        BuildUnitOrder(
          unitType: unitType,
          isMilitary: isMilitary,
          spawnProvinceId: capitalProvinceId,
        ),
      );
    }
  }
  return orders;
}

Map<String, int> incrementTrainDialogCount(Map<String, int> counts, String id) {
  return {...counts, id: (counts[id] ?? 0) + 1};
}

Map<String, int> decrementTrainDialogCount(Map<String, int> counts, String id) {
  final current = counts[id] ?? 0;
  if (current <= 0) return counts;
  return {...counts, id: current - 1};
}

Map<String, int> resetTrainDialogCounts(Map<String, int> counts) {
  return {for (final id in counts.keys) id: 0};
}

Player? trainDialogPlayerById({
  required Iterable<Player> players,
  required String playerId,
}) {
  for (final player in players) {
    if (player.id == playerId) return player;
  }
  return null;
}

bool trainDialogHasCapital(Player? player) {
  return player?.capitalProvinceId != null;
}

int trainDialogTreasury(Player? player) {
  return player?.treasury ?? 0;
}

Map<String, bool> trainDialogTechUnlocked(Player? player) {
  return player?.techUnlocked ?? const {};
}

bool trainDialogIsLocked({
  required String unitType,
  required Map<String, String> unlockingTechByUnitType,
  required Map<String, bool> techUnlocked,
}) {
  final techId = unlockingTechByUnitType[unitType];
  if (techId == null) return false;
  return techUnlocked[techId] != true;
}
