/// Commit paths for MAP30001 / MAP30002 catalog spokes (Refs #4440, #4570).
library;

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;
import '../../flame/caches/per_player_work_target_selection_cache.dart';
import '../../flame/map_state/game_map_area_state_logic.dart';
import 'tile_radial_catalog.dart';

String? _provinceIdFromTileKey(String tileKey) {
  final parts = tileKey.split('|');
  if (parts.length < 2) return null;
  return '${parts[0]}|${parts[1]}';
}

/// Same [OpenCivilianUnitsPanelEvent] fields as MAP20001 Tile shortcuts.
ct_models.OpenCivilianUnitsPanelEvent tileRadialCatalogPanelEvent(
  TileRadialCatalogAction action,
  String tileKey,
) {
  switch (action) {
    case TileRadialCatalogAction.explore:
      return ct_models.OpenCivilianUnitsPanelEvent(
        explorerOnly: true,
        exploreShortcutTargetTileKey: tileKey,
      );
    case TileRadialCatalogAction.prospect:
      return ct_models.OpenCivilianUnitsPanelEvent(
        explorerOnly: true,
        prospectShortcutTargetTileKey: tileKey,
      );
    case TileRadialCatalogAction.buildImprovement:
      return ct_models.OpenCivilianUnitsPanelEvent(
        builderOnly: true,
        buildImprovementShortcutTargetTileKey: tileKey,
      );
    case TileRadialCatalogAction.buildRoad:
      return ct_models.OpenCivilianUnitsPanelEvent(
        engineerOnly: true,
        buildRoadShortcutTargetTileKey: tileKey,
      );
    case TileRadialCatalogAction.purchaseLand:
      return ct_models.OpenCivilianUnitsPanelEvent(
        merchantOnly: true,
        purchaseLandShortcutTargetTileKey: tileKey,
      );
    case TileRadialCatalogAction.upgradeTown:
      return ct_models.OpenCivilianUnitsPanelEvent(
        builderOnly: true,
        upgradeTownShortcutTargetTileKey: tileKey,
      );
    case TileRadialCatalogAction.buildPort:
      return ct_models.OpenCivilianUnitsPanelEvent(
        engineerOnly: true,
        buildPortShortcutTargetTileKey: tileKey,
      );
    case TileRadialCatalogAction.buildRail:
      return ct_models.OpenCivilianUnitsPanelEvent(
        railBuilderOnly: true,
        buildRailShortcutTargetTileKey: tileKey,
      );
    case TileRadialCatalogAction.buildFort:
      return ct_models.OpenCivilianUnitsPanelEvent(
        engineerOnly: true,
        buildFortShortcutTargetTileKey: tileKey,
      );
  }
}

/// Re-validates overlay enablement and emits the matching civilian shortcut.
void emitTileRadialCatalogAction({
  required TileRadialCatalogAction action,
  required String tileKey,
  required ct_models.Game game,
  required String humanPlayerId,
  required RegionMapViewData region,
  required PlayerView playerView,
  required PerPlayerWorkTargetSelectionCache workTargetSelectionCache,
  required ct_models.Orders draftOrders,
  required GameMapData? mapData,
  required ct_models.AppEventBus bus,
}) {
  final topology = mapData?.combinedTopology;
  final tileMapByRegion = mapData?.tileMapByRegion;
  final provinceId = _provinceIdFromTileKey(tileKey);
  final enabled = switch (action) {
    TileRadialCatalogAction.explore =>
      GameMapAreaStateLogicProvinceActions.provinceExploreActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        selectedTileKey: tileKey,
        selectedRegion: region,
        workTargetSelectionCache: workTargetSelectionCache,
      ).enabled,
    TileRadialCatalogAction.prospect =>
      GameMapAreaStateLogicProvinceActions.provinceProspectActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        selectedTileKey: tileKey,
        playerView: playerView,
        topology: topology,
        currentOrders: draftOrders,
        tileMapByRegion: tileMapByRegion,
      ).enabled,
    TileRadialCatalogAction.buildImprovement =>
      GameMapAreaStateLogicProvinceActions.provinceBuildImprovementActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        selectedTileKey: tileKey,
        playerView: playerView,
        workTargetSelectionCache: workTargetSelectionCache,
      ).enabled,
    TileRadialCatalogAction.buildRoad =>
      GameMapAreaStateLogicProvinceActions.provinceBuildRoadActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        selectedTileKey: tileKey,
        playerView: playerView,
        workTargetSelectionCache: workTargetSelectionCache,
        topology: topology,
        currentOrders: draftOrders,
        tileMapByRegion: tileMapByRegion,
      ).enabled,
    TileRadialCatalogAction.purchaseLand =>
      GameMapAreaStateLogicProvinceActions.provincePurchaseLandActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        selectedTileKey: tileKey,
        playerView: playerView,
        workTargetSelectionCache: workTargetSelectionCache,
        topology: topology,
        currentOrders: draftOrders,
        tileMapByRegion: tileMapByRegion,
      ).enabled,
    TileRadialCatalogAction.upgradeTown => () {
      if (provinceId == null) return false;
      final state =
          GameMapAreaStateLogicProvinceActions.provinceUpgradeTownActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            provinceId: provinceId,
            playerView: playerView,
            workTargetSelectionCache: workTargetSelectionCache,
            topology: topology,
            currentOrders: draftOrders,
            tileMapByRegion: tileMapByRegion,
          );
      return state.enabled && state.townTileKey == tileKey;
    }(),
    TileRadialCatalogAction.buildPort =>
      GameMapAreaStateLogicProvinceActions.provinceBuildPortActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        selectedTileKey: tileKey,
        playerView: playerView,
        workTargetSelectionCache: workTargetSelectionCache,
        topology: topology,
        currentOrders: draftOrders,
        tileMapByRegion: tileMapByRegion,
      ).enabled,
    TileRadialCatalogAction.buildRail =>
      GameMapAreaStateLogicProvinceActions.provinceBuildRailActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        selectedTileKey: tileKey,
        playerView: playerView,
        workTargetSelectionCache: workTargetSelectionCache,
        topology: topology,
        currentOrders: draftOrders,
        tileMapByRegion: tileMapByRegion,
      ).enabled,
    TileRadialCatalogAction.buildFort =>
      GameMapAreaStateLogicProvinceActions.provinceBuildFortActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        selectedTileKey: tileKey,
        playerView: playerView,
        workTargetSelectionCache: workTargetSelectionCache,
        topology: topology,
        currentOrders: draftOrders,
        tileMapByRegion: tileMapByRegion,
      ).enabled,
  };
  if (!enabled) return;
  final emitTileKey = action == TileRadialCatalogAction.upgradeTown
      ? (GameMapAreaStateLogicProvinceActions.provinceUpgradeTownActionState(
              game: game,
              humanPlayerId: humanPlayerId,
              provinceId: provinceId!,
              playerView: playerView,
              workTargetSelectionCache: workTargetSelectionCache,
              topology: topology,
              currentOrders: draftOrders,
              tileMapByRegion: tileMapByRegion,
            ).townTileKey ??
            tileKey)
      : tileKey;
  bus.emit(tileRadialCatalogPanelEvent(action, emitTileKey));
}
