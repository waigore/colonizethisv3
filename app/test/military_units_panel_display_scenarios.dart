// Military units-panel display/lookup scenario factories (Refs #4352 Slice D).
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
      unitsPanelOwProvince(provinceId, playerId, townTileKey: tileKey),
    ],
    oldWorldUnits: units,
    armies: [
      unitsPanelArmy(
        id: armyId,
        ownerId: playerId,
        stationedProvinceId: provinceId,
        regimentUnitIds: units.map((u) => u.id).toList(growable: false),
      ),
    ],
    tileKeysByRegionAndProvince: unitsPanelOwTileKeys({
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
    players: [
      unitsPanelHumanPlayerWithCapital(
        playerId,
        playerDisplayName,
        capitalProvinceId,
      ),
    ],
    oldWorldProvinces: [
      unitsPanelOwProvince(
        capitalProvinceId,
        playerId,
        displayName: 'Capital',
        townTileKey: townTileKey,
      ),
    ],
    oldWorldUnits: unitsPanelRegimentsAt(
      regimentIds,
      playerId,
      capitalProvinceId,
      type: regimentType,
    ),
    armies: [
      unitsPanelArmy(
        id: armyId,
        ownerId: playerId,
        stationedProvinceId: capitalProvinceId,
        regimentUnitIds: List<String>.from(regimentIds),
        isHomeArmy: true,
      ),
    ],
    tileKeysByRegionAndProvince: unitsPanelOwTileKeys({
      capitalProvinceId: [townTileKey],
    }),
  );
}

export 'military_units_panel_display_label_scenarios.dart';
