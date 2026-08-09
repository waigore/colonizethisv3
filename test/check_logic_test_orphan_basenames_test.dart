import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_logic_test_orphan_basenames.dart';

void main() {
  group('runCheckLogicTestOrphanBasenames', () {
    test('passes on current repo tree', () {
      expect(runCheckLogicTestOrphanBasenames('.'), 0);
    });

    test('fails when a forbidden collision basename is reintroduced', () {
      final temp =
          Directory.systemTemp.createTempSync('logic-test-orphan-base-');
      try {
        final testDir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_logic', 'test'),
        )..createSync(recursive: true);
        File(
          p.join(testDir.path, 'economy_production_test.dart'),
        ).writeAsStringSync('void main() {}\n');

        final errors = <String>[];
        final code = runCheckLogicTestOrphanBasenames(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('economy_production_test.dart'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}
