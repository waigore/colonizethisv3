import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/widgets.dart';

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;
import '../caches/per_player_work_target_selection_cache.dart';
import '../map_state/game_map_area_state_logic.dart';
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;
import 'province_detail_overlay_host_support_shortcuts_consulate.dart';
import 'province_detail_overlay_host_support_shortcuts_offer_peace.dart';
import 'province_detail_overlay_host_support_shortcuts_work.dart';

/// The three province-overlay shortcut `onTap` callbacks. Each entry is `null`
/// when its action is disabled or no tile is selected, matching the previous
/// inline `state.enabled && selectedTileKey != null ? ... : null` gating.
typedef ProvinceDetailShortcutCallbacks = ({
  VoidCallback? onExploreWithExplorerTap,
  VoidCallback? onProspectWithExplorerTap,
  VoidCallback? onBuildImprovementTap,
  VoidCallback? onBuildRoadTap,
  VoidCallback? onBuildFortTap,
  VoidCallback? onBuildPortTap,
  VoidCallback? onBuildRailroadTap,
  VoidCallback? onPurchaseLandTap,
  VoidCallback? onUpgradeTownTap,
  VoidCallback? onEstablishConsulateTap,
  VoidCallback? onOfferPeaceTap,
});

VoidCallback? _provinceDetailShortcutTap({
  required bool enabled,
  required bool Function() revalidateEnabled,
  required void Function() emit,
}) {
  if (!enabled) return null;
  return () {
    if (!revalidateEnabled()) return;
    emit();
  };
}

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
  required bool buildFortEnabled,
  required bool buildPortEnabled,
  required bool buildRailEnabled,
  required bool purchaseLandEnabled,
  required String provinceId,
  required bool upgradeTownEnabled,
  required String? upgradeTownTargetTileKey,
  required bool establishConsulateEnabled,
  required bool establishConsulatePending,
  required ct_models.DiplomaticOrder? establishConsulateOrder,
  required String establishConsulateTargetName,
  required bool isSeaZone,
  required bool offerPeaceEnabled,
  required bool offerPeacePending,
  required ct_models.DiplomaticOrder? offerPeaceOrder,
  required String offerPeaceTargetName,
  required ct_models.AppEventBus bus,
}) {
  final topology = mapData?.combinedTopology;
  final String? tileKey = selectedTileKey;
  final upgradeTownTap = upgradeTownTargetTileKey == null
      ? null
      : _provinceDetailShortcutTap(
          enabled: upgradeTownEnabled,
          revalidateEnabled: () =>
              GameMapAreaStateLogicProvinceActions.provinceUpgradeTownActionState(
                game: game,
                humanPlayerId: humanPlayerId,
                provinceId: provinceId,
                playerView: playerView,
                workTargetSelectionCache: workTargetSelectionCache,
                topology: topology,
                currentOrders: draftOrders,
                tileMapByRegion: mapData?.tileMapByRegion,
              ).enabled,
          emit: () => bus.emit(
            ct_models.OpenCivilianUnitsPanelEvent(
              builderOnly: true,
              upgradeTownShortcutTargetTileKey: upgradeTownTargetTileKey,
            ),
          ),
        );
  final establishConsulateTap = buildEstablishConsulateShortcutTap(
    game: game,
    humanPlayerId: humanPlayerId,
    provinceId: provinceId,
    draftOrders: draftOrders,
    topology: topology,
    enabled: establishConsulateEnabled,
    pending: establishConsulatePending,
    order: establishConsulateOrder,
    targetName: establishConsulateTargetName,
    bus: bus,
  );
  final offerPeaceTap = buildOfferPeaceShortcutTap(
    game: game,
    humanPlayerId: humanPlayerId,
    provinceId: provinceId,
    draftOrders: draftOrders,
    topology: topology,
    isSeaZone: isSeaZone,
    enabled: offerPeaceEnabled,
    pending: offerPeacePending,
    order: offerPeaceOrder,
    targetName: offerPeaceTargetName,
    bus: bus,
  );
  if (tileKey == null) {
    return (
      onExploreWithExplorerTap: null,
      onProspectWithExplorerTap: null,
      onBuildImprovementTap: null,
      onBuildRoadTap: null,
      onBuildFortTap: null,
      onBuildPortTap: null,
      onBuildRailroadTap: null,
      onPurchaseLandTap: null,
      onUpgradeTownTap: upgradeTownTap,
      onEstablishConsulateTap: establishConsulateTap,
      onOfferPeaceTap: offerPeaceTap,
    );
  }

  final workTaps = buildProvinceDetailWorkShortcutTaps(
    game: game,
    humanPlayerId: humanPlayerId,
    region: region,
    playerView: playerView,
    workTargetSelectionCache: workTargetSelectionCache,
    draftOrders: draftOrders,
    mapData: mapData,
    tileKey: tileKey,
    exploreEnabled: exploreEnabled,
    prospectEnabled: prospectEnabled,
    buildImprovementEnabled: buildImprovementEnabled,
    buildRoadEnabled: buildRoadEnabled,
    buildFortEnabled: buildFortEnabled,
    buildPortEnabled: buildPortEnabled,
    buildRailEnabled: buildRailEnabled,
    purchaseLandEnabled: purchaseLandEnabled,
    bus: bus,
    shortcutTap: _provinceDetailShortcutTap,
  );
  return (
    onExploreWithExplorerTap: workTaps.onExploreWithExplorerTap,
    onProspectWithExplorerTap: workTaps.onProspectWithExplorerTap,
    onBuildImprovementTap: workTaps.onBuildImprovementTap,
    onBuildRoadTap: workTaps.onBuildRoadTap,
    onBuildFortTap: workTaps.onBuildFortTap,
    onBuildPortTap: workTaps.onBuildPortTap,
    onBuildRailroadTap: workTaps.onBuildRailroadTap,
    onPurchaseLandTap: workTaps.onPurchaseLandTap,
    onUpgradeTownTap: upgradeTownTap,
    onEstablishConsulateTap: establishConsulateTap,
    onOfferPeaceTap: offerPeaceTap,
  );
}
