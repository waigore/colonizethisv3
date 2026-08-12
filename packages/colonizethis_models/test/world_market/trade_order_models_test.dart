import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('TradeOrder constructor', () {
    test('constructs valid instance with isFtp default false', () {
      final order = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.bid,
        quantity: 5,
        priority: 2,
      );
      expect(order.commodityId, 'timber');
      expect(order.type, TradeOrderType.bid);
      expect(order.quantity, 5);
      expect(order.priority, 2);
      expect(order.isFtp, false);
    });

    test('rejects empty commodityId', () {
      expect(
        () => TradeOrder(
          commodityId: '',
          type: TradeOrderType.bid,
          quantity: 1,
          priority: 1,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects negative quantity', () {
      expect(
        () => TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.bid,
          quantity: -1,
          priority: 1,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'message',
            contains('quantity'),
          ),
        ),
      );
    });

    test('rejects priority below 1', () {
      expect(
        () => TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.bid,
          quantity: 1,
          priority: 0,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'message',
            contains('priority'),
          ),
        ),
      );
    });

    test(
      'accepts quantity == 0 (caller may carry zero-rest after partial)',
      () {
        final order = TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.offer,
          quantity: 0,
          priority: 1,
        );
        expect(order.quantity, 0);
      },
    );
  });

  group('TradeOrder serialization', () {
    test(
      'toJson produces canonical fields and omits originTileKey when null',
      () {
        final order = TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.bid,
          quantity: 5,
          priority: 2,
          isFtp: true,
        );
        expect(order.toJson(), {
          'commodityId': 'timber',
          'type': 'bid',
          'quantity': 5,
          'priority': 2,
          'isFtp': true,
        });
        expect(order.toJson().containsKey('originTileKey'), isFalse);
      },
    );

    test('round-trips equal instance with all fields preserved', () {
      final order = TradeOrder(
        commodityId: 'iron',
        type: TradeOrderType.offer,
        quantity: 12,
        priority: 3,
        isFtp: false,
      );
      final restored = TradeOrder.fromJson(order.toJson());
      expect(restored, equals(order));
      expect(restored.hashCode, equals(order.hashCode));
    });

    test('fromJson rejects missing/invalid type field', () {
      expect(
        () => TradeOrder.fromJson({
          'commodityId': 'timber',
          'type': 'invalid_type',
          'quantity': 1,
          'priority': 1,
          'isFtp': false,
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromJson rejects non-int quantity field', () {
      expect(
        () => TradeOrder.fromJson({
          'commodityId': 'timber',
          'type': 'bid',
          'quantity': 'not-a-number',
          'priority': 1,
          'isFtp': false,
        }),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('TradeOrder equality and copyWith', () {
    test('equality is field-based', () {
      final a = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.bid,
        quantity: 5,
        priority: 2,
      );
      final b = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.bid,
        quantity: 5,
        priority: 2,
      );
      final c = a.copyWith(quantity: 6);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('equality differs when only originTileKey differs', () {
      final a = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.offer,
        quantity: 5,
        priority: 1,
      );
      final b = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.offer,
        quantity: 5,
        priority: 1,
        originTileKey: 'oldWorld|M1|0|0',
      );
      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('copyWith preserves originTileKey when not specified', () {
      final order = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.offer,
        quantity: 5,
        priority: 1,
        originTileKey: 'oldWorld|M1|0|0',
      );
      final copy = order.copyWith(quantity: 3);
      expect(copy.originTileKey, 'oldWorld|M1|0|0');
      expect(copy.quantity, 3);
    });

    test('copyWith can clear originTileKey by passing null explicitly', () {
      final order = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.offer,
        quantity: 5,
        priority: 1,
        originTileKey: 'oldWorld|M1|0|0',
      );
      final cleared = order.copyWith(originTileKey: null);
      expect(cleared.originTileKey, isNull);
    });

    test('copyWith can replace originTileKey with a new value', () {
      final order = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.offer,
        quantity: 5,
        priority: 1,
      );
      final updated = order.copyWith(originTileKey: 'newWorld|T2|3|3');
      expect(updated.originTileKey, 'newWorld|T2|3|3');
    });
  });

  group('TradeOrder originTileKey (#2992 D2)', () {
    test('originTileKey defaults to null', () {
      final order = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.offer,
        quantity: 5,
        priority: 1,
      );
      expect(order.originTileKey, isNull);
    });

    test('rejects empty originTileKey', () {
      expect(
        () => TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.offer,
          quantity: 5,
          priority: 1,
          originTileKey: '',
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'message',
            contains('originTileKey'),
          ),
        ),
      );
    });

    test('toJson includes originTileKey when set', () {
      final order = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.offer,
        quantity: 5,
        priority: 1,
        originTileKey: 'oldWorld|M1|0|0',
      );
      expect(order.toJson()['originTileKey'], 'oldWorld|M1|0|0');
    });

    test('round-trips originTileKey through JSON', () {
      final order = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.offer,
        quantity: 5,
        priority: 1,
        originTileKey: 'oldWorld|M1|0|0',
      );
      final restored = TradeOrder.fromJson(order.toJson());
      expect(restored, equals(order));
      expect(restored.originTileKey, 'oldWorld|M1|0|0');
    });

    test('fromJson treats missing originTileKey as null', () {
      final restored = TradeOrder.fromJson({
        'commodityId': 'timber',
        'type': 'offer',
        'quantity': 5,
        'priority': 1,
        'isFtp': false,
      });
      expect(restored.originTileKey, isNull);
    });

    test('fromJson treats empty-string originTileKey as null', () {
      final restored = TradeOrder.fromJson({
        'commodityId': 'timber',
        'type': 'offer',
        'quantity': 5,
        'priority': 1,
        'isFtp': false,
        'originTileKey': '',
      });
      expect(restored.originTileKey, isNull);
    });
  });
}
