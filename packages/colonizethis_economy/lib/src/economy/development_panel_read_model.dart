/// Empire Development panel read model. Refs #4175.
///
/// SPEC: SPEC/program/development-panel-read-model.md
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart'
    show
        Game,
        kUnitTypeBuilder,
        kUnitTypeEngineer,
        Orders,
        UnitStatus;
import 'package:colonizethis_world/colonizethis_world.dart';

import 'development_panel_assigned_civilians.dart';
import 'development_panel_model.dart';
import 'development_panel_read_model_scopes.dart';
import 'development_panel_visibility.dart';
import 'game_lookup_helpers.dart';
import 'province_improvable_resource_counts.dart';

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
  final connectivity = resolveConnectivity(
    game: game,
    tileMapByRegion: tileMapByRegion,
    topology: topology,
  );
  final pendingUnitIds = _pendingWorkUnitIds(currentOrders, playerId);
  final idleCounts = _countIdleCivilians(
    game: game,
    playerId: playerId,
    pendingUnitIds: pendingUnitIds,
  );

  final ownerCache = ProvinceOwnerCache.of(game.worldState);

  return DevelopmentPanelModel(
    oldWorld: _buildRegionModel(
      game: game,
      playerId: playerId,
      regionId: kRegionOldWorld,
      tileMapByRegion: tileMapByRegion,
      landExtractionByCommodity: developmentExtractionProjectionForRegion(
        game: game,
        playerId: playerId,
        regionId: kRegionOldWorld,
        tileMapByRegion: tileMapByRegion,
        connectivity: connectivity[playerId],
      ),
      idleBuilderCount: idleCounts.builders,
      idleEngineerCount: idleCounts.engineers,
      provinceDisplayNamesById: provinceDisplayNamesById,
      playerDisplayNamesById: playerDisplayNamesById,
      ownerCache: ownerCache,
      currentOrders: currentOrders,
      playerView: playerView,
    ),
    newWorld: _buildRegionModel(
      game: game,
      playerId: playerId,
      regionId: kRegionNewWorld,
      tileMapByRegion: tileMapByRegion,
      landExtractionByCommodity: developmentExtractionProjectionForRegion(
        game: game,
        playerId: playerId,
        regionId: kRegionNewWorld,
        tileMapByRegion: tileMapByRegion,
        connectivity: connectivity[playerId],
      ),
      idleBuilderCount: idleCounts.builders,
      idleEngineerCount: idleCounts.engineers,
      provinceDisplayNamesById: provinceDisplayNamesById,
      playerDisplayNamesById: playerDisplayNamesById,
      ownerCache: ownerCache,
      currentOrders: currentOrders,
      playerView: playerView,
    ),
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
