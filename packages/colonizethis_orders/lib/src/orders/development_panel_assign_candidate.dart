import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'development_panel/idle_civilians.dart';
import 'development_panel/improve_tile_ordering.dart';
import 'development_panel_pass_context.dart';
import 'development_panel_assign_preview.dart';
import 'development_panel_assign_types.dart';
import 'order_work_constants.dart';
import 'work_tile_candidacy/work_tile_candidacy.dart';

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

    return enrichDevelopmentImproveAssignCandidate(
      game: game,
      playerId: playerId,
      currentOrders: currentOrders,
      candidate: DevelopmentImproveAssignCandidate(
        builderUnitId: builder.id,
        targetTileKey: bestTile,
        isCapitalConnected: connectedTileKeys.contains(bestTile),
      ),
    );
  }
  return null;
}
