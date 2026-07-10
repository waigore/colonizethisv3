import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_orders_test_preserved_descriptions.dart';

void main() {
  group('collectOrdersTestDescriptions', () {
    test('collects test and scenario label descriptions', () {
      final descriptions = collectOrdersTestDescriptions(
        sourcesByPath: {
          'packages/colonizethis_orders/test/orders/a_test.dart':
              "void main() {\n  test('alpha pin', () {});\n}\n",
        },
        scenarioSourcesByPath: {
          'packages/colonizethis_orders/test/orders/support/x.dart':
              "final rows = [\n  (label: 'beta pin'),\n];\n",
        },
      );
      expect(descriptions, containsAll(['alpha pin', 'beta pin']));
    });
  });

  group('runCheckOrdersTestPreservedDescriptions', () {
    test('passes on current repo baseline', () {
      expect(runCheckOrdersTestPreservedDescriptions('.'), 0);
    });

    test('fails when a baseline description is dropped', () {
      final temp = Directory.systemTemp.createTempSync('orders-desc-baseline-');
      try {
        final testDir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_orders', 'test'),
        )..createSync(recursive: true);
        File(p.join(testDir.path, 'DESCRIPTION_BASELINE.txt'))
            .writeAsStringSync('kept pin\nmissing pin\n');
        final orders = Directory(p.join(testDir.path, 'orders'))
          ..createSync();
        File(p.join(orders.path, 'sample_test.dart')).writeAsStringSync(
          "void main() {\n  test('kept pin', () {});\n}\n",
        );

        final errors = <String>[];
        final code = runCheckOrdersTestPreservedDescriptions(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('missing pin'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}
