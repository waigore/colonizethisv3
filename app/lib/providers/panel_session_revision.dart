import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared static session identity for panel / overlay caches (Refs #4734).
typedef PanelStaticSessionRevision = ({
  String gameId,
  int turnNumber,
  int worldRevision,
});

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

/// Sole constructor of `{gameId, turnNumber, worldRevision}` under `app/lib/` (Refs #4734).
PanelStaticSessionRevision panelStaticSessionRevision(Game game) {
  return (
    gameId: game.id,
    turnNumber: game.worldState.turnState.turnNumber,
    worldRevision: panelWorldRevision(game),
  );
}

/// Topology-node revision shared by counsel / trade / diplomacy caches (Refs #4734).
///
/// Hashes `topology.nodes` in list iteration order (not sorted).
int panelTopologyRevision(MapTopology topology) {
  return Object.hashAll(topology.nodes.map((node) => node.id));
}
