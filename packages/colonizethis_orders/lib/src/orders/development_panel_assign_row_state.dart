import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'development_panel/idle_civilians.dart';
import 'development_panel/improve_tile_ordering.dart';
import 'development_panel_assign_candidate.dart';
import 'development_panel_assign_preview.dart';
import 'development_panel_assign_types.dart';

String? priorityTileForDevelopmentCommodity({
  required Game game,
  required String playerId,
  required Set<String> commodityTileKeys,
  required Set<String> connectedTileKeys,
  required TileMapState tileState,
  MapTopology? topology,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  if (commodityTileKeys.isEmpty) return null;
  return orderDevelopmentImproveTiles(
    game: game,
    playerId: playerId,
    tileKeys: commodityTileKeys,
    connectedTileKeys: connectedTileKeys,
    tileState: tileState,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
  ).first;
}

DevelopmentImproveAssignCandidate? hypotheticalDevelopmentAssignCandidate({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required Set<String> commodityTileKeys,
  required Set<String> connectedTileKeys,
  MapTopology? topology,
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  final builders = idleBuildersForDevelopmentAssign(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
  );
  if (builders.isEmpty) return null;
  final tileKey = priorityTileForDevelopmentCommodity(
    game: game,
    playerId: playerId,
    commodityTileKeys: commodityTileKeys,
    connectedTileKeys: connectedTileKeys,
    tileState: game.worldState.tileState,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
  );
  if (tileKey == null) return null;
  return enrichDevelopmentImproveAssignCandidate(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
    candidate: DevelopmentImproveAssignCandidate(
      builderUnitId: builders.first.id,
      targetTileKey: tileKey,
      isCapitalConnected: connectedTileKeys.contains(tileKey),
    ),
  );
}

/// Resolves Assign enablement for one improvable commodity row.
DevelopmentAssignRowState resolveDevelopmentAssignRowState({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required Set<String> commodityTileKeys,
  required Set<String> connectedTileKeys,
}) {
  if (commodityTileKeys.isEmpty) {
    return const DevelopmentAssignRowState(
      enabled: false,
      disabledReason: 'No improvable tiles',
    );
  }

  final builders = idleBuildersForDevelopmentAssign(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
  );
  if (builders.isEmpty) {
    return const DevelopmentAssignRowState(
      enabled: false,
      disabledReason: 'No idle Builders',
    );
  }

  final candidate = selectDevelopmentImproveAssignCandidate(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    commodityTileKeys: commodityTileKeys,
    connectedTileKeys: connectedTileKeys,
  );
  if (candidate != null) {
    if (!candidate.canAffordPreview) {
      return DevelopmentAssignRowState(
        enabled: false,
        disabledReason: 'Insufficient materials',
        candidate: candidate,
      );
    }
    return DevelopmentAssignRowState(enabled: true, candidate: candidate);
  }

  final hypothetical = hypotheticalDevelopmentAssignCandidate(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
    commodityTileKeys: commodityTileKeys,
    connectedTileKeys: connectedTileKeys,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
  );
  if (hypothetical == null) {
    return const DevelopmentAssignRowState(
      enabled: false,
      disabledReason: 'No valid assign target',
    );
  }

  if (!hypothetical.canAffordPreview) {
    return DevelopmentAssignRowState(
      enabled: false,
      disabledReason: 'Insufficient materials',
      candidate: hypothetical,
    );
  }

  return const DevelopmentAssignRowState(
    enabled: false,
    disabledReason: 'No valid assign target',
  );
}
