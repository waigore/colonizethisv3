// Sea-zone label + province display-name scenario factories (Refs #4734 Slice E, #4352 Slice D).
// SPEC: SPEC/ui/military-units-panel.md.

import 'package:colonizethis_models/colonizethis_models.dart';

import 'panel_fixtures/core.dart';
import 'units_panel_test_shared.dart';

/// Sea-zone label via seaZoneDisplayNameById (Refs #4021).
Game buildMilitarySeaZoneLabelGame({
  String id = 'g_mil_sea_label',
  String humanId = 'gp_mil_sea_label',
  String capitalProvinceId = 'oldWorld|c1',
  String capitalLocalId = 'c1',
  String seaZoneId = 'zone_x',
  String seaZoneDisplayName = 'Mil Named Sea',
  String playerDisplayName = 'Mil Sea Tester',
}) {
  return buildPanelTestGame(
    id: id,
    players: [
      buildUnitsPanelHumanPlayer(
        id: humanId,
        displayName: playerDisplayName,
        capitalProvinceId: capitalProvinceId,
      ),
    ],
    oldWorldProvinces: [
      Province(
        id: capitalLocalId,
        regionId: 'oldWorld',
        ownerId: humanId,
        displayName: 'Cap',
      ),
    ],
    fleets: [
      Fleet(
        id: 'f_at_sea',
        ownerId: humanId,
        regionId: 'oldWorld',
        seaZoneId: seaZoneId,
        ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
      ),
    ],
    seaZoneDisplayNameById: {'oldWorld|$seaZoneId': seaZoneDisplayName},
  );
}

/// Field army + named province (Refs #4021).
Game buildMilitaryProvinceDisplayNamesGame({
  String id = 'g_display_mil',
  String playerId = 'gp_display_names',
  String provinceLocal = 'lisbon',
  String provinceDisplayName = 'Lisbon Harbor',
  String regimentId = 'levy1',
  String regimentType = 'peasant_levies',
  String armyId = 'army_field',
  String playerDisplayName = 'Tester',
}) {
  final fullProvince = 'oldWorld|$provinceLocal';
  final townTile = 'oldWorld|$provinceLocal|0|0';
  return buildPanelTestGame(
    id: id,
    players: [
      unitsPanelHumanPlayerWithCapital(
        playerId,
        playerDisplayName,
        fullProvince,
      ),
    ],
    oldWorldProvinces: [
      unitsPanelOwProvince(
        fullProvince,
        playerId,
        displayName: provinceDisplayName,
        townTileKey: townTile,
      ),
    ],
    oldWorldUnits: [
      Unit(
        id: regimentId,
        type: regimentType,
        ownerId: playerId,
        locationProvinceId: fullProvince,
        medals: 0,
        status: UnitStatus.idle,
      ),
    ],
    armies: [
      unitsPanelArmy(
        id: armyId,
        ownerId: playerId,
        stationedProvinceId: fullProvince,
        regimentUnitIds: [regimentId],
      ),
    ],
    tileKeysByRegionAndProvince: unitsPanelOwTileKeys({
      fullProvince: [townTile],
    }),
  );
}
