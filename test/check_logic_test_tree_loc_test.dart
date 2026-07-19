import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_logic_test_tree_loc.dart';

void main() {
  group('countLogicTestTreePhysicalLoc', () {
    test('sums dart physical lines under test/', () {
      final temp = Directory.systemTemp.createTempSync('logic-test-tree-loc-');
      try {
        final support = Directory(p.join(temp.path, 'test'))
          ..createSync(recursive: true);
        File(p.join(support.path, 'a.dart')).writeAsStringSync('a\nb\n');
        final nested = Directory(p.join(support.path, 'nested'))
          ..createSync(recursive: true);
        File(p.join(nested.path, 'b.dart')).writeAsStringSync('x\ny\nz\n');
        File(p.join(support.path, 'skip.txt')).writeAsStringSync('ignored\n');

        expect(countLogicTestTreePhysicalLoc(support), 5);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });

  group('runCheckLogicTestTreeLoc', () {
    test('passes on current repo tree under ratchet ceiling', () {
      expect(runCheckLogicTestTreeLoc('.'), 0);
    });

    test('fails when measured test tree LOC exceeds ceiling', () {
      final temp = Directory.systemTemp.createTempSync('logic-test-tree-loc-');
      try {
        final testDir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_logic', 'test'),
        )..createSync(recursive: true);
        File(
          p.join(testDir.path, 'fat.dart'),
        ).writeAsStringSync(List.generate(20, (i) => 'line$i').join('\n'));

        final errors = <String>[];
        final code = runCheckLogicTestTreeLoc(
          temp.path,
          ceiling: 5,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('exceeds ceiling'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}
