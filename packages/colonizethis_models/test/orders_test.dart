import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('Orders', () {
    test('toJson/fromJson round-trip empty', () {
      const o = Orders();
      final o2 = Orders.fromJson(o.toJson());
      expect(o2.moveOrdersByPlayerId, isEmpty);
    });
    test('toJson/fromJson round-trip with data', () {
      const o = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|prov1|0|0'),
          ],
        },
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'Regiment',
              isMilitary: true,
              spawnProvinceId: 'oldWorld|prov1',
            ),
          ],
        },
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'u1',
              target: 'build_mine',
              targetTileKey: 'oldWorld|prov1|0|0',
            ),
          ],
        },
      );
      final o2 = Orders.fromJson(o.toJson());
      expect(o2.moveOrdersByPlayerId['p1']!.single.unitId, 'u1');
      expect(
        o2.moveOrdersByPlayerId['p1']!.single.destinationTileKey,
        'oldWorld|prov1|0|0',
      );
      expect(o2.buildUnitOrdersByPlayerId['p1']!.single.unitType, 'Regiment');
      expect(o2.workOrdersByPlayerId['p1']!.single.target, 'build_mine');
    });
    test('equality', () {
      const a = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|prov1|0|0'),
          ],
        },
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'Regiment',
              isMilitary: true,
              spawnProvinceId: 'oldWorld|prov1',
            ),
          ],
        },
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'u1',
              target: 'build_mine',
              targetTileKey: 'oldWorld|prov1|0|0',
            ),
          ],
        },
      );
      const b = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|prov1|0|0'),
          ],
        },
        buildUnitOrdersByPlayerId: {
          'p1': [
            BuildUnitOrder(
              unitType: 'Regiment',
              isMilitary: true,
              spawnProvinceId: 'oldWorld|prov1',
            ),
          ],
        },
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'u1',
              target: 'build_mine',
              targetTileKey: 'oldWorld|prov1|0|0',
            ),
          ],
        },
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
    test('fromJson with null or missing byPlayerId', () {
      final o = Orders.fromJson({});
      expect(o.moveOrdersByPlayerId, isEmpty);
      expect(o.buildUnitOrdersByPlayerId, isEmpty);
      expect(o.workOrdersByPlayerId, isEmpty);
      final o2 = Orders.fromJson({'moveOrdersByPlayerId': null});
      expect(o2.moveOrdersByPlayerId, isEmpty);
    });
    test('equality false when different', () {
      const a = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|prov1|0|0'),
          ],
        },
      );
      const b = Orders(
        moveOrdersByPlayerId: {
          'p2': [
            MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|prov2|0|0'),
          ],
        },
      );
      expect(a == b, false);
      expect(a == Object(), false);
    });

    test(
      'fromJson throws for unprefixed army move destination province id',
      () {
        expect(
          () => Orders.fromJson({
            'armyMoveOrdersByPlayerId': {
              'p1': [
                {'armyId': 'a1', 'destinationProvinceId': 'p1'},
              ],
            },
          }),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test('fromJson throws for unprefixed build-unit spawn province id', () {
      expect(
        () => Orders.fromJson({
          'buildUnitOrdersByPlayerId': {
            'p1': [
              {
                'unitType': 'Regiment',
                'isMilitary': true,
                'spawnProvinceId': 'p1',
              },
            ],
          },
        }),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
