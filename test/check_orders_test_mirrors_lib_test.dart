import 'package:test/test.dart';

import '../tool/check_orders_test_mirrors_lib.dart';

void main() {
  group('ordersTestMirrorsLibPathInScope', () {
    test('positive: paths under the orders test tree are in scope', () {
      expect(
        ordersTestMirrorsLibPathInScope(
          'packages/colonizethis_orders/test/orders/foo_test.dart',
        ),
        isTrue,
      );
      expect(
        ordersTestMirrorsLibPathInScope(
          'packages\\colonizethis_orders\\test\\bar_test.dart',
        ),
        isTrue,
      );
    });

    test('negative: lib sources and other packages are out of scope', () {
      expect(
        ordersTestMirrorsLibPathInScope(
          'packages/colonizethis_orders/lib/src/orders/foo.dart',
        ),
        isFalse,
      );
      expect(
        ordersTestMirrorsLibPathInScope(
          'packages/colonizethis_combat/test/foo_test.dart',
        ),
        isFalse,
      );
    });
  });

  group('ordersTestMirrorsLibViolationReason', () {
    test('positive: a flat-root test file is flagged', () {
      final reason = ordersTestMirrorsLibViolationReason(
        'packages/colonizethis_orders/test/order_merge_part1_test.dart',
      );
      expect(reason, isNotNull);
      expect(reason, contains('test/orders/'));
    });

    test('positive: a flat-root support helper is flagged', () {
      final reason = ordersTestMirrorsLibViolationReason(
        'packages/colonizethis_orders/test/order_engine_purchase_land_test_support.dart',
      );
      expect(reason, isNotNull);
    });

    test('positive: backslash-separated flat-root path is flagged', () {
      final reason = ordersTestMirrorsLibViolationReason(
        'packages\\colonizethis_orders\\test\\order_merge_part1_test.dart',
      );
      expect(reason, isNotNull);
    });

    test('negative: a nested test file under test/orders/ is allowed', () {
      final reason = ordersTestMirrorsLibViolationReason(
        'packages/colonizethis_orders/test/orders/order_merge_part1_test.dart',
      );
      expect(reason, isNull);
    });

    test('negative: a deeply nested test file is allowed', () {
      final reason = ordersTestMirrorsLibViolationReason(
        'packages/colonizethis_orders/test/orders/validators/diplomatic/foo_test.dart',
      );
      expect(reason, isNull);
    });

    test('negative: files outside the orders test tree are ignored', () {
      expect(
        ordersTestMirrorsLibViolationReason(
          'packages/colonizethis_combat/test/foo_test.dart',
        ),
        isNull,
      );
      expect(
        ordersTestMirrorsLibViolationReason(
          'packages/colonizethis_orders/lib/src/orders/order_merge.dart',
        ),
        isNull,
      );
    });
  });

  group('runCheckOrdersTestMirrorsLib', () {
    test('passes on the current repo tree', () {
      expect(runCheckOrdersTestMirrorsLib('.'), 0);
    });
  });
}
