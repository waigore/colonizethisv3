import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/widgets.dart';

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;
import '../caches/per_player_work_target_selection_cache.dart';
import '../map_state/game_map_area_state_logic.dart';
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;

/// Tile-keyed civilian work-order shortcut taps for MAP20001 (Refs #4534).
({
  VoidCallback? onExploreWithExplorerTap,
  VoidCallback? onProspectWithExplorerTap,
  VoidCallback? onBuildImprovementTap,
  VoidCallback? onBuildRoadTap,
  VoidCallback? onBuildFortTap,
  VoidCallback? onBuildPortTap,
  VoidCallback? onBuildRailroadTap,
  VoidCallback? onPurchaseLandTap,
})
buildProvinceDetailWorkShortcutTaps({
  required ct_models.Game game,
  required String humanPlayerId,
  required RegionMapViewData region,
  required PlayerView playerView,
  required PerPlayerWorkTargetSelectionCache workTargetSelectionCache,
  required ct_models.Orders draftOrders,
  required GameMapData? mapData,
  required String tileKey,
  required bool exploreEnabled,
  required bool prospectEnabled,
  required bool buildImprovementEnabled,
  required bool buildRoadEnabled,
  required bool buildFortEnabled,
  required bool buildPortEnabled,
  required bool buildRailEnabled,
  required bool purchaseLandEnabled,
  required ct_models.AppEventBus bus,
  required VoidCallback? Function({
    required bool enabled,
    required bool Function() revalidateEnabled,
    required void Function() emit,
  })
  shortcutTap,
}) {
  final topology = mapData?.combinedTopology;
  return (
    onExploreWithExplorerTap: shortcutTap(
      enabled: exploreEnabled,
      revalidateEnabled: () =>
          GameMapAreaStateLogicProvinceActions.provinceExploreActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            selectedTileKey: tileKey,
            selectedRegion: region,
            workTargetSelectionCache: workTargetSelectionCache,
          ).enabled,
      emit: () => bus.emit(
        ct_models.OpenCivilianUnitsPanelEvent(
          explorerOnly: true,
          exploreShortcutTargetTileKey: tileKey,
        ),
      ),
    ),
    onProspectWithExplorerTap: shortcutTap(
      enabled: prospectEnabled,
      revalidateEnabled: () =>
          GameMapAreaStateLogicProvinceActions.provinceProspectActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            selectedTileKey: tileKey,
            playerView: playerView,
            topology: topology,
            currentOrders: draftOrders,
            tileMapByRegion: mapData?.tileMapByRegion,
          ).enabled,
      emit: () => bus.emit(
        ct_models.OpenCivilianUnitsPanelEvent(
          explorerOnly: true,
          prospectShortcutTargetTileKey: tileKey,
        ),
      ),
    ),
    onBuildImprovementTap: shortcutTap(
      enabled: buildImprovementEnabled,
      revalidateEnabled: () =>
          GameMapAreaStateLogicProvinceActions.provinceBuildImprovementActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            selectedTileKey: tileKey,
            playerView: playerView,
            workTargetSelectionCache: workTargetSelectionCache,
          ).enabled,
      emit: () => bus.emit(
        ct_models.OpenCivilianUnitsPanelEvent(
          builderOnly: true,
          buildImprovementShortcutTargetTileKey: tileKey,
        ),
      ),
    ),
    onBuildRoadTap: shortcutTap(
      enabled: buildRoadEnabled,
      revalidateEnabled: () =>
          GameMapAreaStateLogicProvinceActions.provinceBuildRoadActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            selectedTileKey: tileKey,
            playerView: playerView,
            workTargetSelectionCache: workTargetSelectionCache,
          ).enabled,
      emit: () => bus.emit(
        ct_models.OpenCivilianUnitsPanelEvent(
          engineerOnly: true,
          buildRoadShortcutTargetTileKey: tileKey,
        ),
      ),
    ),
    onBuildFortTap: shortcutTap(
      enabled: buildFortEnabled,
      revalidateEnabled: () =>
          GameMapAreaStateLogicProvinceActions.provinceBuildFortActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            selectedTileKey: tileKey,
            playerView: playerView,
            workTargetSelectionCache: workTargetSelectionCache,
          ).enabled,
      emit: () => bus.emit(
        ct_models.OpenCivilianUnitsPanelEvent(
          engineerOnly: true,
          buildFortShortcutTargetTileKey: tileKey,
        ),
      ),
    ),
    onBuildPortTap: shortcutTap(
      enabled: buildPortEnabled,
      revalidateEnabled: () =>
          GameMapAreaStateLogicProvinceActions.provinceBuildPortActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            selectedTileKey: tileKey,
            playerView: playerView,
            workTargetSelectionCache: workTargetSelectionCache,
            topology: topology,
            currentOrders: draftOrders,
            tileMapByRegion: mapData?.tileMapByRegion,
          ).enabled,
      emit: () => bus.emit(
        ct_models.OpenCivilianUnitsPanelEvent(
          engineerOnly: true,
          buildPortShortcutTargetTileKey: tileKey,
        ),
      ),
    ),
    onBuildRailroadTap: shortcutTap(
      enabled: buildRailEnabled,
      revalidateEnabled: () =>
          GameMapAreaStateLogicProvinceActions.provinceBuildRailActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            selectedTileKey: tileKey,
            playerView: playerView,
            workTargetSelectionCache: workTargetSelectionCache,
            topology: topology,
            currentOrders: draftOrders,
            tileMapByRegion: mapData?.tileMapByRegion,
          ).enabled,
      emit: () => bus.emit(
        ct_models.OpenCivilianUnitsPanelEvent(
          railBuilderOnly: true,
          buildRailShortcutTargetTileKey: tileKey,
        ),
      ),
    ),
    onPurchaseLandTap: shortcutTap(
      enabled: purchaseLandEnabled,
      revalidateEnabled: () =>
          GameMapAreaStateLogicProvinceActions.provincePurchaseLandActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            selectedTileKey: tileKey,
            playerView: playerView,
            workTargetSelectionCache: workTargetSelectionCache,
          ).enabled,
      emit: () => bus.emit(
        ct_models.OpenCivilianUnitsPanelEvent(
          merchantOnly: true,
          purchaseLandShortcutTargetTileKey: tileKey,
        ),
      ),
    ),
  );
}
