// Refs #3877 — guards `repo.orders_test_no_src_imports`.
import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_orders_test_no_src_imports.dart';

void main() {
  final repoRoot = Directory.current.path;

  group('repo.orders_test_no_src_imports', () {
    test('passes on current orders test tree', () {
      expect(runCheckOrdersTestNoSrcImports(repoRoot), 0);
    });

    test('flags cross-package src import in orders tests', () {
      final violations = <String>[];
      final reason = ordersTestNoSrcImportsViolationReason(
        'packages/colonizethis_orders/test/orders/example_test.dart',
        "import 'package:colonizethis_logic/src/constants.dart';",
      );
      expect(reason, isNotNull);
      violations.add('example: $reason');
      expect(violations, isNotEmpty);
    });

    test('allows self orders src imports', () {
      final reason = ordersTestNoSrcImportsViolationReason(
        'packages/colonizethis_orders/test/orders/example_test.dart',
        "import 'package:colonizethis_orders/src/orders/order_engine.dart';",
      );
      expect(reason, isNull);
    });
  });
}
