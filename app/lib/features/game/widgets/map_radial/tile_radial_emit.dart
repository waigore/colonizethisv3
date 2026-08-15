/// Commit paths for MAP30001 / MAP30002 catalog spokes (Refs #4440).
library;

import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;
import '../../flame/caches/per_player_work_target_selection_cache.dart';
import '../../flame/map_state/game_map_area_state_logic.dart';
import 'tile_radial_catalog.dart';

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
        tileMapByRegion: mapData?.tileMapByRegion,
      ).enabled,
    TileRadialCatalogAction.buildImprovement =>
      GameMapAreaStateLogicProvinceActions.provinceBuildImprovementActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        selectedTileKey: tileKey,
        playerView: playerView,
        workTargetSelectionCache: workTargetSelectionCache,
      ).enabled,
  };
  if (!enabled) return;
  bus.emit(tileRadialCatalogPanelEvent(action, tileKey));
}
