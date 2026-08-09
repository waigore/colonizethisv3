/// Development panel one-tap Builder improve assign helpers. Refs #4175 Slice B.
///
/// SPEC: SPEC/ui/development-panel.md, SPEC/program/development-panel-read-model.md
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'development_panel/idle_civilians.dart';
import 'development_panel/improve_tile_ordering.dart';
import 'development_panel/material_affordance.dart';
import 'development_panel_pass_context.dart';
import 'order_suggestion_context.dart';
import 'order_work_constants.dart';
import 'work_tile_candidacy/work_tile_candidacy.dart';

export 'development_panel/idle_civilians.dart'
    show
        idleBuildersForDevelopmentAssign,
        idleDevelopmentCiviliansForAssign;
export 'development_panel/improve_tile_ordering.dart'
    show
        compareDevelopmentImproveTilePriority,
        orderDevelopmentImproveTiles,
        sortedDevelopmentImproveTileCandidates;
export 'development_panel/material_affordance.dart'
    show effectiveStockpileAfterPendingDevelopmentMaterialWork;

/// Selected Builder + tile for a pending `build_improvement` assign.
class DevelopmentImproveAssignCandidate {
  const DevelopmentImproveAssignCandidate({
    required this.builderUnitId,
    required this.targetTileKey,
    required this.isCapitalConnected,
  });

  final String builderUnitId;
  final String targetTileKey;
  final bool isCapitalConnected;

  WorkOrder toWorkOrder() => WorkOrder(
    unitId: builderUnitId,
    target: kWorkTargetBuildImprovement,
    targetTileKey: targetTileKey,
  );
}

/// Assign row affordance for one improvable commodity row.
class DevelopmentAssignRowState {
  const DevelopmentAssignRowState({
    required this.enabled,
    this.disabledReason,
    this.candidate,
  });

  final bool enabled;
  final String? disabledReason;
  final DevelopmentImproveAssignCandidate? candidate;
}

String? _priorityTileForCommodity({
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

DevelopmentImproveAssignCandidate? _hypotheticalAssignCandidate({
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
  final tileKey = _priorityTileForCommodity(
    game: game,
    playerId: playerId,
    commodityTileKeys: commodityTileKeys,
    connectedTileKeys: connectedTileKeys,
    tileState: game.worldState.tileState,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
  );
  if (tileKey == null) return null;
  return DevelopmentImproveAssignCandidate(
    builderUnitId: builders.first.id,
    targetTileKey: tileKey,
    isCapitalConnected: connectedTileKeys.contains(tileKey),
  );
}

DevelopmentImproveAssignCandidate? selectDevelopmentImproveAssignCandidate({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required Set<String> commodityTileKeys,
  required Set<String> connectedTileKeys,
}) {
  if (commodityTileKeys.isEmpty) return null;

  final builders = idleBuildersForDevelopmentAssign(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
  );
  if (builders.isEmpty) return null;

  final pass = DevelopmentPanelPassContext.fromPlayerView(
    game: game,
    topology: topology,
    playerId: playerId,
    currentOrders: currentOrders,
    tileMapByRegion: tileMapByRegion,
  );
  final tileState = game.worldState.tileState;

  for (final builder in builders) {
    final validTiles = getValidWorkOrderTileKeysWithVisibility(
      game: game,
      topology: topology,
      view: pass.view,
      unitId: builder.id,
      workTarget: kWorkTargetBuildImprovement,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
      sharedCandidateValidator: pass.candidateValidator,
      resolution: pass.resolution,
    );
    final scoped = validTiles.where(commodityTileKeys.contains).toSet();
    if (scoped.isEmpty) continue;

    final bestTile = orderDevelopmentImproveTiles(
      game: game,
      playerId: playerId,
      tileKeys: scoped,
      connectedTileKeys: connectedTileKeys,
      tileState: tileState,
      topology: topology,
      tileMapByRegion: tileMapByRegion,
    ).first;

    return DevelopmentImproveAssignCandidate(
      builderUnitId: builder.id,
      targetTileKey: bestTile,
      isCapitalConnected: connectedTileKeys.contains(bestTile),
    );
  }
  return null;
}

bool _canAffordDevelopmentImproveAssign({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required DevelopmentImproveAssignCandidate candidate,
}) {
  return canAffordDevelopmentWorkOrder(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
    workTarget: kWorkTargetBuildImprovement,
    targetTileKey: candidate.targetTileKey,
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
    if (!_canAffordDevelopmentImproveAssign(
      game: game,
      playerId: playerId,
      currentOrders: currentOrders,
      candidate: candidate,
    )) {
      return DevelopmentAssignRowState(
        enabled: false,
        disabledReason: 'Insufficient materials',
        candidate: candidate,
      );
    }
    return DevelopmentAssignRowState(enabled: true, candidate: candidate);
  }

  final hypothetical = _hypotheticalAssignCandidate(
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

  if (!_canAffordDevelopmentImproveAssign(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
    candidate: hypothetical,
  )) {
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

/// Commodity ids with at least one improvable row blocked by materials shortage.
Set<String> developmentPanelMaterialShortageCommodityIds({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required Iterable<({String commodityId, Set<String> tileKeys})> improvableRows,
  required Set<String> connectedTileKeys,
}) {
  final shortages = <String>{};
  for (final row in improvableRows) {
    final state = resolveDevelopmentAssignRowState(
      game: game,
      playerId: playerId,
      currentOrders: currentOrders,
      topology: topology,
      tileMapByRegion: tileMapByRegion,
      commodityTileKeys: row.tileKeys,
      connectedTileKeys: connectedTileKeys,
    );
    if (state.disabledReason == 'Insufficient materials') {
      shortages.add(row.commodityId);
    }
  }
  return shortages;
}
