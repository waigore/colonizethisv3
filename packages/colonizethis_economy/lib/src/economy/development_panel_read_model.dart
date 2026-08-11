/// Empire Development panel read model. Refs #4175.
///
/// SPEC: SPEC/program/development-panel-read-model.md
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show Game, Orders;
import 'package:colonizethis_world/colonizethis_world.dart';

import 'development_panel_assigned_civilians.dart';
import 'development_panel_connectivity.dart';
import 'development_panel_model.dart';
import 'development_panel_read_model_scopes.dart';
import 'province_improvable_resource_counts.dart';

export 'development_panel_connectivity.dart';
export 'development_panel_model.dart';

/// Builds the empire Development panel read model from post-resolution state.
DevelopmentPanelModel buildDevelopmentPanelModel({
  required Game game,
  required String playerId,
  required Map<String, TileMapResult> tileMapByRegion,
  required MapTopology topology,
  required Orders currentOrders,
  required Map<String, String> provinceDisplayNamesById,
  required Map<String, String> playerDisplayNamesById,
  PlayerView? playerView,
}) {
  final shared = buildDevelopmentPanelBuildContext(
    game: game,
    playerId: playerId,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
    currentOrders: currentOrders,
  );
  return DevelopmentPanelModel(
    connectedTileKeys: shared.connectedTileKeys,
    oldWorld: buildDevelopmentPanelRegionModel(
      shared: shared,
      game: game,
      playerId: playerId,
      regionId: kRegionOldWorld,
      tileMapByRegion: tileMapByRegion,
      currentOrders: currentOrders,
      provinceDisplayNamesById: provinceDisplayNamesById,
      playerDisplayNamesById: playerDisplayNamesById,
      playerView: playerView,
    ),
    newWorld: buildDevelopmentPanelRegionModel(
      shared: shared,
      game: game,
      playerId: playerId,
      regionId: kRegionNewWorld,
      tileMapByRegion: tileMapByRegion,
      currentOrders: currentOrders,
      provinceDisplayNamesById: provinceDisplayNamesById,
      playerDisplayNamesById: playerDisplayNamesById,
      playerView: playerView,
    ),
  );
}

/// One region slice; call per visited tab on panel open (Slice E).
DevelopmentPanelRegionModel buildDevelopmentPanelRegionModel({
  required DevelopmentPanelBuildContext shared,
  required Game game,
  required String playerId,
  required String regionId,
  required Map<String, TileMapResult> tileMapByRegion,
  required Orders currentOrders,
  required Map<String, String> provinceDisplayNamesById,
  required Map<String, String> playerDisplayNamesById,
  PlayerView? playerView,
}) {
  return _buildRegionModel(
    game: game,
    playerId: playerId,
    regionId: regionId,
    tileMapByRegion: tileMapByRegion,
    landExtractionByCommodity: developmentExtractionProjectionForRegion(
      game: game,
      playerId: playerId,
      regionId: regionId,
      tileMapByRegion: tileMapByRegion,
      connectivity: shared.playerConnectivity,
    ),
    idleBuilderCount: shared.idleBuilderCount,
    idleEngineerCount: shared.idleEngineerCount,
    provinceDisplayNamesById: provinceDisplayNamesById,
    playerDisplayNamesById: playerDisplayNamesById,
    ownerCache: shared.ownerCache,
    currentOrders: currentOrders,
    playerView: playerView,
  );
}

DevelopmentPanelRegionModel _buildRegionModel({
  required Game game,
  required String playerId,
  required String regionId,
  required Map<String, TileMapResult> tileMapByRegion,
  required Map<String, int> landExtractionByCommodity,
  required int idleBuilderCount,
  required int idleEngineerCount,
  required Map<String, String> provinceDisplayNamesById,
  required Map<String, String> playerDisplayNamesById,
  required ProvinceOwnerCache ownerCache,
  required Orders currentOrders,
  PlayerView? playerView,
}) {
  final ownedProvinces =
      ownerCache.provincesOwnedByInRegion(playerId, regionId);
  final ownedScopes = <DevelopmentPanelScopeRow>[];
  for (final province in ownedProvinces) {
    final improvable = developmentImprovableRowsFromCounts(
      provinceImprovableResourceTileCounts(
        game: game,
        provinceId: province.id,
        ownerId: playerId,
        tileMapByRegion: tileMapByRegion,
      ),
      playerView: playerView,
    );
    ownedScopes.add(
      DevelopmentPanelScopeRow(
        scopeKey: province.id,
        provinceId: province.id,
        displayName:
            provinceDisplayNamesById[province.id] ?? province.id,
        improvableCommodities: improvable,
      ),
    );
  }

  final purchasedScopes = buildDevelopmentPurchasedScopes(
    game: game,
    playerId: playerId,
    regionId: regionId,
    tileMapByRegion: tileMapByRegion,
    provinceDisplayNamesById: provinceDisplayNamesById,
    playerDisplayNamesById: playerDisplayNamesById,
    ownerCache: ownerCache,
    playerView: playerView,
  );

  return DevelopmentPanelRegionModel(
    regionId: regionId,
    ownedScopes: ownedScopes,
    purchasedScopes: purchasedScopes,
    landExtractionByCommodity: landExtractionByCommodity,
    idleBuilderCount: idleBuilderCount,
    idleEngineerCount: idleEngineerCount,
    assignedCivilians: buildDevelopmentAssignedCiviliansForRegion(
      game: game,
      playerId: playerId,
      regionId: regionId,
      currentOrders: currentOrders,
    ),
  );
}
