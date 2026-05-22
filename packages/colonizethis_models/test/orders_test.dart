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

    test('round-trips recruitWorkerOrdersByPlayerId for every tier', () {
      const o = Orders(
        recruitWorkerOrdersByPlayerId: {
          'p1': [
            RecruitWorkerOrder(targetTier: WorkerTier.peasant),
            RecruitWorkerOrder(targetTier: WorkerTier.apprentice),
            RecruitWorkerOrder(targetTier: WorkerTier.journeyman),
            RecruitWorkerOrder(targetTier: WorkerTier.master),
          ],
        },
      );
      final o2 = Orders.fromJson(o.toJson());
      expect(o2.recruitWorkerOrdersByPlayerId['p1']!.length, 4);
      expect(
        o2.recruitWorkerOrdersByPlayerId['p1']!.map((e) => e.targetTier),
        [
          WorkerTier.peasant,
          WorkerTier.apprentice,
          WorkerTier.journeyman,
          WorkerTier.master,
        ],
      );
      expect(o2, o);
      expect(o2.hashCode, o.hashCode);
    });

    test('toJson omits recruitWorkerOrdersByPlayerId when empty', () {
      const o = Orders();
      expect(o.toJson().containsKey('recruitWorkerOrdersByPlayerId'), isFalse);
    });

    test('equality false when recruit worker orders differ', () {
      const a = Orders(
        recruitWorkerOrdersByPlayerId: {
          'p1': [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
        },
      );
      const b = Orders(
        recruitWorkerOrdersByPlayerId: {
          'p1': [RecruitWorkerOrder(targetTier: WorkerTier.master)],
        },
      );
      expect(a == b, isFalse);
    });

    test('copyWith preserves recruit worker orders by default', () {
      const original = Orders(
        recruitWorkerOrdersByPlayerId: {
          'p1': [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
        },
      );
      final copy = original.copyWith();
      expect(copy, original);
      expect(copy.recruitWorkerOrdersByPlayerId, isNotEmpty);
    });

    test('copyWith can replace recruit worker orders', () {
      const original = Orders(
        recruitWorkerOrdersByPlayerId: {
          'p1': [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
        },
      );
      final updated = original.copyWith(
        recruitWorkerOrdersByPlayerId: const {
          'p1': [RecruitWorkerOrder(targetTier: WorkerTier.master)],
        },
      );
      expect(
        updated.recruitWorkerOrdersByPlayerId['p1']!.single.targetTier,
        WorkerTier.master,
      );
      expect(updated == original, isFalse);
    });

    test(
      'RecruitWorkerOrder.fromJson throws on missing targetTier',
      () {
        expect(
          () => RecruitWorkerOrder.fromJson(<String, dynamic>{}),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      'RecruitWorkerOrder.fromJson throws on empty targetTier',
      () {
        expect(
          () => RecruitWorkerOrder.fromJson({'targetTier': ''}),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test(
      'RecruitWorkerOrder.fromJson throws on unknown targetTier id',
      () {
        expect(
          () => RecruitWorkerOrder.fromJson({'targetTier': 'engineers'}),
          throwsA(isA<ArgumentError>()),
        );
      },
    );

    test('RecruitWorkerOrder.toJson uses canonical WorkerTier id', () {
      expect(
        const RecruitWorkerOrder(targetTier: WorkerTier.apprentice).toJson(),
        {'targetTier': 'apprentices'},
      );
    });
  });
}
