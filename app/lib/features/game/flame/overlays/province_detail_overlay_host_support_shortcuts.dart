part of 'province_detail_overlay_host_support.dart';

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
  required ct_models.AppEventBus bus,
}) {
  final String? tileKey = selectedTileKey;
  if (tileKey == null) {
    return (
      onExploreWithExplorerTap: null,
      onProspectWithExplorerTap: null,
      onBuildImprovementTap: null,
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

  return (
    onExploreWithExplorerTap: onExplore,
    onProspectWithExplorerTap: onProspect,
    onBuildImprovementTap: onBuildImprovement,
  );
}
