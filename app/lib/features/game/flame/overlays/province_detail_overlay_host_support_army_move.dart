import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;
import '../caches/per_player_army_move_picker_cache.dart';
import '../map_state/province_army_move_action_state.dart';
import '../map_state/province_army_move_home_army.dart';
import '../../widgets/unit_orders/home_army_detach_then_move_flow.dart';
import '../../widgets/unit_orders/overlay_army_move_flow.dart';

/// Move / Invade control props for [ProvinceSeaZoneDetailOverlay] (Refs #4350).
typedef ProvinceArmyMoveOverlayControls = ({
  bool showMove,
  bool moveEnabled,
  String moveTooltip,
  VoidCallback? onMoveTap,
  bool showInvade,
  bool invadeEnabled,
  String invadeTooltip,
  VoidCallback? onInvadeTap,
});

/// Resolves MAP20001 Move/Invade enablement, tooltips, and tap handlers for the
/// shared province-detail overlay factory.
ProvinceArmyMoveOverlayControls buildProvinceArmyMoveOverlayControls({
  required BuildContext context,
  required ct_models.Game game,
  required RegionMapViewData region,
  required String humanPlayerId,
  required PlayerView playerView,
  required String displayId,
  required ct_models.Orders draftOrders,
  required GameMapData? mapData,
  required bool canMutateViaUi,
  required bool omniscientDetail,
  required PerPlayerArmyMovePickerCache? armyMovePickerCache,
  required ct_models.AppEventBus bus,
  required bool isSeaZone,
}) {
  final armyCache = armyMovePickerCache ?? PerPlayerArmyMovePickerCache();
  final provinceTileKeys =
      game.worldState.tileKeysByRegionAndProvince[region
          .regionId]?[displayId] ??
      const <String>[];
  final showsFullMilitaryIntel =
      omniscientDetail ||
      provincePanelShowsFullTileDerivedIntel(
        game: game,
        view: playerView,
        humanPlayerId: humanPlayerId,
        provinceId: displayId,
        provinceTileKeys: provinceTileKeys,
      );
  final armyMoveState = computeProvinceArmyMoveActionState(
    game: game,
    humanPlayerId: humanPlayerId,
    provinceId: displayId,
    topology: mapData?.combinedTopology ?? const MapTopology(),
    armyMovePickerCache: armyCache,
    showsFullMilitaryIntel: showsFullMilitaryIntel,
    isSeaZoneContext: isSeaZone,
  );
  final l10n = appL10n(context);
  String moveTooltip() {
    switch (armyMoveState.moveDisabledReason) {
      case ProvinceArmyMoveDisabledReason.homeArmyCannotLeave:
        return l10n.provinceOverlay_moveArmyDisabledHomeArmyTooltip;
      case ProvinceArmyMoveDisabledReason.noDestinations:
        return l10n.provinceOverlay_moveArmyDisabledNoDestinationsTooltip;
      case ProvinceArmyMoveDisabledReason.cannotReach:
      case ProvinceArmyMoveDisabledReason.none:
        return l10n.provinceOverlay_moveArmyAction;
    }
  }

  String invadeTooltip() {
    switch (armyMoveState.invadeDisabledReason) {
      case ProvinceArmyMoveDisabledReason.cannotReach:
        return l10n.provinceOverlay_invadeArmyDisabledCannotReachTooltip;
      case ProvinceArmyMoveDisabledReason.homeArmyCannotLeave:
      case ProvinceArmyMoveDisabledReason.noDestinations:
      case ProvinceArmyMoveDisabledReason.none:
        return l10n.provinceOverlay_invadeArmyAction(
          game.worldState.allProvincesById[displayId]?.displayName ?? displayId,
        );
    }
  }

  final topology = mapData?.combinedTopology ?? const MapTopology();
  VoidCallback? moveTap;
  if (canMutateViaUi && armyMoveState.moveEnabled) {
    moveTap = () {
      if (usesHomeArmyDetachFlow(
        enabled: armyMoveState.moveEnabled,
        eligibleArmyIds: armyMoveState.eligibleMoveArmyIds,
      )) {
        showHomeArmyDetachThenMoveFlow(
          context: context,
          game: game,
          topology: topology,
          humanPlayerId: humanPlayerId,
          draftOrders: draftOrders,
          bus: bus,
          playerView: playerView,
        );
        return;
      }
      showOverlayArmyMoveFlow(
        context: context,
        game: game,
        topology: topology,
        humanPlayerId: humanPlayerId,
        draftOrders: draftOrders,
        bus: bus,
        armyIds: armyMoveState.eligibleMoveArmyIds,
        playerView: playerView,
      );
    };
  }
  VoidCallback? invadeTap;
  if (canMutateViaUi && armyMoveState.invadeEnabled) {
    invadeTap = () {
      if (usesHomeArmyDetachFlow(
        enabled: armyMoveState.invadeEnabled,
        eligibleArmyIds: armyMoveState.eligibleInvadeArmyIds,
      )) {
        showHomeArmyDetachThenMoveFlow(
          context: context,
          game: game,
          topology: topology,
          humanPlayerId: humanPlayerId,
          draftOrders: draftOrders,
          bus: bus,
          playerView: playerView,
          initialDestinationProvinceId: displayId,
        );
        return;
      }
      showOverlayArmyMoveFlow(
        context: context,
        game: game,
        topology: topology,
        humanPlayerId: humanPlayerId,
        draftOrders: draftOrders,
        bus: bus,
        armyIds: armyMoveState.eligibleInvadeArmyIds,
        playerView: playerView,
        initialDestinationProvinceId: displayId,
      );
    };
  }

  return (
    showMove: canMutateViaUi && armyMoveState.showMove,
    moveEnabled: canMutateViaUi && armyMoveState.moveEnabled,
    moveTooltip: moveTooltip(),
    onMoveTap: moveTap,
    showInvade: canMutateViaUi && armyMoveState.showInvade,
    invadeEnabled: canMutateViaUi && armyMoveState.invadeEnabled,
    invadeTooltip: invadeTooltip(),
    onInvadeTap: invadeTap,
  );
}
