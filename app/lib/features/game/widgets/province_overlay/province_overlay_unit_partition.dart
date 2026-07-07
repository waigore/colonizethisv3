import 'package:colonizethis_data/colonizethis_data.dart' show isMilitaryUnit;
import 'package:colonizethis_logic/colonizethis_logic.dart'
    show PlayerView, foreignCivilianVisibleToPlayer;
import 'package:colonizethis_models/colonizethis_models.dart';

/// Military/civilian units in one province for overlay sections (single pass).
({List<Unit> military, List<Unit> civilian, int visibleCivilianCount})
partitionProvinceOverlayUnits({
  required List<Unit> regionUnits,
  required String provinceId,
  required String humanPlayerId,
  required PlayerView playerView,
}) {
  final military = <Unit>[];
  final civilian = <Unit>[];
  var visibleCivilianCount = 0;
  for (final u in regionUnits) {
    if (u.locationProvinceId != provinceId) {
      continue;
    }
    if (isMilitaryUnit(u.type)) {
      military.add(u);
    } else {
      civilian.add(u);
      if (foreignCivilianVisibleToPlayer(
        unit: u,
        viewerPlayerId: humanPlayerId,
        view: playerView,
      )) {
        visibleCivilianCount++;
      }
    }
  }
  return (
    military: military,
    civilian: civilian,
    visibleCivilianCount: visibleCivilianCount,
  );
}
