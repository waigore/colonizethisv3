import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_app/features/game/flame/game_map_area_state_logic.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';

void main() {
  suppressLogsForTests();
  group('GameMapAreaStateLogic', () {
    group('displayProvinceOrSeaIdFromTileKey', () {
      test('extracts region and province from full tile key', () {
        expect(
          displayProvinceOrSeaIdFromTileKey('oldWorld|p1|10|20'),
          'oldWorld|p1',
        );
      });

      test('returns null for short keys', () {
        expect(displayProvinceOrSeaIdFromTileKey('badKey'), isNull);
        expect(displayProvinceOrSeaIdFromTileKey(null), isNull);
      });
    });

    group('regionIndexFromWorldRegionId', () {
      test('newWorld maps to index 1', () {
        expect(
          GameMapAreaStateLogic.regionIndexFromWorldRegionId('newWorld'),
          1,
        );
      });

      test('any other region maps to index 0', () {
        expect(
          GameMapAreaStateLogic.regionIndexFromWorldRegionId('oldWorld'),
          0,
        );
      });
    });

    group('isWorkTargetTileProvinceBased', () {
      test('explore/steal_tech/counter_spy are province-based', () {
        expect(
          GameMapAreaStateLogic.isWorkTargetTileProvinceBased('explore'),
          isTrue,
        );
        expect(
          GameMapAreaStateLogic.isWorkTargetTileProvinceBased('steal_tech'),
          isTrue,
        );
        expect(
          GameMapAreaStateLogic.isWorkTargetTileProvinceBased('counter_spy'),
          isTrue,
        );
      });

      test('move is not province-based', () {
        expect(
          GameMapAreaStateLogic.isWorkTargetTileProvinceBased('move'),
          isFalse,
        );
      });
    });

    group('translateWorkTargetTileKey', () {
      test('province-based work targets rewrite tile coords to x=0,y=0', () {
        final translated =
            GameMapAreaStateLogic.translateWorkTargetTileKey(
          tileKey: 'oldWorld|p1|10|20',
          workTarget: 'explore',
        );
        expect(translated, 'oldWorld|p1|0|0');
      });

      test('non-province-based work targets return tileKey unchanged', () {
        final translated =
            GameMapAreaStateLogic.translateWorkTargetTileKey(
          tileKey: 'oldWorld|p1|10|20',
          workTarget: 'move',
        );
        expect(translated, 'oldWorld|p1|10|20');
      });

      test('short tile keys return tileKey unchanged', () {
        final translated =
            GameMapAreaStateLogic.translateWorkTargetTileKey(
          tileKey: 'oldWorld|p1',
          workTarget: 'explore',
        );
        // With parts length >= 2, province-based work targets normalize to x=0,y=0.
        expect(translated, 'oldWorld|p1|0|0');
      });
    });

    group('addHumanWorkOrder', () {
      test('appends work order under given humanPlayerId', () {
        const humanPlayerId = 'gp1';
        final orders = Orders(
          workOrdersByPlayerId: const {
            humanPlayerId: [],
          },
        );
        final workOrder = WorkOrder(
          unitId: 'u1',
          target: 'explore',
          targetTileKey: 'oldWorld|p1|0|0',
        );

        final updated = GameMapAreaStateLogic.addHumanWorkOrder(
          orders: orders,
          humanPlayerId: humanPlayerId,
          workOrder: workOrder,
        );

        expect(
          updated.workOrdersByPlayerId[humanPlayerId],
          [workOrder],
        );
      });
    });
  });
}

