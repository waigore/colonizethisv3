import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/orders_fixtures.dart';

void main() {
  group('Orders', () {
    test('toJson/fromJson round-trip empty', () {
      const o = Orders();
      final o2 = Orders.fromJson(o.toJson());
      expect(o2.moveOrdersByPlayerId, isEmpty);
    });

    test('toJson/fromJson round-trip with data', () {
      final o2 = Orders.fromJson(sampleOrdersWithBasics.toJson());
      expect(o2.moveOrdersByPlayerId['p1']!.single.unitId, 'u1');
      expect(
        o2.moveOrdersByPlayerId['p1']!.single.destinationTileKey,
        'oldWorld|prov1|0|0',
      );
      expect(o2.buildUnitOrdersByPlayerId['p1']!.single.unitType, 'Regiment');
      expect(o2.workOrdersByPlayerId['p1']!.single.target, 'build_mine');
    });

    test('equality', () {
      const a = sampleOrdersWithBasics;
      const b = sampleOrdersWithBasics;
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('fromJson with null or missing byPlayerId', () {
      for (final json in [
        <String, dynamic>{},
        <String, dynamic>{'moveOrdersByPlayerId': null},
      ]) {
        final o = Orders.fromJson(json);
        expect(o.moveOrdersByPlayerId, isEmpty);
        expect(o.buildUnitOrdersByPlayerId, isEmpty);
        expect(o.workOrdersByPlayerId, isEmpty);
      }
    });

    test('equality false when different', () {
      const a = Orders(
        moveOrdersByPlayerId: {
          'p1': [sampleMoveOrder],
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

    test('fromJson throws for unprefixed province ids', () {
      for (final json in [
        {
          'armyMoveOrdersByPlayerId': {
            'p1': [
              {'armyId': 'a1', 'destinationProvinceId': 'p1'},
            ],
          },
        },
        {
          'buildUnitOrdersByPlayerId': {
            'p1': [
              {
                'unitType': 'Regiment',
                'isMilitary': true,
                'spawnProvinceId': 'p1',
              },
            ],
          },
        },
      ]) {
        expect(() => Orders.fromJson(json), throwsA(isA<ArgumentError>()));
      }
    });

    test('round-trips recruitWorkerOrdersByPlayerId for every tier', () {
      final o2 = Orders.fromJson(allWorkerTierRecruitOrders.toJson());
      expect(o2.recruitWorkerOrdersByPlayerId['p1']!.length, 4);
      expect(
        o2.recruitWorkerOrdersByPlayerId['p1']!.map((e) => e.targetTier),
        WorkerTier.values,
      );
      expect(o2, allWorkerTierRecruitOrders);
      expect(o2.hashCode, allWorkerTierRecruitOrders.hashCode);
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

    test('copyWith recruit worker orders', () {
      const original = Orders(
        recruitWorkerOrdersByPlayerId: {
          'p1': [RecruitWorkerOrder(targetTier: WorkerTier.apprentice)],
        },
      );
      final preserved = original.copyWith();
      expect(preserved, original);
      expect(preserved.recruitWorkerOrdersByPlayerId, isNotEmpty);

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

    test('RecruitWorkerOrder.fromJson validation', () {
      for (final json in [
        <String, dynamic>{},
        <String, dynamic>{'targetTier': ''},
        <String, dynamic>{'targetTier': 'engineers'},
      ]) {
        expect(
          () => RecruitWorkerOrder.fromJson(json),
          throwsA(isA<ArgumentError>()),
        );
      }
      expect(
        const RecruitWorkerOrder(targetTier: WorkerTier.apprentice).toJson(),
        {'targetTier': 'apprentices'},
      );
    });
  });

  group('Orders.tradeOrdersByPlayerId', () {
    test('defaults to empty and toJson omits the key when empty', () {
      const o = Orders();
      expect(o.tradeOrdersByPlayerId, isEmpty);
      expect(o.toJson().containsKey('tradeOrdersByPlayerId'), isFalse);
    });

    test('round-trips multiple bids/offers across players via JSON', () {
      final o = sampleTradeOrders();
      final restored = Orders.fromJson(o.toJson());
      expect(restored.tradeOrdersByPlayerId.keys, {'p1', 'p2'});
      expect(restored.tradeOrdersByPlayerId['p1']!.length, 2);
      expect(restored.tradeOrdersByPlayerId['p2']!.single.commodityId, 'silk');
      expect(restored.tradeOrdersByPlayerId['p2']!.single.isFtp, isTrue);
      expect(restored, o);
      expect(restored.hashCode, o.hashCode);
    });

    test('equality false when trade orders differ', () {
      final a = sampleTradeOrders();
      final b = sampleTradeOrders(player1OfferQuantity: 20);
      expect(a == b, isFalse);
    });

    test('copyWith trade orders', () {
      final original = sampleTradeOrders();
      final preserved = original.copyWith();
      expect(preserved, original);
      expect(preserved.tradeOrdersByPlayerId, isNotEmpty);

      final updated = original.copyWith(
        tradeOrdersByPlayerId: {
          'p1': [
            TradeOrder(
              commodityId: 'iron',
              type: TradeOrderType.bid,
              quantity: 2,
              priority: 1,
            ),
          ],
        },
      );
      expect(
        updated.tradeOrdersByPlayerId['p1']!.single.commodityId,
        'iron',
      );
      expect(updated == original, isFalse);
    });

    test('fromJson defaults to empty map when key missing', () {
      final o = Orders.fromJson({});
      expect(o.tradeOrdersByPlayerId, isEmpty);
    });
  });
}
