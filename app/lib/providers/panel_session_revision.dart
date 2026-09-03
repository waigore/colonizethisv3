import 'package:colonizethis_models/colonizethis_models.dart';

/// World-state revision hash shared by panel session caches (Refs #4720 Slice A).
int panelWorldRevision(Game game) {
  return Object.hash(
    game.worldState.turnState.turnNumber,
    game.worldState.purchasedTilesByTileKey.length,
    game.worldState.tileKeysByRegionAndProvince.length,
    game.players.length,
  );
}

/// Draft-orders revision hash shared by panel session caches (Refs #4720 Slice A).
int panelOrdersRevision(Orders orders) {
  final workHashes = <int>[];
  for (final entry in orders.workOrdersByPlayerId.entries) {
    workHashes.add(Object.hash(entry.key, entry.value.length));
    for (final order in entry.value) {
      workHashes.add(
        Object.hash(order.unitId, order.target, order.targetTileKey),
      );
    }
  }
  workHashes.sort();
  return Object.hashAll(workHashes);
}
