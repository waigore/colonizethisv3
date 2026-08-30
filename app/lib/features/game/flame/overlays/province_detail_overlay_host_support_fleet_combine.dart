import 'dart:async';

import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/prefixed_id.dart';
import '../../../../widgets/ct_confirm_dialog.dart';
import '../map_state/province_naval_combine_action_state.dart';
import '../map_state/province_naval_combine_overlay_controls.dart';
import '../../widgets/province_overlay/province_overlay_fleet_combine_copy.dart';

export '../map_state/province_naval_combine_overlay_controls.dart';

/// Resolves MAP20001 Naval Combine enablement and confirm (Refs #4659).
ProvinceNavalCombineOverlayControls buildProvinceNavalCombineOverlayControls({
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
  final showsFullNavalIntel = _showsFullNavalIntel(
    game: game,
    region: region,
    humanPlayerId: humanPlayerId,
    playerView: playerView,
    displayId: displayId,
    omniscientDetail: omniscientDetail,
    isSeaZone: isSeaZone,
  );
  final state = computeProvinceNavalCombineActionState(
    game: game,
    humanPlayerId: humanPlayerId,
    displayId: displayId,
    draftOrders: draftOrders,
    showsFullNavalIntel: showsFullNavalIntel,
    isSeaZoneContext: isSeaZone,
    canMutateViaUi: canMutateViaUi,
  );
  final l10n = appL10n(context);
  if (!state.show) {
    return ProvinceNavalCombineOverlayControls.hidden;
  }
  final tooltip = state.enabled
      ? l10n.provinceOverlay_combineFleetsAction
      : l10n.provinceOverlay_combineFleetsPendingOrderTooltip;
  VoidCallback? onTap;
  if (state.enabled) {
    onTap = () {
      final fleets = humanFleetsInOverlayNavalLocality(
        game: game,
        humanPlayerId: humanPlayerId,
        displayId: displayId,
        isSeaZoneContext: isSeaZone,
      );
      unawaited(
        showProvinceOverlayFleetCombineConfirm(
          context: context,
          l10n: l10n,
          game: game,
          fleets: fleets,
          humanPlayerId: humanPlayerId,
          bus: bus,
        ),
      );
    };
  }
  return ProvinceNavalCombineOverlayControls(
    showCombineFleets: true,
    combineFleetsEnabled: state.enabled,
    combineFleetsTooltip: tooltip,
    onCombineFleetsTap: onTap,
  );
}

bool _showsFullNavalIntel({
  required ct_models.Game game,
  required RegionMapViewData region,
  required String humanPlayerId,
  required PlayerView playerView,
  required String displayId,
  required bool omniscientDetail,
  required bool isSeaZone,
}) {
  if (omniscientDetail) return true;
  if (isSeaZone) {
    final regionId = prefixedIdRegionSegment(displayId) ?? region.regionId;
    final localSea = prefixedIdLocalSegment(displayId);
    if (region.regionId != regionId) return false;
    return region.cells.any(
      (c) =>
          c.isSea &&
          c.regionCellId == localSea &&
          c.visibility != TileVisibility.unrevealed,
    );
  }
  final provinceTileKeys =
      game.worldState.tileKeysByRegionAndProvince[region
          .regionId]?[displayId] ??
      const <String>[];
  return provincePanelShowsFullTileDerivedIntel(
    game: game,
    view: playerView,
    humanPlayerId: humanPlayerId,
    provinceId: displayId,
    provinceTileKeys: provinceTileKeys,
  );
}

Future<void> showProvinceOverlayFleetCombineConfirm({
  required BuildContext context,
  required AppLocalizations l10n,
  required ct_models.Game game,
  required List<ct_models.Fleet> fleets,
  required String humanPlayerId,
  required ct_models.AppEventBus bus,
}) async {
  if (fleets.length < 2) return;
  final confirmed = await showCtConfirmDialog(
    context,
    title: l10n.provinceOverlay_combineFleetsConfirmTitle,
    message: overlayFleetCombineConfirmMessage(
      l10n: l10n,
      humanPlayerId: humanPlayerId,
      fleets: fleets,
    ),
    confirmLabel: l10n.common_confirm,
    cancelLabel: l10n.common_cancel,
    useRootNavigator: false,
  );
  if (!confirmed) return;
  final preferIds = [for (final f in fleets) f.id];
  final next = applyNavalCombineFleets(
    game: game,
    humanPlayerId: humanPlayerId,
    fleetIds: preferIds,
  );
  bus.emit(ct_models.NavalFleetsUpdatedEvent(game: next));
}
