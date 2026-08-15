import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_economy_test_support_no_expectations_modules.dart';

void main() {
  group('runCheckEconomyTestSupportNoExpectationsModules', () {
    test('passes on current repo tree', () {
      expect(runCheckEconomyTestSupportNoExpectationsModules('.'), 0);
    });

    test('fails when a planted *_expectations.dart module exists', () {
      final temp = Directory.systemTemp.createTempSync(
        'economy-support-no-expectations-',
      );
      try {
        final libDir = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_economy_test_support',
            'lib',
            'src',
          ),
        )..createSync(recursive: true);
        File(
          p.join(libDir.path, 'foo_expectations.dart'),
        ).writeAsStringSync('class FooExpectation {}\n');

        final errors = <String>[];
        final code = runCheckEconomyTestSupportNoExpectationsModules(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('foo_expectations.dart'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}
