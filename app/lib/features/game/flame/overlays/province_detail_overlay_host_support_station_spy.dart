import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import '../map_state/province_station_spy_action_state.dart';
import '../../widgets/province_overlay/province_sea_zone_detail_overlay_support.dart';
import '../../widgets/province_overlay/province_sea_zone_detail_overlay_tile_section_label_text.dart'
    show tryParseProvinceOverlayTileCoords;
import '../../widgets/units/civilian/spy_research_insight_copy.dart';

/// MAP20001 Civilian **Station spy** props for both overlay hosts (Refs #4439).
ProvinceOverlayStationSpyProps buildProvinceStationSpyOverlayProps({
  required BuildContext context,
  required ct_models.Game game,
  required RegionMapViewData region,
  required String displayId,
  required String humanPlayerId,
  required PlayerView playerView,
  required String? selectedTileKey,
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
  var tileObfuscated = true;
  if (omniscientDetail) {
    tileObfuscated = false;
  } else if (selectedTileKey != null) {
    final coords = tryParseProvinceOverlayTileCoords(
      regionId: region.regionId,
      regionWidth: region.width,
      regionHeight: region.height,
      selectedTileKey: selectedTileKey,
    );
    if (coords != null) {
      final cell = region.cellAt(coords.x, coords.y);
      tileObfuscated = cell.visibility == TileVisibility.unrevealed;
    }
  }
  ProvinceStationSpyActionState state() => computeProvinceStationSpyActionState(
    game: game,
    orders: draftOrders,
    humanPlayerId: humanPlayerId,
    selectedTileKey: selectedTileKey,
    canMutateViaUi: canMutateViaUi,
    isSeaZone: isSeaZone,
    tileObfuscated: tileObfuscated,
    civilianSectionObfuscated: !showsFullIntel,
  );
  final resolved = state();
  if (!resolved.showControl) {
    return kProvinceOverlayStationSpyHidden;
  }
  final tooltip = switch (resolved.disabledReason) {
    ProvinceStationSpyDisabledReason.noIdleSpy =>
      l10n.provinceOverlay_stationSpyDisabledNoIdleSpyTooltip,
    ProvinceStationSpyDisabledReason.tileNotOccupiable =>
      l10n.provinceOverlay_stationSpyDisabledNotOccupiableTooltip,
    null => l10n.provinceOverlay_stationSpyAction,
  };
  final tileKey = selectedTileKey;
  final gist = tileKey == null
      ? ''
      : spyResearchInsightGistTextForTile(
              l10n: l10n,
              game: game,
              orders: draftOrders,
              humanPlayerId: humanPlayerId,
              tileKey: tileKey,
            ) ??
            '';
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
                relocateShortcutTargetTileKey: tileKey,
              ),
            );
          },
  );
}
