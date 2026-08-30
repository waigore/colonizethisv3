import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_no_part_directives.dart';

void main() {
  group('runCheckAppE2eSupportNoPartDirectives', () {
    test('fails for a `part` parent directive in e2e_support lib', () {
      final temp =
          Directory.systemTemp.createTempSync('e2e-support-no-part-lib-');
      try {
        final lib = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_app_e2e_support',
            'lib',
          ),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(lib.path, 'parent.dart'),
          "// header\npart 'child.dart';\nvoid x() {}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckAppE2eSupportNoPartDirectives(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('parent.dart:2'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails for a `part of` fragment directive in e2e_support test', () {
      final temp =
          Directory.systemTemp.createTempSync('e2e-support-no-part-test-');
      try {
        final testDir = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_app_e2e_support',
            'test',
          ),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(testDir.path, 'child_test.dart'),
          "part of 'parent_test.dart';\nvoid x() {}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckAppE2eSupportNoPartDirectives(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('child_test.dart:1'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes for an e2e_support library with explicit imports', () {
      final temp =
          Directory.systemTemp.createTempSync('e2e-support-no-part-ok-');
      try {
        final lib = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_app_e2e_support',
            'lib',
          ),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(lib.path, 'lib_file.dart'),
          "import 'helpers.dart';\n\nfinal participants = <String>[];\nvoid x() {}\n",
        );

        final exitCode = runCheckAppE2eSupportNoPartDirectives(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes for the real e2e_support package tree', () {
      final logs = <String>[];
      final code = runCheckAppE2eSupportNoPartDirectives(
        Directory.current.path,
        info: logs.add,
        err: logs.add,
      );
      expect(
        code,
        0,
        reason:
            'packages/colonizethis_app_e2e_support must have zero part '
            'directives under lib/ and test/.\n${logs.join('\n')}',
      );
    });

    test('ignores `part of` outside the e2e_support package', () {
      final temp =
          Directory.systemTemp.createTempSync('e2e-support-no-part-other-');
      try {
        final otherLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_map', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(otherLib.path, 'child.dart'),
          "part of 'parent.dart';\nvoid x() {}\n",
        );

        final exitCode = runCheckAppE2eSupportNoPartDirectives(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });
}

void _writeDartFile(String path, String contents) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(contents);
}
