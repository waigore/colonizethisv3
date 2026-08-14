import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'support/init_game_map_view_fixtures.dart';

void main() {
  group('buildInitGameMapViewData armyTileMarkers (Refs #4384)', () {
    test('draws empty Home Army at the capital town tile', () {
      final view = _armyMarkerView(
        armies: const [
          Army(
            id: 'army_home',
            ownerId: 'gp1',
            regionId: 'oldWorld',
            stationedProvinceId: 'oldWorld|p1',
            regimentUnitIds: [],
            isHomeArmy: true,
          ),
        ],
      );
      expect(view.oldWorld.armyTileMarkers, hasLength(1));
      final marker = view.oldWorld.armyTileMarkers.single;
      expect(marker.armyIds, ['army_home']);
      expect(marker.fieldArmyIds, isEmpty);
      expect(marker.stackCount, 1);
      expect(marker.hasHomeArmy, isTrue);
      expect(marker.provinceId, 'oldWorld|p1');
      expect(marker.tileKey, 'oldWorld|p1|0|0');
    });

    test('mixed capital stack counts Home plus field army', () {
      final view = _armyMarkerView(
        armies: const [
          Army(
            id: 'army_field',
            ownerId: 'gp1',
            regionId: 'oldWorld',
            stationedProvinceId: 'oldWorld|p1',
            regimentUnitIds: ['reg_1'],
          ),
          Army(
            id: 'army_home',
            ownerId: 'gp1',
            regionId: 'oldWorld',
            stationedProvinceId: 'oldWorld|p1',
            regimentUnitIds: ['reg_home'],
            isHomeArmy: true,
          ),
        ],
      );
      final marker = view.oldWorld.armyTileMarkers.single;
      expect(marker.stackCount, 2);
      expect(marker.armyIds, ['army_field', 'army_home']);
      expect(marker.fieldArmyIds, ['army_field']);
      expect(marker.hasHomeArmy, isTrue);
    });

    test('omits AI-owned armies even when stationed at a town', () {
      final view = _armyMarkerView(
        armies: const [
          Army(
            id: 'army_ai',
            ownerId: 'gp2',
            regionId: 'oldWorld',
            stationedProvinceId: 'oldWorld|p1',
            regimentUnitIds: ['reg_ai'],
          ),
        ],
        extraPlayers: const [
          Player(id: 'gp2', displayName: 'GP2', isHuman: false),
        ],
      );
      expect(view.oldWorld.armyTileMarkers, isEmpty);
    });

    test('omits empty non-Home field armies', () {
      final view = _armyMarkerView(
        armies: const [
          Army(
            id: 'army_empty_field',
            ownerId: 'gp1',
            regionId: 'oldWorld',
            stationedProvinceId: 'oldWorld|p1',
            regimentUnitIds: [],
          ),
        ],
      );
      expect(view.oldWorld.armyTileMarkers, isEmpty);
    });
  });

  group('ArmyTileMarkerLayout (Refs #4384)', () {
    test('hits only the bottom-right sub-rect of the cell', () {
      const cellSize = 32.0;
      expect(ArmyTileMarkerLayout.originFrac, 0.55);
      expect(
        ArmyTileMarkerLayout.hitTestInCell(
          localX: cellSize * 0.8,
          localY: cellSize * 0.8,
          cellSize: cellSize,
        ),
        isTrue,
      );
      expect(
        ArmyTileMarkerLayout.hitTestInCell(
          localX: cellSize * 0.2,
          localY: cellSize * 0.2,
          cellSize: cellSize,
        ),
        isFalse,
      );
      expect(
        ArmyTileMarkerLayout.hitTestInCell(localX: 10, localY: 10, cellSize: 0),
        isFalse,
      );
    });
  });
}

InitGameMapViewData _armyMarkerView({
  required List<Army> armies,
  List<Player> extraPlayers = const [],
}) {
  return buildViewDataForScenario(
    oldWorldFocusedScenario(
      game: minimalGame(
        id: 'army-markers',
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            ownerId: 'gp1',
            townTileKey: 'oldWorld|p1|0|0',
          ),
        ],
        armies: armies,
        players: [
          const Player(
            id: 'gp1',
            displayName: 'GP1',
            isHuman: true,
            capitalTile: CapitalTile(
              regionId: 'oldWorld',
              provinceId: 'oldWorld|p1',
              x: 0,
              y: 0,
            ),
          ),
          ...extraPlayers,
        ],
      ),
      oldWorldGrid: const [
        ['p1'],
      ],
      oldWorldTopology: regionTopology(
        regionId: 'oldWorld',
        provinceIds: const ['p1'],
      ),
    ),
  );
}
