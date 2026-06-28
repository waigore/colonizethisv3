import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_orders_test_no_duplicate_fixtures.dart';

void main() {
  group('runCheckOrdersTestNoDuplicateFixtures', () {
    test('fails when a local test_fixtures.dart is re-added under orders test',
        () {
      final temp = Directory.systemTemp.createTempSync('orders-dup-fixtures-');
      try {
        final ordersTest = Directory(
          p.join(temp.path, 'packages', 'colonizethis_orders', 'test'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(ordersTest.path, 'test_fixtures.dart'),
          "import 'package:colonizethis_models/colonizethis_models.dart';\n"
          'abstract final class TestFixtures {\n  TestFixtures._();\n}\n',
        );

        final errors = <String>[];
        final exitCode = runCheckOrdersTestNoDuplicateFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('test_fixtures.dart'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when an orders test redeclares a TestFixtures class', () {
      final temp = Directory.systemTemp.createTempSync('orders-dup-class-');
      try {
        final ordersTest = Directory(
          p.join(temp.path, 'packages', 'colonizethis_orders', 'test', 'orders'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(ordersTest.path, 'local_fixtures_test.dart'),
          "import 'package:test/test.dart';\n\n"
          'class TestFixtures {\n  static int x() => 1;\n}\n'
          'void main() {}\n',
        );

        final errors = <String>[];
        final exitCode = runCheckOrdersTestNoDuplicateFixtures(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('redefines a local'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when orders tests import the shared fixtures', () {
      final temp = Directory.systemTemp.createTempSync('orders-dup-ok-');
      try {
        final ordersTest = Directory(
          p.join(temp.path, 'packages', 'colonizethis_orders', 'test', 'orders'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(ordersTest.path, 'uses_shared_test.dart'),
          "import 'package:colonizethis_test/game_test_fixtures.dart';\n"
          "import 'package:test/test.dart';\n\n"
          'void main() {\n  TestFixtures.minimalGame();\n}\n',
        );

        final exitCode = runCheckOrdersTestNoDuplicateFixtures(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('ignores a TestFixtures class outside the orders package test tree',
        () {
      final temp = Directory.systemTemp.createTempSync('orders-dup-other-');
      try {
        final sharedLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_test', 'lib'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(sharedLib.path, 'game_test_fixtures.dart'),
          'abstract final class TestFixtures {\n  TestFixtures._();\n}\n',
        );

        final exitCode = runCheckOrdersTestNoDuplicateFixtures(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });

  group('ordersTestDuplicateFixturesViolationReason', () {
    test('flags the deleted local fixture filename', () {
      expect(
        ordersTestDuplicateFixturesViolationReason('test_fixtures.dart', ''),
        isNotNull,
      );
    });

    test('flags abstract final class TestFixtures declarations', () {
      expect(
        ordersTestDuplicateFixturesViolationReason(
          'foo_test.dart',
          'abstract final class TestFixtures {}',
        ),
        isNotNull,
      );
    });

    test('does not flag references to the shared TestFixtures symbol', () {
      expect(
        ordersTestDuplicateFixturesViolationReason(
          'foo_test.dart',
          "import 'package:colonizethis_test/game_test_fixtures.dart';\n"
          'void main() => TestFixtures.minimalGame();',
        ),
        isNull,
      );
    });
  });

  group('ordersTestNoDuplicateFixturesPathInScope', () {
    test('matches orders package test paths only', () {
      expect(
        ordersTestNoDuplicateFixturesPathInScope(
          'packages/colonizethis_orders/test/foo_test.dart',
        ),
        isTrue,
      );
      expect(
        ordersTestNoDuplicateFixturesPathInScope(
          'packages/colonizethis_orders/lib/src/orders/foo.dart',
        ),
        isFalse,
      );
      expect(
        ordersTestNoDuplicateFixturesPathInScope(
          'packages/colonizethis_logic/test/foo_test.dart',
        ),
        isFalse,
      );
    });
  });
}

void _writeDartFile(String path, String content) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(content);
}
