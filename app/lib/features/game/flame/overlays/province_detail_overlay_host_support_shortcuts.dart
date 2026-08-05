
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/widgets.dart';

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;
import '../caches/per_player_work_target_selection_cache.dart';
import '../map_state/game_map_area_state_logic.dart';
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;

/// The three province-overlay shortcut `onTap` callbacks. Each entry is `null`
/// when its action is disabled or no tile is selected, matching the previous
/// inline `state.enabled && selectedTileKey != null ? ... : null` gating.
typedef ProvinceDetailShortcutCallbacks = ({
  VoidCallback? onExploreWithExplorerTap,
  VoidCallback? onProspectWithExplorerTap,
  VoidCallback? onBuildImprovementTap,
  VoidCallback? onBuildRoadTap,
});

/// Builds the explore / prospect / build-improvement shortcut callbacks shared
/// by both province-detail overlay hosts.
///
/// Each callback re-validates its action state via [GameMapAreaStateLogic] at
/// tap time (guarding against stale enablement) and, only when still enabled,
/// emits an [ct_models.OpenCivilianUnitsPanelEvent] on [bus] carrying the
/// matching shortcut target tile key. The `*Enabled` flags mirror the hosts'
/// previous `state.enabled` gating (not the `canMutateViaUi`-gated icon flags,
/// which stay on the overlay's `show*`/`*ActionEnabled` props).
///
/// This introduces no new behavior: it forwards to the same logic entry points
/// with the same arguments the hosts used inline.
ProvinceDetailShortcutCallbacks buildProvinceDetailShortcutCallbacks({
  required ct_models.Game game,
  required String humanPlayerId,
  required RegionMapViewData region,
  required PlayerView playerView,
  required PerPlayerWorkTargetSelectionCache workTargetSelectionCache,
  required ct_models.Orders draftOrders,
  required GameMapData? mapData,
  required String? selectedTileKey,
  required bool exploreEnabled,
  required bool prospectEnabled,
  required bool buildImprovementEnabled,
  required bool buildRoadEnabled,
  required ct_models.AppEventBus bus,
}) {
  final String? tileKey = selectedTileKey;
  if (tileKey == null) {
    return (
      onExploreWithExplorerTap: null,
      onProspectWithExplorerTap: null,
      onBuildImprovementTap: null,
      onBuildRoadTap: null,
    );
  }
  final topology = mapData?.combinedTopology;

  VoidCallback? onExplore;
  if (exploreEnabled) {
    onExplore = () {
      final revalidated = GameMapAreaStateLogic.provinceExploreActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        selectedTileKey: tileKey,
        selectedRegion: region,
        workTargetSelectionCache: workTargetSelectionCache,
      );
      if (!revalidated.enabled) {
        return;
      }
      bus.emit(
        ct_models.OpenCivilianUnitsPanelEvent(
          explorerOnly: true,
          exploreShortcutTargetTileKey: tileKey,
        ),
      );
    };
  }

  VoidCallback? onProspect;
  if (prospectEnabled) {
    onProspect = () {
      final revalidated = GameMapAreaStateLogic.provinceProspectActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        selectedTileKey: tileKey,
        playerView: playerView,
        topology: topology,
        currentOrders: draftOrders,
        tileMapByRegion: mapData?.tileMapByRegion,
      );
      if (!revalidated.enabled) {
        return;
      }
      bus.emit(
        ct_models.OpenCivilianUnitsPanelEvent(
          explorerOnly: true,
          prospectShortcutTargetTileKey: tileKey,
        ),
      );
    };
  }

  VoidCallback? onBuildImprovement;
  if (buildImprovementEnabled) {
    onBuildImprovement = () {
      final revalidated =
          GameMapAreaStateLogic.provinceBuildImprovementActionState(
            game: game,
            humanPlayerId: humanPlayerId,
            selectedTileKey: tileKey,
            playerView: playerView,
            workTargetSelectionCache: workTargetSelectionCache,
          );
      if (!revalidated.enabled) {
        return;
      }
      bus.emit(
        ct_models.OpenCivilianUnitsPanelEvent(
          builderOnly: true,
          buildImprovementShortcutTargetTileKey: tileKey,
        ),
      );
    };
  }

  VoidCallback? onBuildRoad;
  if (buildRoadEnabled) {
    onBuildRoad = () {
      final revalidated = GameMapAreaStateLogic.provinceBuildRoadActionState(
        game: game,
        humanPlayerId: humanPlayerId,
        selectedTileKey: tileKey,
        playerView: playerView,
        workTargetSelectionCache: workTargetSelectionCache,
      );
      if (!revalidated.enabled) {
        return;
      }
      bus.emit(
        ct_models.OpenCivilianUnitsPanelEvent(
          engineerOnly: true,
          buildRoadShortcutTargetTileKey: tileKey,
        ),
      );
    };
  }

  return (
    onExploreWithExplorerTap: onExplore,
    onProspectWithExplorerTap: onProspect,
    onBuildImprovementTap: onBuildImprovement,
    onBuildRoadTap: onBuildRoad,
  );
}
