import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_orders_test_support_raw_game.dart';

void main() {
  group('countOrdersTestSupportRawGameConstructions', () {
    test('counts return/=> Game( outside common/', () {
      final temp = Directory.systemTemp.createTempSync('orders-raw-game-');
      try {
        final support = Directory(p.join(temp.path, 'support'))
          ..createSync(recursive: true);
        Directory(p.join(support.path, 'common')).createSync();
        File(p.join(support.path, 'common', 'graphs.dart')).writeAsStringSync(
          'Game ok() => Game(id: "c");\n',
        );
        File(p.join(support.path, 'family.dart')).writeAsStringSync(
          'Game a() => Game(id: "a");\nGame b() {\n  return Game(id: "b");\n}\n',
        );
        expect(countOrdersTestSupportRawGameConstructions(support), 2);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });

  group('runCheckOrdersTestSupportRawGame', () {
    test('passes on current repo tree under ratchet ceiling', () {
      expect(runCheckOrdersTestSupportRawGame('.'), 0);
    });

    test('fails when measured count exceeds ceiling', () {
      final temp = Directory.systemTemp.createTempSync('orders-raw-game-');
      try {
        final support = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_orders',
            'test',
            'orders',
            'support',
          ),
        )..createSync(recursive: true);
        File(p.join(support.path, 'fat.dart')).writeAsStringSync(
          'Game a() => Game(id: "a");\nGame b() => Game(id: "b");\n',
        );

        final errors = <String>[];
        final code = runCheckOrdersTestSupportRawGame(
          temp.path,
          ceiling: 1,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('exceeds'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}
