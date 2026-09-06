import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';

import '../../../../core/services/game_service/game_service.dart'
    show GameMapData;
import '../../../../core/utils/prefixed_id.dart';
import '../../widgets/unit_orders/overlay_sail_move_flow.dart';
import '../map_state/province_overlay_sail_move_action_state.dart';
import '../map_state/province_overlay_sail_move_overlay_controls.dart';

export '../map_state/province_overlay_sail_move_overlay_controls.dart';

/// Resolves MAP20001 Naval Sail / Move enablement (Refs #4735).
ProvinceOverlaySailMoveOverlayControls buildProvinceOverlaySailMoveOverlayControls({
  required BuildContext context,
  required ct_models.Game game,
  required RegionMapViewData region,
  required String humanPlayerId,
  required PlayerView playerView,
  required String displayId,
  required GameMapData? mapData,
  required bool canMutateViaUi,
  required bool omniscientDetail,
  required ct_models.AppEventBus bus,
  required bool isSeaZone,
}) {
  final showsFullNavalIntel = _showsFullNavalIntelForSailMove(
    game: game,
    region: region,
    humanPlayerId: humanPlayerId,
    playerView: playerView,
    displayId: displayId,
    omniscientDetail: omniscientDetail,
    isSeaZone: isSeaZone,
  );
  final state = computeProvinceOverlaySailMoveActionState(
    game: game,
    humanPlayerId: humanPlayerId,
    displayId: displayId,
    showsFullNavalIntel: showsFullNavalIntel,
    isSeaZoneContext: isSeaZone,
    canMutateViaUi: canMutateViaUi,
  );
  if (!state.show) {
    return ProvinceOverlaySailMoveOverlayControls.hidden;
  }
  final l10n = appL10n(context);
  final topology = mapData?.combinedTopology ?? const MapTopology();
  return ProvinceOverlaySailMoveOverlayControls(
    showSailMove: true,
    sailMoveEnabled: state.enabled,
    sailMoveTooltip: l10n.naval_mission_effect_sail,
    onSailMoveTap: state.enabled
        ? () => showOverlaySailMoveFlow(
            context: context,
            game: game,
            topology: topology,
            humanPlayerId: humanPlayerId,
            bus: bus,
            fleetIds: state.fleetIds,
            playerView: playerView,
          )
        : null,
  );
}

bool _showsFullNavalIntelForSailMove({
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
