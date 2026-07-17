// Military units-panel scenario Game factories (Refs #4048).
// SPEC: SPEC/ui/military-units-panel.md; SPEC/program/repo-lint.md.
import 'package:colonizethis_models/colonizethis_models.dart';
import 'panel_fixtures/core.dart';
import 'units_panel_test_shared.dart';

/// Minimal province + tile-key lookup (Refs #4013).
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

/// Sea-zone fleet display (Refs #4013).
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
        ? [Province(id: provinceId, regionId: 'oldWorld', ownerId: playerId)]
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
    portsByProvinceSeaboard: const {'oldWorld|lisbon|atlantic': tileKey},
    tileKeysByRegionAndProvince: const {
      'oldWorld': {
        'oldWorld|lisbon': [tileKey],
      },
    },
  );
}

/// Land army at Lisbon (medals / status).
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
      _owProvince(provinceId, playerId, townTileKey: tileKey),
    ],
    oldWorldUnits: units,
    armies: [
      _army(
        id: armyId,
        ownerId: playerId,
        stationedProvinceId: provinceId,
        regimentUnitIds: units.map((u) => u.id).toList(growable: false),
      ),
    ],
    tileKeysByRegionAndProvince: _owTiles({
      provinceId: [tileKey],
    }),
  );
}

/// Home army at capital (Refs #4013).
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
    players: [_human(playerId, playerDisplayName, capitalProvinceId)],
    oldWorldProvinces: [
      _owProvince(
        capitalProvinceId,
        playerId,
        displayName: 'Capital',
        townTileKey: townTileKey,
      ),
    ],
    oldWorldUnits: _regimentsAt(
      regimentIds,
      playerId,
      capitalProvinceId,
      type: regimentType,
    ),
    armies: [
      _army(
        id: armyId,
        ownerId: playerId,
        stationedProvinceId: capitalProvinceId,
        regimentUnitIds: List<String>.from(regimentIds),
        isHomeArmy: true,
      ),
    ],
    tileKeysByRegionAndProvince: _owTiles({
      capitalProvinceId: [townTileKey],
    }),
  );
}

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
    players: [_human(playerId, playerDisplayName, fullProvince)],
    oldWorldProvinces: [
      _owProvince(
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
      _army(
        id: armyId,
        ownerId: playerId,
        stationedProvinceId: fullProvince,
        regimentUnitIds: [regimentId],
      ),
    ],
    tileKeysByRegionAndProvince: _owTiles({
      fullProvince: [townTile],
    }),
  );
}

/// Two field armies at one province (Combine).
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
    players: [_human(playerId, playerDisplayName, capitalProvinceId)],
    oldWorldProvinces: [
      _owProvince(provinceId, playerId, townTileKey: townTileKey),
    ],
    oldWorldUnits: _regimentsAt(
      [regimentIdA, regimentIdB],
      playerId,
      provinceId,
      type: regimentType,
    ),
    armies: [
      _army(
        id: armyIdA,
        ownerId: playerId,
        stationedProvinceId: provinceId,
        regimentUnitIds: [regimentIdA],
      ),
      _army(
        id: armyIdB,
        ownerId: playerId,
        stationedProvinceId: provinceId,
        regimentUnitIds: [regimentIdB],
      ),
    ],
    tileKeysByRegionAndProvince: _owTiles({
      provinceId: [townTileKey],
    }),
  );
}

/// Field army + adjacent owned dest (Move/Locate).
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
    players: [_human(playerId, playerDisplayName, stationProvinceId)],
    oldWorldProvinces: [
      _owProvince(
        stationProvinceId,
        playerId,
        displayName: stationDisplayName,
        townTileKey: stationTownTileKey,
      ),
      _owProvince(
        adjacentProvinceId,
        playerId,
        displayName: adjacentDisplayName,
      ),
    ],
    oldWorldUnits: _regimentsAt(
      regimentUnitIds,
      playerId,
      stationProvinceId,
      type: regimentType,
    ),
    armies: [
      _army(
        id: armyId,
        ownerId: playerId,
        stationedProvinceId: stationProvinceId,
        regimentUnitIds: List<String>.from(regimentUnitIds),
      ),
    ],
    tileKeysByRegionAndProvince: includeTileKeysAndVisibility
        ? _owTiles({
            stationProvinceId: [stationTile],
            adjacentProvinceId: [adjacentTile],
          })
        : const {},
    playerVisibilityByTile: includeTileKeysAndVisibility
        ? _visibility(playerId, [stationTile, adjacentTile])
        : const {},
  );
}

/// Cross-region OW+NW owned dests (MoveArmyDialog).
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
    players: [_human(playerId, playerDisplayName, fromProvinceId)],
    oldWorldProvinces: [
      _owProvince(
        fromProvinceId,
        playerId,
        displayName: fromDisplayName,
        townTileKey: fromTownTileKey,
      ),
      _owProvince(oldDestProvinceId, playerId, displayName: oldDestDisplayName),
    ],
    newWorldProvinces: [
      Province(
        id: newDestProvinceId,
        regionId: 'newWorld',
        ownerId: playerId,
        displayName: newDestDisplayName,
      ),
    ],
    oldWorldUnits: _regimentsAt(
      [regimentId],
      playerId,
      fromProvinceId,
      type: regimentType,
    ),
    armies: [
      _army(
        id: armyId,
        ownerId: playerId,
        stationedProvinceId: fromProvinceId,
        regimentUnitIds: [regimentId],
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
    playerVisibilityByTile: _visibility(playerId, [
      fromTile,
      oldDestTile,
      newDestTile,
    ]),
  );
}

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
      _human(playerId, playerDisplayName, stationProvinceId),
      _human(enemyId, enemyDisplayName, hostileProvinceId),
    ],
    oldWorldProvinces: [
      _owProvince(stationProvinceId, playerId),
      _owProvince(hostileProvinceId, enemyId, displayName: hostileDisplayName),
    ],
    oldWorldUnits: _regimentsAt(
      [regimentId],
      playerId,
      stationProvinceId,
      type: regimentType,
    ),
    armies: [
      _army(
        id: armyId,
        ownerId: playerId,
        stationedProvinceId: stationProvinceId,
        regimentUnitIds: [regimentId],
      ),
    ],
    tileKeysByRegionAndProvince: _owTiles({
      stationProvinceId: [stationTile],
      hostileProvinceId: [hostileTile],
    }),
    playerVisibilityByTile: _visibility(playerId, [stationTile, hostileTile]),
  );
}

Player _human(String id, String name, String capital) => Player(
  id: id,
  displayName: name,
  isHuman: true,
  capitalProvinceId: capital,
);
Province _owProvince(
  String id,
  String ownerId, {
  String? displayName,
  String? townTileKey,
}) => Province(
  id: id,
  regionId: 'oldWorld',
  ownerId: ownerId,
  displayName: displayName,
  townTileKey: townTileKey,
);
List<Unit> _regimentsAt(
  List<String> ids,
  String ownerId,
  String provinceId, {
  required String type,
}) => [
  for (final id in ids)
    Unit(id: id, type: type, ownerId: ownerId, locationProvinceId: provinceId),
];
Army _army({
  required String id,
  required String ownerId,
  required String stationedProvinceId,
  required List<String> regimentUnitIds,
  bool isHomeArmy = false,
}) => Army(
  id: id,
  ownerId: ownerId,
  regionId: 'oldWorld',
  stationedProvinceId: stationedProvinceId,
  regimentUnitIds: regimentUnitIds,
  isHomeArmy: isHomeArmy,
);
Map<String, Map<String, List<String>>> _owTiles(
  Map<String, List<String>> byProvince,
) => {'oldWorld': byProvince};
Map<String, Map<String, String>> _visibility(
  String playerId,
  List<String> tiles,
) => {
  playerId: {for (final tile in tiles) tile: 'fullyVisible'},
};
