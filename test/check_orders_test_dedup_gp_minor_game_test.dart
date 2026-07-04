import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_orders_test_dedup_gp_minor_game.dart';

void main() {
  group('ordersTestDedupGpMinorGameViolationReason', () {
    test('allows builders in the canonical fixture module', () {
      expect(
        ordersTestDedupGpMinorGameViolationReason(
          ordersGpMinorFixtureModule,
          'Game gpMinorGame() => TestFixtures.minimalGame();',
        ),
        isNull,
      );
    });

    test('flags duplicate GP–Minor builders in other orders tests', () {
      expect(
        ordersTestDedupGpMinorGameViolationReason(
          'packages/colonizethis_orders/test/orders/foo_test.dart',
          'Game gpMinorBaseGame({int treasury = 0}) => gpMinorGame(treasury: treasury);',
        ),
        isNotNull,
      );
    });

    test('ignores calls to shared GP–Minor builders', () {
      expect(
        ordersTestDedupGpMinorGameViolationReason(
          'packages/colonizethis_orders/test/orders/foo_test.dart',
          'void main() { gpMinorBaseGame(treasury: 10); }',
        ),
        isNull,
      );
    });
  });

  group('runCheckOrdersTestDedupGpMinorGame', () {
    test('passes on current repo tree', () {
      expect(runCheckOrdersTestDedupGpMinorGame('.'), 0);
    });

    test('fails when a duplicate builder is added outside the fixture module',
        () {
      final temp = Directory.systemTemp.createTempSync('orders-gp-minor-dedup-');
      try {
        final ordersTest = Directory(
          p.join(temp.path, 'packages', 'colonizethis_orders', 'test', 'orders'),
        )..createSync(recursive: true);
        File(
          p.join(ordersTest.path, 'local_gp_minor_test.dart'),
        ).writeAsStringSync(
          "Game gpMinorGame() => throw UnimplementedError();\n",
        );

        final errors = <String>[];
        final exitCode = runCheckOrdersTestDedupGpMinorGame(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('local_gp_minor_test.dart'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}
