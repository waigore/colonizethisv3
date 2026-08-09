import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_orders_test_shorthand_file_size.dart';

void main() {
  group('runCheckOrdersTestShorthandFileSize', () {
    test('passes on current repo tree under shorthand ceiling', () {
      expect(runCheckOrdersTestShorthandFileSize('.'), 0);
    });

    test('fails when a shorthand file exceeds ceiling', () {
      final temp = Directory.systemTemp.createTempSync('orders-shorthand-size-');
      try {
        final support = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_orders',
            'test',
            'orders',
            'support',
            'engine',
          ),
        )..createSync(recursive: true);
        File(
          p.join(support.path, 'fat_expectation_shorthand.dart'),
        ).writeAsStringSync(List.generate(25, (i) => 'line$i').join('\n'));

        final errors = <String>[];
        final code = runCheckOrdersTestShorthandFileSize(
          temp.path,
          ceiling: 5,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('fat_expectation_shorthand.dart'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}
