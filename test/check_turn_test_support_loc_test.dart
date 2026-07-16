import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_turn_test_support_loc.dart';

void main() {
  group('countTurnTestSupportPhysicalLoc', () {
    test('sums dart physical lines under support/', () {
      final temp = Directory.systemTemp.createTempSync('turn-support-loc-');
      try {
        final support = Directory(p.join(temp.path, 'support'))
          ..createSync(recursive: true);
        File(p.join(support.path, 'a.dart')).writeAsStringSync('a\nb\n');
        final nested = Directory(p.join(support.path, 'nested'))
          ..createSync(recursive: true);
        File(p.join(nested.path, 'b.dart')).writeAsStringSync('x\ny\nz\n');
        File(p.join(support.path, 'skip.txt')).writeAsStringSync('ignored\n');

        expect(countTurnTestSupportPhysicalLoc(support), 5);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });

  group('runCheckTurnTestSupportLoc', () {
    test('passes on current repo tree under ratchet ceiling', () {
      expect(runCheckTurnTestSupportLoc('.'), 0);
    });

    test('fails when measured support LOC exceeds ceiling', () {
      final temp = Directory.systemTemp.createTempSync('turn-support-loc-');
      try {
        final support = Directory(
          p.join(temp.path, 'packages', 'colonizethis_turn', 'test', 'support'),
        )..createSync(recursive: true);
        File(
          p.join(support.path, 'fat.dart'),
        ).writeAsStringSync(List.generate(20, (i) => 'line$i').join('\n'));

        final errors = <String>[];
        final code = runCheckTurnTestSupportLoc(
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
