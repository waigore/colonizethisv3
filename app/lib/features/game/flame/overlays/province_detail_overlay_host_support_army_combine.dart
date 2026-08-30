import 'dart:async';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import '../map_state/province_army_combine_action_state.dart';
import '../../widgets/province_overlay/province_overlay_army_combine_copy.dart';
import '../../../../widgets/ct_confirm_dialog.dart';

/// Combine control props for [ProvinceSeaZoneDetailOverlay] (Refs #4610).
typedef ProvinceArmyCombineOverlayControls = ({
  bool show,
  bool enabled,
  String tooltip,
  VoidCallback? onTap,
});

ProvinceArmyCombineOverlayControls buildProvinceArmyCombineOverlayControls({
  required BuildContext context,
  required ct_models.Game game,
  required RegionMapViewData region,
  required String humanPlayerId,
  required PlayerView playerView,
  required String displayId,
  required ct_models.Orders draftOrders,
  required bool canMutateViaUi,
  required bool omniscientDetail,
  required ct_models.AppEventBus bus,
  required bool isSeaZone,
}) {
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
  final state = computeProvinceArmyCombineActionState(
    game: game,
    humanPlayerId: humanPlayerId,
    provinceId: displayId,
    draftOrders: draftOrders,
    showsFullMilitaryIntel: showsFullMilitaryIntel,
    isSeaZoneContext: isSeaZone,
    canMutateViaUi: canMutateViaUi,
  );
  final l10n = appL10n(context);
  if (!state.show) {
    return (show: false, enabled: false, tooltip: '', onTap: null);
  }
  final tooltip = state.enabled
      ? l10n.provinceOverlay_combineArmiesAction
      : l10n.provinceOverlay_combineArmiesPendingMarchTooltip;
  VoidCallback? onTap;
  if (state.enabled) {
    onTap = () {
      final armies = humanArmiesInProvince(
        game: game,
        humanPlayerId: humanPlayerId,
        provinceId: displayId,
      );
      unawaited(
        showProvinceOverlayArmyCombineConfirm(
          context: context,
          l10n: l10n,
          game: game,
          armies: armies,
          humanPlayerId: humanPlayerId,
          bus: bus,
        ),
      );
    };
  }
  return (show: true, enabled: state.enabled, tooltip: tooltip, onTap: onTap);
}

Future<void> showProvinceOverlayArmyCombineConfirm({
  required BuildContext context,
  required AppLocalizations l10n,
  required ct_models.Game game,
  required List<ct_models.Army> armies,
  required String humanPlayerId,
  required ct_models.AppEventBus bus,
}) async {
  if (armies.length < 2) return;
  final confirmed = await showCtConfirmDialog(
    context,
    title: l10n.provinceOverlay_combineArmiesConfirmTitle,
    message: overlayArmyCombineConfirmMessage(
      l10n: l10n,
      game: game,
      armies: armies,
    ),
    confirmLabel: l10n.common_confirm,
    cancelLabel: l10n.common_cancel,
    useRootNavigator: false,
  );
  if (!confirmed) return;
  final ids = [for (final a in armies) a.id]..sort();
  bus.emit(
    ct_models.ArmyCombineRequestedEvent(
      humanPlayerId: humanPlayerId,
      armyIds: ids,
    ),
  );
}
