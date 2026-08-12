import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/trade_order_fixtures.dart';

void main() {
  group('TradeOrder constructor', () {
    test('constructs valid instance with isFtp default false', () {
      final order = sampleTradeOrder();
      expect(order.commodityId, 'timber');
      expect(order.type, TradeOrderType.bid);
      expect(order.quantity, 5);
      expect(order.priority, 2);
      expect(order.isFtp, false);
    });

    test('rejects invalid constructor arguments', () {
      for (final entry in <(String label, void Function() build)>[
        (
          'empty commodityId',
          () => TradeOrder(
            commodityId: '',
            type: TradeOrderType.bid,
            quantity: 1,
            priority: 1,
          ),
        ),
        (
          'negative quantity',
          () => TradeOrder(
            commodityId: 'timber',
            type: TradeOrderType.bid,
            quantity: -1,
            priority: 1,
          ),
        ),
        (
          'priority below 1',
          () => TradeOrder(
            commodityId: 'timber',
            type: TradeOrderType.bid,
            quantity: 1,
            priority: 0,
          ),
        ),
      ]) {
        expect(entry.$2, throwsA(isA<ArgumentError>()), reason: entry.$1);
      }
    });

    test(
      'accepts quantity == 0 (caller may carry zero-rest after partial)',
      () {
        expect(sampleTradeOrder(type: TradeOrderType.offer, quantity: 0).quantity, 0);
      },
    );
  });

  group('TradeOrder serialization', () {
    test('toJson produces canonical fields and omits originTileKey when null', () {
      final order = sampleTradeOrder(isFtp: true);
      expect(order.toJson(), {
        'commodityId': 'timber',
        'type': 'bid',
        'quantity': 5,
        'priority': 2,
        'isFtp': true,
      });
      expect(order.toJson().containsKey('originTileKey'), isFalse);
    });

    test('round-trips equal instance with all fields preserved', () {
      final order = sampleTradeOrder(
        commodityId: 'iron',
        type: TradeOrderType.offer,
        quantity: 12,
        priority: 3,
      );
      final restored = TradeOrder.fromJson(order.toJson());
      expect(restored, equals(order));
      expect(restored.hashCode, equals(order.hashCode));
    });

    test('fromJson rejects missing/invalid fields', () {
      for (final json in [
        {
          'commodityId': 'timber',
          'type': 'invalid_type',
          'quantity': 1,
          'priority': 1,
          'isFtp': false,
        },
        {
          'commodityId': 'timber',
          'type': 'bid',
          'quantity': 'not-a-number',
          'priority': 1,
          'isFtp': false,
        },
      ]) {
        expect(() => TradeOrder.fromJson(json), throwsA(isA<ArgumentError>()));
      }
    });
  });

  group('TradeOrder equality and copyWith', () {
    test('equality is field-based', () {
      final a = sampleTradeOrder();
      final b = sampleTradeOrder();
      expect(a, equals(b));
      expect(a, isNot(equals(a.copyWith(quantity: 6))));
    });

    test('equality differs when only originTileKey differs', () {
      final a = sampleTradeOrder(type: TradeOrderType.offer, priority: 1);
      final b = sampleTradeOrder(
        type: TradeOrderType.offer,
        priority: 1,
        originTileKey: 'oldWorld|M1|0|0',
      );
      expect(a, isNot(equals(b)));
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('copyWith originTileKey semantics', () {
      final withKey = sampleTradeOrder(
        type: TradeOrderType.offer,
        priority: 1,
        originTileKey: 'oldWorld|M1|0|0',
      );
      expect(withKey.copyWith(quantity: 3).originTileKey, 'oldWorld|M1|0|0');
      expect(withKey.copyWith(originTileKey: null).originTileKey, isNull);
      expect(
        sampleTradeOrder(type: TradeOrderType.offer, priority: 1)
            .copyWith(originTileKey: 'newWorld|T2|3|3')
            .originTileKey,
        'newWorld|T2|3|3',
      );
    });
  });

  group('TradeOrder originTileKey (#2992 D2)', () {
    test('originTileKey defaults to null', () {
      expect(
        sampleTradeOrder(type: TradeOrderType.offer, priority: 1).originTileKey,
        isNull,
      );
    });

    test('rejects empty originTileKey', () {
      expect(
        () => sampleTradeOrder(
          type: TradeOrderType.offer,
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

    test('JSON originTileKey round-trip and omission rules', () {
      final withKey = sampleTradeOrder(
        type: TradeOrderType.offer,
        priority: 1,
        originTileKey: 'oldWorld|M1|0|0',
      );
      expect(withKey.toJson()['originTileKey'], 'oldWorld|M1|0|0');
      expect(TradeOrder.fromJson(withKey.toJson()), equals(withKey));

      for (final json in [
        {
          'commodityId': 'timber',
          'type': 'offer',
          'quantity': 5,
          'priority': 1,
          'isFtp': false,
        },
        {
          'commodityId': 'timber',
          'type': 'offer',
          'quantity': 5,
          'priority': 1,
          'isFtp': false,
          'originTileKey': '',
        },
      ]) {
        expect(TradeOrder.fromJson(json).originTileKey, isNull);
      }
    });
  });
}
