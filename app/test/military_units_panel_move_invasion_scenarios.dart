// Adjacent-hostile invasion scenario factory (Refs #4734 Slice E, #4352 Slice D).
// SPEC: SPEC/ui/military-units-panel.md.

import 'package:colonizethis_models/colonizethis_models.dart';

import 'panel_fixtures/core.dart';
import 'units_panel_test_shared.dart';

/// Adjacent hostile province (invasion confirm).
Game buildMilitaryInvasionAdjacentHostileGame({
  required String id,
  required String playerId,
  required String enemyId,
  String armyId = 'ainv',
  String regimentId = 'ui1',
  String stationProvinceId = 'oldWorld|p2',
  String hostileProvinceId = 'oldWorld|p3',
  String hostileDisplayName = 'Hostile',
  String playerDisplayName = 'Inv',
  String enemyDisplayName = 'Enemy',
  String regimentType = 'musketeers',
}) {
  final stationTile = '$stationProvinceId|0|0';
  final hostileTile = '$hostileProvinceId|0|0';
  return buildPanelTestGame(
    id: id,
    diplomacyRelations: const [],
    players: [
      unitsPanelHumanPlayerWithCapital(
        playerId,
        playerDisplayName,
        stationProvinceId,
      ),
      unitsPanelHumanPlayerWithCapital(
        enemyId,
        enemyDisplayName,
        hostileProvinceId,
      ),
    ],
    oldWorldProvinces: [
      unitsPanelOwProvince(stationProvinceId, playerId),
      unitsPanelOwProvince(
        hostileProvinceId,
        enemyId,
        displayName: hostileDisplayName,
      ),
    ],
    oldWorldUnits: unitsPanelRegimentsAt(
      [regimentId],
      playerId,
      stationProvinceId,
      type: regimentType,
    ),
    armies: [
      unitsPanelArmy(
        id: armyId,
        ownerId: playerId,
        stationedProvinceId: stationProvinceId,
        regimentUnitIds: [regimentId],
      ),
    ],
    tileKeysByRegionAndProvince: unitsPanelOwTileKeys({
      stationProvinceId: [stationTile],
      hostileProvinceId: [hostileTile],
    }),
    playerVisibilityByTile: unitsPanelPlayerVisibility(playerId, [
      stationTile,
      hostileTile,
    ]),
  );
}
