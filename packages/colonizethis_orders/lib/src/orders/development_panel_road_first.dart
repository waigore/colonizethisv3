/// Development panel Road first Engineer assign helpers. Refs #4175 Slice C.
///
/// SPEC: SPEC/ui/development-panel.md, SPEC/game/capital-and-connectivity.md
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'development_panel/idle_civilians.dart';
import 'development_panel/material_affordance.dart';
import 'development_panel_pass_context.dart';
import 'order_suggestion_context.dart';
import 'order_work_constants.dart';
import 'owned_tile_graph.dart';
import 'work_tile_candidacy/work_tile_candidacy.dart';

export 'development_panel/idle_civilians.dart'
    show idleEngineersForDevelopmentAssign;
export 'owned_tile_graph.dart' show shortestOwnedTilePathToConnectedNetwork;

/// Selected Engineer + tile for a pending `build_road` Road-first gesture.
class DevelopmentRoadFirstCandidate {
  const DevelopmentRoadFirstCandidate({
    required this.engineerUnitId,
    required this.targetTileKey,
  });

  final String engineerUnitId;
  final String targetTileKey;

  WorkOrder toWorkOrder() => WorkOrder(
    unitId: engineerUnitId,
    target: kWorkTargetBuildRoad,
    targetTileKey: targetTileKey,
  );
}

/// Road-first affordance for the disconnected improve warn dialog.
class DevelopmentRoadFirstState {
  const DevelopmentRoadFirstState({
    required this.enabled,
    this.disabledReason,
    this.candidate,
  });

  final bool enabled;
  final String? disabledReason;
  final DevelopmentRoadFirstCandidate? candidate;
}

bool _canAffordDevelopmentRoadFirst({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required DevelopmentRoadFirstCandidate candidate,
}) {
  return canAffordDevelopmentWorkOrder(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
    workTarget: kWorkTargetBuildRoad,
    targetTileKey: candidate.targetTileKey,
  );
}

DevelopmentRoadFirstCandidate? selectDevelopmentRoadFirstCandidate({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required String improveTargetTileKey,
  required Set<String> connectedTileKeys,
}) {
  if (connectedTileKeys.contains(improveTargetTileKey)) return null;

  final engineers = idleEngineersForDevelopmentAssign(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
  );
  if (engineers.isEmpty) return null;

  final path = shortestOwnedTilePathToConnectedNetwork(
    game: game,
    playerId: playerId,
    startTileKey: improveTargetTileKey,
    connectedTileKeys: connectedTileKeys,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
  );
  if (path == null || path.length < 2) return null;

  final pass = DevelopmentPanelPassContext.fromPlayerView(
    game: game,
    topology: topology,
    playerId: playerId,
    currentOrders: currentOrders,
    tileMapByRegion: tileMapByRegion,
  );

  final roadCandidates = <String>[
    for (var i = path.length - 2; i >= 0; i--) path[i],
  ];

  for (final engineer in engineers) {
    final validTiles = getValidWorkOrderTileKeysWithVisibility(
      game: game,
      topology: topology,
      view: pass.view,
      unitId: engineer.id,
      workTarget: kWorkTargetBuildRoad,
      currentOrders: currentOrders,
      tileMapByRegion: tileMapByRegion,
      sharedCandidateValidator: pass.candidateValidator,
      resolution: pass.resolution,
    );
    for (final tileKey in roadCandidates) {
      if (!validTiles.contains(tileKey)) continue;
      return DevelopmentRoadFirstCandidate(
        engineerUnitId: engineer.id,
        targetTileKey: tileKey,
      );
    }
  }
  return null;
}

/// Resolves Road-first enablement for the disconnected improve warn dialog.
DevelopmentRoadFirstState resolveDevelopmentRoadFirstState({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  required String improveTargetTileKey,
  required Set<String> connectedTileKeys,
}) {
  final engineers = idleEngineersForDevelopmentAssign(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
  );
  if (engineers.isEmpty) {
    return const DevelopmentRoadFirstState(
      enabled: false,
      disabledReason: 'No idle Engineers',
    );
  }

  final path = shortestOwnedTilePathToConnectedNetwork(
    game: game,
    playerId: playerId,
    startTileKey: improveTargetTileKey,
    connectedTileKeys: connectedTileKeys,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
  );
  if (path == null) {
    return const DevelopmentRoadFirstState(
      enabled: false,
      disabledReason: 'No owned path to capital connection',
    );
  }

  final candidate = selectDevelopmentRoadFirstCandidate(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    improveTargetTileKey: improveTargetTileKey,
    connectedTileKeys: connectedTileKeys,
  );
  if (candidate == null) {
    return const DevelopmentRoadFirstState(
      enabled: false,
      disabledReason: 'No legal road step toward capital',
    );
  }

  if (!_canAffordDevelopmentRoadFirst(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
    candidate: candidate,
  )) {
    return DevelopmentRoadFirstState(
      enabled: false,
      disabledReason: 'Insufficient materials',
      candidate: candidate,
    );
  }

  return DevelopmentRoadFirstState(enabled: true, candidate: candidate);
}
