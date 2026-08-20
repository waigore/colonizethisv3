import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/init_game_map_view_fixtures.dart';
import 'support/init_game_map_view_army_marker_scenarios.dart';
import 'support/init_game_map_view_civilian_marker_scenarios.dart';
import 'support/init_game_map_view_town_civilian_scenarios.dart';

void main() {
  group('buildInitGameMapViewData town markers', () {
    test(
      'town markers: isPort with prefixed Province.id; port icon on port tile when separate from town',
      () {
        final game = townPortSepGame();
        final viewData = buildViewDataForScenario(townPortSepScenario(game));

        final tm = viewData.oldWorld.townMarkers.single;
        expect(tm.provinceId, 'p1');
        expect(tm.isPort, isTrue);
        expect(tm.isCoastal, isFalse);
        expect(tm.touchesSea, isTrue);
        expect(tm.x, 0);
        expect(tm.y, 0);
        expect(tm.portIconX, 2);
        expect(tm.portIconY, 1);
      },
    );

    test('town markers include non-player provinces with townTileKey', () {
      final game = townNonPlayerGame();
      final viewData = buildViewDataForScenario(townNonPlayerScenario(game));

      expect(viewData.oldWorld.townMarkers, hasLength(2));
      final ids = viewData.oldWorld.townMarkers
          .map((m) => m.provinceId)
          .toSet();
      expect(ids, containsAll({'pPlayer', 'pMinor'}));
    });

    test(
      'town markers: port on capital tile places port drawable on sea by town',
      () {
        final game = townPortCapGame();
        final viewData = buildViewDataForScenario(townPortCapScenario(game));

        final tm = viewData.oldWorld.townMarkers.single;
        expect(tm.isPort, isTrue);
        expect(tm.portIconX, 1);
        expect(tm.portIconY, 0);
      },
    );

    test('town markers: co-located port with no orthogonal sea throws', () {
      final game = townPortFallGame();
      final scenario = townPortFallScenario(game);

      expect(
        () => buildViewDataForScenario(scenario),
        throwsA(isA<PortDrawableSeaCellException>()),
      );
    });
  });

  group('buildInitGameMapViewData civilian tile markers', () {
    test(
      'builds deterministic player-owned civilian tile markers with priority and stack counts',
      expectPlayerOwnedCivilianTileMarkers,
    );

    test(
      'capital marker and stacked civilian marker can co-exist on same tile key',
      expectCapitalAndCivilianMarkerCoexist,
    );
  });

  group('buildInitGameMapViewData armyTileMarkers (Refs #4384)', () {
    test('draws empty Home Army at the capital town tile', () {
      final view = armyMarkerView(
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
      final view = armyMarkerView(
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
      final view = armyMarkerView(
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
      final view = armyMarkerView(
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
