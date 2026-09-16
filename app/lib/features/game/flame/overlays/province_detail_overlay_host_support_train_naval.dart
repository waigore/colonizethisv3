import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart'
    show trainNavalDialogId;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/widgets.dart';

/// MAP20001 Naval **Train** props (Refs #4776). Always enabled when shown.
typedef ProvinceTrainNavalOverlayControls = ({bool show, VoidCallback? onTap});

const ProvinceTrainNavalOverlayControls kProvinceTrainNavalOverlayHidden = (
  show: false,
  onTap: null,
);

/// Opens `UNIT60001` with no dialog params; overlay stays mounted (Refs #4776).
VoidCallback buildTrainNavalDialogTap(ct_models.AppEventBus bus) {
  return () => bus.emit(const ct_models.OpenDialogEvent(trainNavalDialogId));
}

/// Human-capital **Train** on MAP20001 Naval. Keys off
/// `Player.capitalProvinceId`, not any-faction `provinceOverlayIsCapital`.
ProvinceTrainNavalOverlayControls buildProvinceTrainNavalOverlayControls({
  required ct_models.Game game,
  required RegionMapViewData region,
  required String humanPlayerId,
  required PlayerView playerView,
  required String displayId,
  required bool canMutateViaUi,
  required bool omniscientDetail,
  required ct_models.AppEventBus bus,
  required bool isSeaZone,
}) {
  if (!canMutateViaUi || isSeaZone) {
    return kProvinceTrainNavalOverlayHidden;
  }
  final capitalId = game.playerById(humanPlayerId)?.capitalProvinceId;
  if (capitalId == null || capitalId.isEmpty || capitalId != displayId) {
    return kProvinceTrainNavalOverlayHidden;
  }
  final provinceTileKeys =
      game.worldState.tileKeysByRegionAndProvince[region
          .regionId]?[displayId] ??
      const <String>[];
  final showsFullNavalIntel =
      omniscientDetail ||
      provincePanelShowsFullTileDerivedIntel(
        game: game,
        view: playerView,
        humanPlayerId: humanPlayerId,
        provinceId: displayId,
        provinceTileKeys: provinceTileKeys,
      );
  if (!showsFullNavalIntel) {
    return kProvinceTrainNavalOverlayHidden;
  }
  return (show: true, onTap: buildTrainNavalDialogTap(bus));
}
