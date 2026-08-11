/// Connectivity and shared build context for Development panel read model.
/// Refs #4175 Slice E.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show Game, kUnitTypeBuilder, kUnitTypeEngineer, Orders, UnitStatus;
import 'package:colonizethis_world/colonizethis_world.dart';

/// Shared inputs for per-region Development panel projections (Slice E).
class DevelopmentPanelBuildContext {
  const DevelopmentPanelBuildContext({
    required this.connectedTileKeys,
    required this.idleBuilderCount,
    required this.idleEngineerCount,
    required this.ownerCache,
    required this.playerConnectivity,
  });

  final Set<String> connectedTileKeys;
  final int idleBuilderCount;
  final int idleEngineerCount;
  final ProvinceOwnerCache ownerCache;
  final ConnectivityResult? playerConnectivity;
}

/// Connectivity for all players — depends on game + map only (not orders).
Map<String, ConnectivityResult> resolveDevelopmentPanelConnectivity({
  required Game game,
  required Map<String, TileMapResult> tileMapByRegion,
  required MapTopology topology,
}) {
  return resolveConnectivity(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
  );
}

/// Connectivity, idle counts, and owner cache — once per panel rebuild.
DevelopmentPanelBuildContext buildDevelopmentPanelBuildContext({
  required Game game,
  required String playerId,
  required Map<String, TileMapResult> tileMapByRegion,
  required MapTopology topology,
  required Orders currentOrders,
}) {
  return buildDevelopmentPanelBuildContextFromConnectivity(
    connectivity: resolveDevelopmentPanelConnectivity(
      game: game,
      tileMapByRegion: tileMapByRegion,
      topology: topology,
    ),
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
  );
}

/// Same as [buildDevelopmentPanelBuildContext] but reuses a precomputed
/// connectivity map (Slice E — avoid duplicate resolve on order-only churn).
DevelopmentPanelBuildContext buildDevelopmentPanelBuildContextFromConnectivity({
  required Map<String, ConnectivityResult> connectivity,
  required Game game,
  required String playerId,
  required Orders currentOrders,
}) {
  final pendingUnitIds = _pendingWorkUnitIds(currentOrders, playerId);
  final idleCounts = _countIdleCivilians(
    game: game,
    playerId: playerId,
    pendingUnitIds: pendingUnitIds,
  );
  return DevelopmentPanelBuildContext(
    connectedTileKeys:
        connectivity[playerId]?.connected ?? const <String>{},
    idleBuilderCount: idleCounts.builders,
    idleEngineerCount: idleCounts.engineers,
    ownerCache: ProvinceOwnerCache.of(game.worldState),
    playerConnectivity: connectivity[playerId],
  );
}

Set<String> _pendingWorkUnitIds(Orders orders, String playerId) {
  final pending = orders.workOrdersByPlayerId[playerId] ?? const [];
  return pending.map((o) => o.unitId).toSet();
}

({int builders, int engineers}) _countIdleCivilians({
  required Game game,
  required String playerId,
  required Set<String> pendingUnitIds,
}) {
  var builders = 0;
  var engineers = 0;
  for (final unit in [
    ...game.worldState.oldWorld.units,
    ...game.worldState.newWorld.units,
  ]) {
    if (unit.ownerId != playerId) continue;
    if (unit.status != UnitStatus.idle) continue;
    if (unit.currentWork != null) continue;
    if (pendingUnitIds.contains(unit.id)) continue;
    if (unit.type == kUnitTypeBuilder) {
      builders++;
    } else if (unit.type == kUnitTypeEngineer) {
      engineers++;
    }
  }
  return (builders: builders, engineers: engineers);
}
