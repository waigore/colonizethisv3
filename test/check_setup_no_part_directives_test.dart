import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_setup_no_part_directives.dart';

void main() {
  group('runCheckSetupNoPartDirectives', () {
    test('fails for a `part` parent directive in setup lib', () {
      final temp = Directory.systemTemp.createTempSync(
        'setup-no-part-parent-',
      );
      try {
        final setupLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_setup', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(setupLib.path, 'parent.dart'),
          "// header\npart 'child.dart';\nvoid x() {}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckSetupNoPartDirectives(
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

    test('fails for a `part of` fragment directive in setup lib', () {
      final temp = Directory.systemTemp.createTempSync('setup-no-part-frag-');
      try {
        final setupLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_setup', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(setupLib.path, 'child.dart'),
          "part of 'parent.dart';\nvoid x() {}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckSetupNoPartDirectives(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('child.dart:1'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes for a setup lib library file with explicit imports', () {
      final temp = Directory.systemTemp.createTempSync('setup-no-part-ok-');
      try {
        final setupLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_setup', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(setupLib.path, 'lib_file.dart'),
          "import 'helpers.dart';\n\nfinal participants = <String>[];\nvoid x() {}\n",
        );

        final exitCode = runCheckSetupNoPartDirectives(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('ignores `part of` outside the setup package lib', () {
      final temp = Directory.systemTemp.createTempSync('setup-no-part-other-');
      try {
        final otherLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_map', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(otherLib.path, 'child.dart'),
          "part of 'parent.dart';\nvoid x() {}\n",
        );

        final exitCode = runCheckSetupNoPartDirectives(
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

  group('setupNoPartDirectivesLineIsPartDirective', () {
    test('matches part and part of directive forms', () {
      expect(
        setupNoPartDirectivesLineIsPartDirective("part 'a.dart';"),
        isTrue,
      );
      expect(
        setupNoPartDirectivesLineIsPartDirective("part of 'a.dart';"),
        isTrue,
      );
      expect(
        setupNoPartDirectivesLineIsPartDirective('part of "a.dart";'),
        isTrue,
      );
    });

    test('does not match identifiers that start with part', () {
      expect(
        setupNoPartDirectivesLineIsPartDirective('participants.add(x);'),
        isFalse,
      );
      expect(
        setupNoPartDirectivesLineIsPartDirective('final partition = 1;'),
        isFalse,
      );
    });
  });
}

void _writeDartFile(String path, String content) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(content);
}
