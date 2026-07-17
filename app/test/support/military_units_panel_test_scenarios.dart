// Military units-panel scenario Game factories (Refs #4048).
// SPEC: SPEC/ui/military-units-panel.md; SPEC/program/repo-lint.md.

import 'package:colonizethis_models/colonizethis_models.dart';

import 'panel_fixtures/core.dart';
import 'units_panel_test_shared.dart';

/// Minimal province + tile-key lookup game (Refs #4013).
Game buildMilitaryProvinceTileLookupGame({
  String id = 'min',
  String regionId = 'oldWorld',
  String provinceId = 'p1',
  String tileKey = 'oldWorld|p1|0|0',
  String? ownerId,
}) {
  final prefixedId = '$regionId|$provinceId';
  return buildPanelTestGame(
    id: id,
    players: const [],
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorldProvinces: [
      Province(
        id: provinceId,
        regionId: regionId,
        ownerId: ownerId,
        townTileKey: null,
      ),
    ],
    tileKeysByRegionAndProvince: {
      regionId: {
        prefixedId: [tileKey],
      },
    },
  );
}
/// Sea-zone fleet display scenario (Refs #4013).
Game buildMilitarySeaFleetDisplayGame({
  required String id,
  required String playerId,
  required List<String> shipTypeIds,
  required FleetMission mission,
  String seaZoneId = 'atlantic',
  String fleetId = 'fleet1',
  bool includeLisbonProvince = false,
  String playerDisplayName = 'Test',
}) {
  const provinceId = 'lisbon';
  const tileKey = 'oldWorld|lisbon|0|0';
  return buildPanelTestGame(
    id: id,
    players: [
      Player(id: playerId, displayName: playerDisplayName, isHuman: true),
    ],
    oldWorldProvinces: includeLisbonProvince
        ? [
            Province(
              id: provinceId,
              regionId: 'oldWorld',
              ownerId: playerId,
            ),
          ]
        : const [],
    fleets: [
      Fleet(
        id: fleetId,
        ownerId: playerId,
        regionId: 'oldWorld',
        seaZoneId: seaZoneId,
        shipTypeIds: shipTypeIds,
        mission: mission,
      ),
    ],
    portsByProvinceSeaboard: const {
      'oldWorld|lisbon|atlantic': tileKey,
    },
    tileKeysByRegionAndProvince: const {
      'oldWorld': {
        'oldWorld|lisbon': [tileKey],
      },
    },
  );
}
/// Land-army display at Lisbon (medals / status pins).
Game buildMilitaryArmyAtLisbonDisplayGame({
  required String id,
  required String playerId,
  required String armyId,
  required List<Unit> units,
  String playerDisplayName = 'Test',
}) {
  const provinceId = 'oldWorld|lisbon';
  const tileKey = 'oldWorld|lisbon|0|0';
  return buildPanelTestGame(
    id: id,
    players: [
      Player(id: playerId, displayName: playerDisplayName, isHuman: true),
    ],
    oldWorldProvinces: [
      Province(
        id: provinceId,
        regionId: 'oldWorld',
        ownerId: playerId,
        townTileKey: tileKey,
      ),
    ],
    oldWorldUnits: units,
    armies: [
      Army(
        id: armyId,
        ownerId: playerId,
        regionId: 'oldWorld',
        stationedProvinceId: provinceId,
        regimentUnitIds: units.map((u) => u.id).toList(growable: false),
        isHomeArmy: false,
      ),
    ],
    tileKeysByRegionAndProvince: const {
      'oldWorld': {
        provinceId: [tileKey],
      },
    },
  );
}
/// Home army at capital for split-UI / shell smoke (Refs #4013).
Game buildMilitaryHomeArmyAtCapitalGame({
  required String id,
  required String playerId,
  required List<String> regimentIds,
  String capitalProvinceId = 'oldWorld|cap',
  String townTileKey = 'tk_cap',
  String armyId = 'home_army',
  int nextArmySeq = 1,
  String playerDisplayName = 'Splitter',
  String regimentType = kPanelTestRegimentType,
}) {
  return buildPanelTestGame(
    id: id,
    nextArmySeq: nextArmySeq,
    players: [
      Player(
        id: playerId,
        displayName: playerDisplayName,
        isHuman: true,
        capitalProvinceId: capitalProvinceId,
      ),
    ],
    oldWorldProvinces: [
      Province(
        id: capitalProvinceId,
        regionId: 'oldWorld',
        ownerId: playerId,
        displayName: 'Capital',
        townTileKey: townTileKey,
      ),
    ],
    oldWorldUnits: [
      for (final regimentId in regimentIds)
        Unit(
          id: regimentId,
          type: regimentType,
          ownerId: playerId,
          locationProvinceId: capitalProvinceId,
        ),
    ],
    armies: [
      Army(
        id: armyId,
        ownerId: playerId,
        regionId: 'oldWorld',
        stationedProvinceId: capitalProvinceId,
        regimentUnitIds: List<String>.from(regimentIds),
        isHomeArmy: true,
      ),
    ],
    tileKeysByRegionAndProvince: {
      'oldWorld': {
        capitalProvinceId: [townTileKey],
      },
    },
  );
}
/// Sea-fleet location header via [seaZoneDisplayNameById] (Refs #4021).
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
/// Field army + named province for display-name pins (Refs #4021).
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
      Player(
        id: playerId,
        displayName: playerDisplayName,
        isHuman: true,
        capitalProvinceId: fullProvince,
      ),
    ],
    oldWorldProvinces: [
      Province(
        id: fullProvince,
        regionId: 'oldWorld',
        ownerId: playerId,
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
      Army(
        id: armyId,
        ownerId: playerId,
        regionId: 'oldWorld',
        stationedProvinceId: fullProvince,
        regimentUnitIds: [regimentId],
        isHomeArmy: false,
      ),
    ],
    tileKeysByRegionAndProvince: {
      'oldWorld': {
        fullProvince: [townTile],
      },
    },
  );
}
/// Two field armies at one owned province (Combine scenario).
Game buildMilitaryTwoFieldArmiesAtProvinceGame({
  required String id,
  required String playerId,
  String provinceId = 'oldWorld|p2',
  String townTileKey = 'tk',
  String armyIdA = 'ax',
  String armyIdB = 'ay',
  String regimentIdA = 'uu1',
  String regimentIdB = 'uu2',
  String capitalProvinceId = 'oldWorld|cap',
  String playerDisplayName = 'C',
  String regimentType = 'musketeers',
}) {
  return buildPanelTestGame(
    id: id,
    players: [
      Player(
        id: playerId,
        displayName: playerDisplayName,
        isHuman: true,
        capitalProvinceId: capitalProvinceId,
      ),
    ],
    oldWorldProvinces: [
      Province(
        id: provinceId,
        regionId: 'oldWorld',
        ownerId: playerId,
        townTileKey: townTileKey,
      ),
    ],
    oldWorldUnits: [
      Unit(
        id: regimentIdA,
        type: regimentType,
        ownerId: playerId,
        locationProvinceId: provinceId,
      ),
      Unit(
        id: regimentIdB,
        type: regimentType,
        ownerId: playerId,
        locationProvinceId: provinceId,
      ),
    ],
    armies: [
      Army(
        id: armyIdA,
        ownerId: playerId,
        regionId: 'oldWorld',
        stationedProvinceId: provinceId,
        regimentUnitIds: [regimentIdA],
        isHomeArmy: false,
      ),
      Army(
        id: armyIdB,
        ownerId: playerId,
        regionId: 'oldWorld',
        stationedProvinceId: provinceId,
        regimentUnitIds: [regimentIdB],
        isHomeArmy: false,
      ),
    ],
    tileKeysByRegionAndProvince: {
      'oldWorld': {
        provinceId: [townTileKey],
      },
    },
  );
}
/// Field army with adjacent owned dest for Move/Locate.
Game buildMilitaryFieldArmyWithAdjacentOwnedGame({
  required String id,
  required String playerId,
  required String armyId,
  required List<String> regimentUnitIds,
  String stationProvinceId = 'oldWorld|p2',
  String adjacentProvinceId = 'oldWorld|p3',
  String? stationTownTileKey = 'tk',
  String? stationDisplayName,
  String? adjacentDisplayName,
  String playerDisplayName = 'M',
  String regimentType = 'musketeers',
  bool includeTileKeysAndVisibility = true,
}) {
  final stationTile = '$stationProvinceId|0|0';
  final adjacentTile = '$adjacentProvinceId|0|0';
  return buildPanelTestGame(
    id: id,
    players: [
      Player(
        id: playerId,
        displayName: playerDisplayName,
        isHuman: true,
        capitalProvinceId: stationProvinceId,
      ),
    ],
    oldWorldProvinces: [
      Province(
        id: stationProvinceId,
        regionId: 'oldWorld',
        ownerId: playerId,
        displayName: stationDisplayName,
        townTileKey: stationTownTileKey,
      ),
      Province(
        id: adjacentProvinceId,
        regionId: 'oldWorld',
        ownerId: playerId,
        displayName: adjacentDisplayName,
      ),
    ],
    oldWorldUnits: [
      for (final regimentId in regimentUnitIds)
        Unit(
          id: regimentId,
          type: regimentType,
          ownerId: playerId,
          locationProvinceId: stationProvinceId,
        ),
    ],
    armies: [
      Army(
        id: armyId,
        ownerId: playerId,
        regionId: 'oldWorld',
        stationedProvinceId: stationProvinceId,
        regimentUnitIds: List<String>.from(regimentUnitIds),
        isHomeArmy: false,
      ),
    ],
    tileKeysByRegionAndProvince: includeTileKeysAndVisibility
        ? {
            'oldWorld': {
              stationProvinceId: [stationTile],
              adjacentProvinceId: [adjacentTile],
            },
          }
        : const {},
    playerVisibilityByTile: includeTileKeysAndVisibility
        ? {
            playerId: {
              stationTile: 'fullyVisible',
              adjacentTile: 'fullyVisible',
            },
          }
        : const {},
  );
}
/// Cross-region OW+NW owned dests for MoveArmyDialog grouping.
Game buildMilitaryCrossRegionOwnedMoveGame({
  required String id,
  required String playerId,
  String armyId = 'amove',
  String regimentId = 'u1',
  String fromProvinceId = 'oldWorld|p2',
  String oldDestProvinceId = 'oldWorld|p3',
  String newDestProvinceId = 'newWorld|n2',
  String fromDisplayName = 'From',
  String oldDestDisplayName = 'Old Port',
  String newDestDisplayName = 'New Port',
  String fromTownTileKey = 'tk_from',
  String playerDisplayName = 'Grouped',
  String regimentType = 'musketeers',
}) {
  final fromTile = '$fromProvinceId|0|0';
  final oldDestTile = '$oldDestProvinceId|0|0';
  final newDestTile = '$newDestProvinceId|0|0';
  return buildPanelTestGame(
    id: id,
    players: [
      Player(
        id: playerId,
        displayName: playerDisplayName,
        isHuman: true,
        capitalProvinceId: fromProvinceId,
      ),
    ],
    oldWorldProvinces: [
      Province(
        id: fromProvinceId,
        regionId: 'oldWorld',
        ownerId: playerId,
        displayName: fromDisplayName,
        townTileKey: fromTownTileKey,
      ),
      Province(
        id: oldDestProvinceId,
        regionId: 'oldWorld',
        ownerId: playerId,
        displayName: oldDestDisplayName,
      ),
    ],
    newWorldProvinces: [
      Province(
        id: newDestProvinceId,
        regionId: 'newWorld',
        ownerId: playerId,
        displayName: newDestDisplayName,
      ),
    ],
    oldWorldUnits: [
      Unit(
        id: regimentId,
        type: regimentType,
        ownerId: playerId,
        locationProvinceId: fromProvinceId,
      ),
    ],
    armies: [
      Army(
        id: armyId,
        ownerId: playerId,
        regionId: 'oldWorld',
        stationedProvinceId: fromProvinceId,
        regimentUnitIds: [regimentId],
        isHomeArmy: false,
      ),
    ],
    tileKeysByRegionAndProvince: {
      'oldWorld': {
        fromProvinceId: [fromTile],
        oldDestProvinceId: [oldDestTile],
      },
      'newWorld': {
        newDestProvinceId: [newDestTile],
      },
    },
    playerVisibilityByTile: {
      playerId: {
        fromTile: 'fullyVisible',
        oldDestTile: 'fullyVisible',
        newDestTile: 'fullyVisible',
      },
    },
  );
}
/// Adjacent hostile province for invasion declare-war confirm.
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
      Player(
        id: playerId,
        displayName: playerDisplayName,
        isHuman: true,
        capitalProvinceId: stationProvinceId,
      ),
      Player(
        id: enemyId,
        displayName: enemyDisplayName,
        isHuman: true,
        capitalProvinceId: hostileProvinceId,
      ),
    ],
    oldWorldProvinces: [
      Province(
        id: stationProvinceId,
        regionId: 'oldWorld',
        ownerId: playerId,
      ),
      Province(
        id: hostileProvinceId,
        regionId: 'oldWorld',
        ownerId: enemyId,
        displayName: hostileDisplayName,
      ),
    ],
    oldWorldUnits: [
      Unit(
        id: regimentId,
        type: regimentType,
        ownerId: playerId,
        locationProvinceId: stationProvinceId,
      ),
    ],
    armies: [
      Army(
        id: armyId,
        ownerId: playerId,
        regionId: 'oldWorld',
        stationedProvinceId: stationProvinceId,
        regimentUnitIds: [regimentId],
        isHomeArmy: false,
      ),
    ],
    tileKeysByRegionAndProvince: {
      'oldWorld': {
        stationProvinceId: [stationTile],
        hostileProvinceId: [hostileTile],
      },
    },
    playerVisibilityByTile: {
      playerId: {
        stationTile: 'fullyVisible',
        hostileTile: 'fullyVisible',
      },
    },
  );
}
