import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_colonizethis_setup_test_support_loc.dart';

void main() {
  group('countSetupTestSupportPhysicalLoc', () {
    test('sums dart physical lines under support/', () {
      final temp = Directory.systemTemp.createTempSync('setup-support-loc-');
      try {
        final support = Directory(p.join(temp.path, 'support'))
          ..createSync(recursive: true);
        File(p.join(support.path, 'a.dart')).writeAsStringSync('a\nb\n');
        final nested = Directory(p.join(support.path, 'nested'))
          ..createSync(recursive: true);
        File(p.join(nested.path, 'b.dart')).writeAsStringSync('x\ny\nz\n');
        File(p.join(support.path, 'skip.txt')).writeAsStringSync('ignored\n');

        expect(countSetupTestSupportPhysicalLoc(support), 5);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });

  group('runCheckColonizethisSetupTestSupportLoc', () {
    test('passes on current repo tree under ratchet ceiling', () {
      expect(runCheckColonizethisSetupTestSupportLoc('.'), 0);
    });

    test('fails when a support file meets the per-file line ceiling', () {
      final temp = Directory.systemTemp.createTempSync('setup-support-loc-');
      try {
        final support = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_setup',
            'test',
            'setup',
            'support',
          ),
        )..createSync(recursive: true);
        File(
          p.join(support.path, 'fat.dart'),
        ).writeAsStringSync(List.generate(380, (i) => 'line$i').join('\n'));

        final errors = <String>[];
        final code = runCheckColonizethisSetupTestSupportLoc(
          temp.path,
          ceiling: 10000,
          fileCeiling: 380,
          info: (_) {},
          err: errors.add,
        );
        expect(code, 1);
        expect(errors.join('\n'), contains('physical lines'));
        expect(errors.join('\n'), contains('fat.dart'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when measured support LOC exceeds ceiling', () {
      final temp = Directory.systemTemp.createTempSync('setup-support-loc-');
      try {
        final support = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_setup',
            'test',
            'setup',
            'support',
          ),
        )..createSync(recursive: true);
        File(
          p.join(support.path, 'fat.dart'),
        ).writeAsStringSync(List.generate(20, (i) => 'line$i').join('\n'));

        final errors = <String>[];
        final code = runCheckColonizethisSetupTestSupportLoc(
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
