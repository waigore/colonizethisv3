// Military units-panel move/combine/invasion scenario factories (Refs #4352 Slice D).
// SPEC: SPEC/ui/military-units-panel.md; SPEC/program/repo-lint.md.
import 'package:colonizethis_models/colonizethis_models.dart';
import 'panel_fixtures/core.dart';
import 'units_panel_test_shared.dart';

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
    players: [
      unitsPanelHumanPlayerWithCapital(
        playerId,
        playerDisplayName,
        capitalProvinceId,
      ),
    ],
    oldWorldProvinces: [
      unitsPanelOwProvince(provinceId, playerId, townTileKey: townTileKey),
    ],
    oldWorldUnits: unitsPanelRegimentsAt(
      [regimentIdA, regimentIdB],
      playerId,
      provinceId,
      type: regimentType,
    ),
    armies: [
      unitsPanelArmy(
        id: armyIdA,
        ownerId: playerId,
        stationedProvinceId: provinceId,
        regimentUnitIds: [regimentIdA],
      ),
      unitsPanelArmy(
        id: armyIdB,
        ownerId: playerId,
        stationedProvinceId: provinceId,
        regimentUnitIds: [regimentIdB],
      ),
    ],
    tileKeysByRegionAndProvince: unitsPanelOwTileKeys({
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
    players: [
      unitsPanelHumanPlayerWithCapital(
        playerId,
        playerDisplayName,
        stationProvinceId,
      ),
    ],
    oldWorldProvinces: [
      unitsPanelOwProvince(
        stationProvinceId,
        playerId,
        displayName: stationDisplayName,
        townTileKey: stationTownTileKey,
      ),
      unitsPanelOwProvince(
        adjacentProvinceId,
        playerId,
        displayName: adjacentDisplayName,
      ),
    ],
    oldWorldUnits: unitsPanelRegimentsAt(
      regimentUnitIds,
      playerId,
      stationProvinceId,
      type: regimentType,
    ),
    armies: [
      unitsPanelArmy(
        id: armyId,
        ownerId: playerId,
        stationedProvinceId: stationProvinceId,
        regimentUnitIds: List<String>.from(regimentUnitIds),
      ),
    ],
    tileKeysByRegionAndProvince: includeTileKeysAndVisibility
        ? unitsPanelOwTileKeys({
            stationProvinceId: [stationTile],
            adjacentProvinceId: [adjacentTile],
          })
        : const {},
    playerVisibilityByTile: includeTileKeysAndVisibility
        ? unitsPanelPlayerVisibility(playerId, [stationTile, adjacentTile])
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
    players: [
      unitsPanelHumanPlayerWithCapital(
        playerId,
        playerDisplayName,
        fromProvinceId,
      ),
    ],
    oldWorldProvinces: [
      unitsPanelOwProvince(
        fromProvinceId,
        playerId,
        displayName: fromDisplayName,
        townTileKey: fromTownTileKey,
      ),
      unitsPanelOwProvince(
        oldDestProvinceId,
        playerId,
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
    oldWorldUnits: unitsPanelRegimentsAt(
      [regimentId],
      playerId,
      fromProvinceId,
      type: regimentType,
    ),
    armies: [
      unitsPanelArmy(
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
    playerVisibilityByTile: unitsPanelPlayerVisibility(playerId, [
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
