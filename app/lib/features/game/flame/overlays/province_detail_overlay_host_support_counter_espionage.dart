import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import '../map_state/province_counter_espionage_action_state.dart';
import '../../widgets/province_overlay/province_sea_zone_detail_overlay_support.dart';

/// MAP20001 Civilian **Counter-espionage** props for both overlay hosts (Refs #4528).
ProvinceOverlayCounterEspionageProps buildProvinceCounterEspionageOverlayProps({
  required BuildContext context,
  required ct_models.Game game,
  required RegionMapViewData region,
  required String displayId,
  required String humanPlayerId,
  required PlayerView playerView,
  required ct_models.Orders draftOrders,
  required bool canMutateViaUi,
  required bool omniscientDetail,
  required bool isSeaZone,
  required ct_models.AppEventBus bus,
}) {
  final l10n = appL10n(context);
  final tileKeys =
      game.worldState.tileKeysByRegionAndProvince[region
          .regionId]?[displayId] ??
      const <String>[];
  final showsFullIntel =
      omniscientDetail ||
      provincePanelShowsFullTileDerivedIntel(
        game: game,
        view: playerView,
        humanPlayerId: humanPlayerId,
        provinceId: displayId,
        provinceTileKeys: tileKeys,
      );
  ProvinceCounterEspionageActionState state() =>
      computeProvinceCounterEspionageActionState(
        game: game,
        orders: draftOrders,
        humanPlayerId: humanPlayerId,
        displayId: displayId,
        canMutateViaUi: canMutateViaUi,
        isSeaZone: isSeaZone,
        civilianSectionObfuscated: !showsFullIntel,
      );
  final resolved = state();
  if (!resolved.showControl) {
    return kProvinceOverlayCounterEspionageHidden;
  }
  final tooltip = switch (resolved.disabledReason) {
    ProvinceCounterEspionageDisabledReason.noIdleSpy =>
      l10n.provinceOverlay_counterEspionageDisabledNoIdleSpyTooltip,
    ProvinceCounterEspionageDisabledReason.alreadyPosted =>
      l10n.provinceOverlay_counterEspionageDisabledAlreadyPostedTooltip,
    null => l10n.provinceOverlay_counterEspionageOneSpyTooltip,
  };
  final gist = resolved.enabled
      ? l10n.provinceOverlay_counterEspionageGist
      : '';
  final tileKey = provinceLevelCounterSpyTileKey(displayId);
  return (
    showControl: true,
    enabled: resolved.enabled,
    tooltip: tooltip,
    gist: gist,
    onTap: !resolved.enabled || tileKey == null
        ? null
        : () {
            if (!state().enabled) return;
            bus.emit(
              ct_models.OpenCivilianUnitsPanelEvent(
                spyOnly: true,
                counterSpyShortcutTargetTileKey: tileKey,
              ),
            );
          },
  );
}
