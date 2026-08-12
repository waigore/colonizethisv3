import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/player_view.dart';

import 'topology_constants.dart';

/// Empty topology for player-view unit pins.
const playerViewTestTopology = kEmptyMapTopology;

Unit playerViewSpy({
  required String id,
  required String ownerId,
  required String loc,
}) =>
    Unit(id: id, type: kUnitTypeSpy, ownerId: ownerId, locationProvinceId: loc);

PlayerView panelIntelViewWith({
  Map<String, Province> provincesById = const {},
  List<Unit> ownUnits = const [],
  Map<String, VisibilityLevel> visibilityByTile = const {},
}) {
  return PlayerView(
    playerId: 'p1',
    player: const Player(id: 'p1', displayName: 'P1', isHuman: true),
    ownUnitsById: {for (final u in ownUnits) u.id: u},
    provincesById: provincesById,
    visibilityByTile: visibilityByTile,
    prospectedTiles: const {},
    diplomacyByOtherId: const {},
  );
}
