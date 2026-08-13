import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart'
    show buildDiplomacyConfirmPreviewMessage;
import 'package:flutter/widgets.dart';

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;
import '../caches/per_player_work_target_selection_cache.dart';
import '../map_state/game_map_area_state_logic.dart';
import '../../widgets/diplomacy/diplomacy_order_helpers.dart'
    show diplomacyActionLabel;
import 'package:colonizethis_world/colonizethis_world.dart' show PlayerView;

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
  VoidCallback? onPurchaseLandTap,
  VoidCallback? onUpgradeTownTap,
  VoidCallback? onEstablishConsulateTap,
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
  required bool purchaseLandEnabled,
  required String provinceId,
  required bool upgradeTownEnabled,
  required String? upgradeTownTargetTileKey,
  required bool establishConsulateEnabled,
  required bool establishConsulatePending,
  required ct_models.DiplomaticOrder? establishConsulateOrder,
  required String establishConsulateTargetName,
  required ct_models.AppEventBus bus,
}) {
  final topology = mapData?.combinedTopology;
  final String? tileKey = selectedTileKey;
  final upgradeTownTap = upgradeTownTargetTileKey == null
      ? null
      : _provinceDetailShortcutTap(
          enabled: upgradeTownEnabled,
          revalidateEnabled: () =>
              GameMapAreaStateLogic.provinceUpgradeTownActionState(
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
  final establishConsulateTap = _establishConsulateTap(
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
  if (tileKey == null) {
    return (
      onExploreWithExplorerTap: null,
      onProspectWithExplorerTap: null,
      onBuildImprovementTap: null,
      onBuildRoadTap: null,
      onBuildFortTap: null,
      onBuildPortTap: null,
      onPurchaseLandTap: null,
      onUpgradeTownTap: upgradeTownTap,
      onEstablishConsulateTap: establishConsulateTap,
    );
  }

  return (
    onExploreWithExplorerTap: _provinceDetailShortcutTap(
      enabled: exploreEnabled,
      revalidateEnabled: () => GameMapAreaStateLogic.provinceExploreActionState(
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
    onProspectWithExplorerTap: _provinceDetailShortcutTap(
      enabled: prospectEnabled,
      revalidateEnabled: () =>
          GameMapAreaStateLogic.provinceProspectActionState(
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
    onBuildImprovementTap: _provinceDetailShortcutTap(
      enabled: buildImprovementEnabled,
      revalidateEnabled: () =>
          GameMapAreaStateLogic.provinceBuildImprovementActionState(
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
    onBuildRoadTap: _provinceDetailShortcutTap(
      enabled: buildRoadEnabled,
      revalidateEnabled: () =>
          GameMapAreaStateLogic.provinceBuildRoadActionState(
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
    onBuildFortTap: _provinceDetailShortcutTap(
      enabled: buildFortEnabled,
      revalidateEnabled: () =>
          GameMapAreaStateLogic.provinceBuildFortActionState(
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
    onBuildPortTap: _provinceDetailShortcutTap(
      enabled: buildPortEnabled,
      revalidateEnabled: () =>
          GameMapAreaStateLogic.provinceBuildPortActionState(
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
    onPurchaseLandTap: _provinceDetailShortcutTap(
      enabled: purchaseLandEnabled,
      revalidateEnabled: () =>
          GameMapAreaStateLogic.provincePurchaseLandActionState(
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
    onUpgradeTownTap: upgradeTownTap,
    onEstablishConsulateTap: establishConsulateTap,
  );
}

VoidCallback? _establishConsulateTap({
  required ct_models.Game game,
  required String humanPlayerId,
  required String provinceId,
  required ct_models.Orders draftOrders,
  required MapTopology? topology,
  required bool enabled,
  required bool pending,
  required ct_models.DiplomaticOrder? order,
  required String targetName,
  required ct_models.AppEventBus bus,
}) {
  if (!enabled || order == null) return null;
  if (pending) {
    return () => bus.emit(
      ct_models.RemoveDiplomaticOrderRequestedEvent(
        playerId: humanPlayerId,
        type: ct_models.DiplomaticOrderType.establishOverture,
        targetFactionId: order.targetFactionId,
      ),
    );
  }
  return () {
    final state = GameMapAreaStateLogic.provinceEstablishConsulateActionState(
      game: game,
      humanPlayerId: humanPlayerId,
      provinceId: provinceId,
      topology: topology,
      currentOrders: draftOrders,
    );
    if (!state.enabled || state.pending || state.order == null) return;
    final validatedOrder = state.order!;
    bus.emit(
      ct_models.ConfirmDialogEvent(
        title: diplomacyActionLabel(validatedOrder),
        message: buildDiplomacyConfirmPreviewMessage(
          order: validatedOrder,
          game: game,
          humanPlayerId: humanPlayerId,
          targetDisplayName: targetName,
        ),
        onResult: (confirmed) {
          if (!confirmed) return;
          bus.emit(
            ct_models.AppendDiplomaticOrderRequestedEvent(
              playerId: humanPlayerId,
              order: validatedOrder,
            ),
          );
        },
      ),
    );
  };
}
