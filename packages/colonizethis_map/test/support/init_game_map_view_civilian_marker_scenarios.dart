import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'init_game_map_view_fixtures.dart';

Game civilianMarkersGame() => minimalGame(
  id: 'civilian_markers',
  oldWorldProvinces: const [
    Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
    Province(id: 'oldWorld|p2', regionId: 'oldWorld'),
    Province(id: 'oldWorld|p3', regionId: 'oldWorld'),
  ],
  oldWorldUnits: [
    Unit(
      id: 'u_builder',
      type: kUnitTypeBuilder,
      ownerId: 'gp_human',
      locationProvinceId: 'oldWorld|p1',
      tileKey: 'oldWorld|p1|0|0',
      status: UnitStatus.working,
      assignedTileKey: 'oldWorld|p1|0|0',
    ),
    Unit(
      id: 'u_spy',
      type: kUnitTypeSpy,
      ownerId: 'gp_human',
      locationProvinceId: 'oldWorld|p1',
      tileKey: 'oldWorld|p1|0|0',
      status: UnitStatus.idle,
    ),
    Unit(
      id: 'u_engineer',
      type: kUnitTypeEngineer,
      ownerId: 'gp_human',
      locationProvinceId: 'oldWorld|p2',
      tileKey: 'oldWorld|p2|1|0',
      status: UnitStatus.idle,
    ),
    Unit(
      id: 'u_ai_builder',
      type: kUnitTypeBuilder,
      ownerId: 'gp_ai',
      locationProvinceId: 'oldWorld|p3',
      tileKey: 'oldWorld|p3|2|0',
      status: UnitStatus.idle,
    ),
    Unit(
      id: 'u_human_military',
      type: 'pikemen',
      ownerId: 'gp_human',
      locationProvinceId: 'oldWorld|p1',
      status: UnitStatus.idle,
    ),
    Unit(
      id: 'u_other_region',
      type: kUnitTypeMerchant,
      ownerId: 'gp_human',
      locationProvinceId: 'newWorld|p1',
      tileKey: 'newWorld|p1|0|0',
      status: UnitStatus.idle,
    ),
  ],
  newWorldProvinces: const [
    Province(id: 'newWorld|p1', regionId: 'newWorld'),
  ],
  players: const [
    Player(id: 'gp_human', displayName: 'Human', isHuman: true),
    Player(id: 'gp_ai', displayName: 'AI', isHuman: false),
  ],
);

DualRegionViewScenario civilianMarkersScenario(Game game) => dualRegionScenario(
  game: game,
  oldWorldGrid: const [
    ['p1', 'p2', 'p3'],
  ],
  oldWorldTopology: regionTopology(
    regionId: 'oldWorld',
    provinceIds: const ['p1', 'p2', 'p3'],
  ),
);

Game capitalCivilianOverlapGame() => minimalGame(
  id: 'capital_civilian_overlap',
  oldWorldProvinces: const [
    Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
  ],
  oldWorldUnits: [
    Unit(
      id: 'u_builder',
      type: kUnitTypeBuilder,
      ownerId: 'gp1',
      locationProvinceId: 'oldWorld|p1',
      tileKey: 'oldWorld|p1|0|0',
    ),
    Unit(
      id: 'u_explorer',
      type: kUnitTypeExplorer,
      ownerId: 'gp1',
      locationProvinceId: 'oldWorld|p1',
      tileKey: 'oldWorld|p1|0|0',
    ),
  ],
  newWorldProvinces: const [
    Province(id: 'newWorld|p1', regionId: 'newWorld'),
  ],
  players: const [
    Player(
      id: 'gp1',
      displayName: 'Human',
      isHuman: true,
      capitalProvinceId: 'oldWorld|p1',
      capitalTile: CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p1',
        x: 0,
        y: 0,
      ),
    ),
  ],
);

DualRegionViewScenario capitalCivilianOverlapScenario(Game game) =>
    dualRegionScenario(
      game: game,
      oldWorldGrid: const [
        ['p1'],
      ],
      oldWorldTopology: regionTopology(
        regionId: 'oldWorld',
        provinceIds: const ['p1'],
      ),
    );

void expectPlayerOwnedCivilianTileMarkers() {
  final game = civilianMarkersGame();
  final viewData = buildViewDataForScenario(civilianMarkersScenario(game));

  final markers = viewData.oldWorld.civilianTileMarkers;
  expect(markers, hasLength(2));

  final tile00 = markers.singleWhere((m) => m.tileKey == 'oldWorld|p1|0|0');
  expect(tile00.stackCount, 2);
  expect(tile00.representativeUnitType, kUnitTypeBuilder);
  expect(tile00.representativeIsAssigned, isTrue);
  expect(tile00.unitIds, equals(['u_builder', 'u_spy']));
  expect(tile00.unitTypes['u_builder'], kUnitTypeBuilder);
  expect(tile00.unitTypes['u_spy'], kUnitTypeSpy);

  final tile10 = markers.singleWhere((m) => m.tileKey == 'oldWorld|p2|1|0');
  expect(tile10.stackCount, 1);
  expect(tile10.representativeUnitType, kUnitTypeEngineer);
  expect(tile10.representativeIsAssigned, isFalse);
  expect(tile10.unitIds, equals(['u_engineer']));
}

void expectCapitalAndCivilianMarkerCoexist() {
  final game = capitalCivilianOverlapGame();
  final viewData = buildViewDataForScenario(capitalCivilianOverlapScenario(game));

  expect(viewData.oldWorld.capitalMarkers, hasLength(1));
  final cap = viewData.oldWorld.capitalMarkers.single;
  expect(cap.x, 0);
  expect(cap.y, 0);

  expect(viewData.oldWorld.civilianTileMarkers, hasLength(1));
  final marker = viewData.oldWorld.civilianTileMarkers.single;
  expect(marker.tileKey, 'oldWorld|p1|0|0');
  expect(marker.stackCount, 2);
}
