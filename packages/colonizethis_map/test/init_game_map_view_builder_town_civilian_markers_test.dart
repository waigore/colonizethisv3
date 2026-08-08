import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/init_game_map_view_fixtures.dart';
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
      () {
        final game = civilianMarkersGame();
        final viewData = buildViewDataForScenario(civilianMarkersScenario(game));

        final markers = viewData.oldWorld.civilianTileMarkers;
        expect(markers, hasLength(2));

        final tile00 = markers.singleWhere(
          (m) => m.tileKey == 'oldWorld|p1|0|0',
        );
        expect(tile00.stackCount, 2);
        expect(tile00.representativeUnitType, kUnitTypeBuilder);
        expect(tile00.representativeIsAssigned, isTrue);
        expect(tile00.unitIds, equals(['u_builder', 'u_spy']));
        expect(tile00.unitTypes['u_builder'], kUnitTypeBuilder);
        expect(tile00.unitTypes['u_spy'], kUnitTypeSpy);

        final tile10 = markers.singleWhere(
          (m) => m.tileKey == 'oldWorld|p2|1|0',
        );
        expect(tile10.stackCount, 1);
        expect(tile10.representativeUnitType, kUnitTypeEngineer);
        expect(tile10.representativeIsAssigned, isFalse);
        expect(tile10.unitIds, equals(['u_engineer']));
      },
    );

    test(
      'capital marker and stacked civilian marker can co-exist on same tile key',
      () {
        final game = capitalCivilianOverlapGame();
        final viewData = buildViewDataForScenario(
          capitalCivilianOverlapScenario(game),
        );

        expect(viewData.oldWorld.capitalMarkers, hasLength(1));
        final cap = viewData.oldWorld.capitalMarkers.single;
        expect(cap.x, 0);
        expect(cap.y, 0);

        expect(viewData.oldWorld.civilianTileMarkers, hasLength(1));
        final marker = viewData.oldWorld.civilianTileMarkers.single;
        expect(marker.tileKey, 'oldWorld|p1|0|0');
        expect(marker.stackCount, 2);
      },
    );
  });
}
