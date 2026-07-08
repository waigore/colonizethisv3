import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_orders_test_support_layout.dart';

void main() {
  group('ordersTestSupportLayoutViolationReason', () {
    test('allows non-test Dart under support/', () {
      expect(
        ordersTestSupportLayoutViolationReason(
          'packages/colonizethis_orders/test/orders/support/foo.dart',
        ),
        isNull,
      );
    });

    test('allows *_test.dart outside support/', () {
      expect(
        ordersTestSupportLayoutViolationReason(
          'packages/colonizethis_orders/test/orders/bar_test.dart',
        ),
        isNull,
      );
    });

    test('flags non-test Dart at test/orders/ root', () {
      expect(
        ordersTestSupportLayoutViolationReason(
          'packages/colonizethis_orders/test/orders/orphan_support.dart',
        ),
        isNotNull,
      );
    });
  });

  group('runCheckOrdersTestSupportLayout', () {
    test('passes on current repo tree', () {
      expect(runCheckOrdersTestSupportLayout('.'), 0);
    });

    test('fails when a support file is left outside support/', () {
      final temp = Directory.systemTemp.createTempSync('orders-support-layout-');
      try {
        final orders = Directory(
          p.join(temp.path, 'packages', 'colonizethis_orders', 'test', 'orders'),
        )..createSync(recursive: true);
        File(p.join(orders.path, 'orphan_helpers.dart')).writeAsStringSync(
          'void orphan() {}\n',
        );

        final errors = <String>[];
        final code = runCheckOrdersTestSupportLayout(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('orphan_helpers.dart'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}
