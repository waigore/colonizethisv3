import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('GameMapAreaArmyDraftProjection (Refs #4384)', () {
    test('empty army set returns the input region unchanged', () {
      final region = _region();
      final result = GameMapAreaArmyDraftProjection.project(
        region: region,
        game: _game(armies: const []),
        orders: const ct_models.Orders(),
        humanPlayerId: 'gp1',
      );
      expect(identical(result, region), isTrue);
    });

    test('grayscale when every field army has a pending ArmyMoveOrder', () {
      final region = _region(
        armyTileMarkers: [
          _marker(
            armyIds: const ['army_field'],
            fieldArmyIds: const ['army_field'],
          ),
        ],
      );
      final projected = GameMapAreaArmyDraftProjection.project(
        region: region,
        game: _game(
          armies: const [
            ct_models.Army(
              id: 'army_field',
              ownerId: 'gp1',
              regionId: 'oldWorld',
              stationedProvinceId: 'oldWorld|p1',
              regimentUnitIds: ['reg_1'],
            ),
          ],
        ),
        orders: const ct_models.Orders(
          armyMoveOrdersByPlayerId: {
            'gp1': [
              ct_models.ArmyMoveOrder(
                armyId: 'army_field',
                destinationProvinceId: 'oldWorld|p1',
              ),
            ],
          },
        ),
        humanPlayerId: 'gp1',
      );
      expect(projected.armyTileMarkers.single.renderGrayscale, isTrue);
    });

    test('Home-only stack is not grayscale', () {
      final region = _region(
        armyTileMarkers: [
          _marker(
            armyIds: const ['army_home'],
            fieldArmyIds: const [],
            hasHomeArmy: true,
          ),
        ],
      );
      final projected = GameMapAreaArmyDraftProjection.project(
        region: region,
        game: _game(
          armies: const [
            ct_models.Army(
              id: 'army_home',
              ownerId: 'gp1',
              regionId: 'oldWorld',
              stationedProvinceId: 'oldWorld|p1',
              regimentUnitIds: [],
              isHomeArmy: true,
            ),
          ],
        ),
        orders: const ct_models.Orders(),
        humanPlayerId: 'gp1',
      );
      expect(projected.armyTileMarkers.single.renderGrayscale, isFalse);
      expect(projected.armyTileMarkers.single.stackCount, 1);
    });

    test('projects a pending move onto the destination town tile', () {
      final region = _region(
        width: 2,
        cells: const [
          CellViewData(x: 0, y: 0, regionCellId: 'p1', isSea: false),
          CellViewData(x: 1, y: 0, regionCellId: 'p2', isSea: false),
        ],
        townMarkers: const [
          TownMarkerView(
            x: 0,
            y: 0,
            provinceId: 'p1',
            isCoastal: false,
            isPort: false,
            touchesSea: false,
            townDevelopmentLevel: 1,
            townIconStyle: 'euro',
          ),
          TownMarkerView(
            x: 1,
            y: 0,
            provinceId: 'p2',
            isCoastal: false,
            isPort: false,
            touchesSea: false,
            townDevelopmentLevel: 1,
            townIconStyle: 'euro',
          ),
        ],
        armyTileMarkers: [
          _marker(
            armyIds: const ['army_field'],
            fieldArmyIds: const ['army_field'],
          ),
        ],
      );
      final projected = GameMapAreaArmyDraftProjection.project(
        region: region,
        game: _game(
          armies: const [
            ct_models.Army(
              id: 'army_field',
              ownerId: 'gp1',
              regionId: 'oldWorld',
              stationedProvinceId: 'oldWorld|p1',
              regimentUnitIds: ['reg_1'],
            ),
          ],
        ),
        orders: const ct_models.Orders(
          armyMoveOrdersByPlayerId: {
            'gp1': [
              ct_models.ArmyMoveOrder(
                armyId: 'army_field',
                destinationProvinceId: 'oldWorld|p2',
              ),
            ],
          },
        ),
        humanPlayerId: 'gp1',
      );
      expect(projected.armyTileMarkers, hasLength(1));
      expect(projected.armyTileMarkers.single.tileKey, 'oldWorld|p2|1|0');
      expect(projected.armyTileMarkers.single.provinceId, 'oldWorld|p2');
      expect(projected.armyTileMarkers.single.renderGrayscale, isTrue);
    });
  });
}

ArmyTileMarkerView _marker({
  required List<String> armyIds,
  required List<String> fieldArmyIds,
  bool hasHomeArmy = false,
}) {
  return ArmyTileMarkerView(
    tileKey: 'oldWorld|p1|0|0',
    x: 0,
    y: 0,
    provinceId: 'oldWorld|p1',
    armyIds: armyIds,
    fieldArmyIds: fieldArmyIds,
    stackCount: armyIds.length,
    hasHomeArmy: hasHomeArmy,
  );
}

RegionMapViewData _region({
  int width = 1,
  List<CellViewData>? cells,
  List<TownMarkerView>? townMarkers,
  List<ArmyTileMarkerView> armyTileMarkers = const [],
}) {
  return RegionMapViewData(
    regionId: 'oldWorld',
    width: width,
    height: 1,
    cellSize: 16,
    cells:
        cells ??
        const [CellViewData(x: 0, y: 0, regionCellId: 'p1', isSea: false)],
    capitalMarkers: const [],
    portMarkers: const [],
    factionColors: const {},
    greatPowerFactionIds: const {},
    terrainColors: const {},
    unitMarkers: const [],
    armyTileMarkers: armyTileMarkers,
    townMarkers:
        townMarkers ??
        const [
          TownMarkerView(
            x: 0,
            y: 0,
            provinceId: 'p1',
            isCoastal: false,
            isPort: false,
            touchesSea: false,
            townDevelopmentLevel: 1,
            townIconStyle: 'euro',
          ),
        ],
  );
}

ct_models.Game _game({required List<ct_models.Army> armies}) {
  return ct_models.Game(
    id: 'g',
    worldState: ct_models.WorldState(
      turnState: const ct_models.TurnState(
        phase: ct_models.TurnPhase.orders,
        turnNumber: 1,
      ),
      oldWorld: const ct_models.RegionData(
        provinces: [
          ct_models.Province(id: 'oldWorld|p1', regionId: 'oldWorld'),
          ct_models.Province(id: 'oldWorld|p2', regionId: 'oldWorld'),
        ],
        units: [],
      ),
      newWorld: const ct_models.RegionData(provinces: [], units: []),
      armies: armies,
    ),
    players: const [
      ct_models.Player(id: 'gp1', displayName: 'Human', isHuman: true),
    ],
    minorNations: const [],
    tribes: const [],
  );
}
