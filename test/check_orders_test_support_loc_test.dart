import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_orders_test_support_loc.dart';

void main() {
  group('countOrdersTestSupportPhysicalLoc', () {
    test('sums dart physical lines under support/', () {
      final temp = Directory.systemTemp.createTempSync('orders-support-loc-');
      try {
        final support = Directory(p.join(temp.path, 'support'))
          ..createSync(recursive: true);
        File(p.join(support.path, 'a.dart')).writeAsStringSync('a\nb\n');
        final nested = Directory(p.join(support.path, 'nested'))
          ..createSync(recursive: true);
        File(p.join(nested.path, 'b.dart')).writeAsStringSync('x\ny\nz\n');
        File(p.join(support.path, 'skip.txt')).writeAsStringSync('ignored\n');

        expect(countOrdersTestSupportPhysicalLoc(support), 5);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });

  group('runCheckOrdersTestSupportLoc', () {
    test('passes on current repo tree under ratchet ceilings', () {
      expect(runCheckOrdersTestSupportLoc('.'), 0);
    });

    test('fails when measured support LOC exceeds ceiling', () {
      final temp = Directory.systemTemp.createTempSync('orders-support-loc-');
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
        File(
          p.join(support.path, 'fat.dart'),
        ).writeAsStringSync(List.generate(20, (i) => 'line$i').join('\n'));

        final errors = <String>[];
        final code = runCheckOrdersTestSupportLoc(
          temp.path,
          ceiling: 5,
          checkPackage: false,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('exceeds ceiling'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when measured package test LOC exceeds ceiling', () {
      final temp = Directory.systemTemp.createTempSync('orders-test-loc-');
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
        File(p.join(support.path, 'ok.dart')).writeAsStringSync('a\n');

        final packageTest = Directory(
          p.join(temp.path, 'packages', 'colonizethis_orders', 'test'),
        );
        File(
          p.join(packageTest.path, 'fat.dart'),
        ).writeAsStringSync(List.generate(30, (i) => 'line$i').join('\n'));

        final errors = <String>[];
        final code = runCheckOrdersTestSupportLoc(
          temp.path,
          ceiling: 100,
          packageCeiling: 5,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('package test/ LOC'));
        expect(errors.join('\n'), contains('exceeds'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}
