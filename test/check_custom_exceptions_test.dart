import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_custom_exceptions.dart';

void main() {
  group('runCheckCustomExceptions', () {
    test('fails when package lib contains throw Exception()', () {
      final temp = Directory.systemTemp.createTempSync('custom-ex-');
      try {
        final libDir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_logic', 'lib', 'src'),
        )..createSync(recursive: true);
        File(p.join(libDir.path, 'bad.dart')).writeAsStringSync(r'''
void f() {
  throw Exception('nope');
}
''');

        final errors = <String>[];
        final exitCode = runCheckCustomExceptions(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('bad.dart'));
        expect(errors.join('\n'), contains('Exception'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test(
      'fails on violation; legacy keyed waiver YAML under tool/ is not read',
      () {
        final temp = Directory.systemTemp.createTempSync('custom-ex-legacy-');
        try {
          final libDir = Directory(
            p.join(temp.path, 'packages', 'colonizethis_logic', 'lib', 'src'),
          )..createSync(recursive: true);
          File(p.join(libDir.path, 'bad.dart')).writeAsStringSync(r'''
void f() {
  throw Exception('nope');
}
''');
          final toolDir = Directory(p.join(temp.path, 'tool'))
            ..createSync(recursive: true);
          File(
            p.join(toolDir.path, 'legacy_custom_exception_waiver_table.yaml'),
          ).writeAsStringSync('''
# Decoy: historical repo-lint keyed waiver shape; checker must not load this.
exempt_files:
  - packages/colonizethis_logic/lib/src/bad.dart
''');

          final errors = <String>[];
          final exitCode = runCheckCustomExceptions(
            temp.path,
            info: (_) {},
            err: errors.add,
          );
          expect(exitCode, 1);
          expect(errors.join('\n'), contains('bad.dart'));
          expect(errors.join('\n'), contains('Exception'));
        } finally {
          temp.deleteSync(recursive: true);
        }
      },
    );
  });
}
