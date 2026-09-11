import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart'
    show trainMilitaryDialogId;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/widgets.dart';

/// MAP20001 Military **Train** props (Refs #4769). Always enabled when shown.
typedef ProvinceTrainMilitaryOverlayControls = ({
  bool show,
  VoidCallback? onTap,
});

const ProvinceTrainMilitaryOverlayControls kProvinceTrainMilitaryOverlayHidden =
    (show: false, onTap: null);

/// Opens `UNIT50001` with no dialog params; overlay stays mounted (Refs #4769).
VoidCallback buildTrainMilitaryDialogTap(ct_models.AppEventBus bus) {
  return () => bus.emit(const ct_models.OpenDialogEvent(trainMilitaryDialogId));
}

/// Human-capital **Train** on MAP20001 Military. Keys off
/// `Player.capitalProvinceId`, not any-faction `provinceOverlayIsCapital`.
ProvinceTrainMilitaryOverlayControls buildProvinceTrainMilitaryOverlayControls({
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
    return kProvinceTrainMilitaryOverlayHidden;
  }
  final capitalId = game.playerById(humanPlayerId)?.capitalProvinceId;
  if (capitalId == null || capitalId.isEmpty || capitalId != displayId) {
    return kProvinceTrainMilitaryOverlayHidden;
  }
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
  if (!showsFullMilitaryIntel) {
    return kProvinceTrainMilitaryOverlayHidden;
  }
  return (show: true, onTap: buildTrainMilitaryDialogTap(bus));
}
