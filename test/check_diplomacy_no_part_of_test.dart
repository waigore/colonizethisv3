import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_diplomacy_no_part_of.dart';

void main() {
  group('runCheckDiplomacyNoPartOf', () {
    test('fails for a `part` parent directive in diplomacy lib', () {
      final temp = Directory.systemTemp.createTempSync('diplo-no-part-parent-');
      try {
        final diplomacyLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_diplomacy', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(diplomacyLib.path, 'parent.dart'),
          "// header\npart 'child.dart';\nvoid x() {}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckDiplomacyNoPartOf(
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

    test('fails for a `part of` fragment directive in diplomacy lib', () {
      final temp = Directory.systemTemp.createTempSync('diplo-no-part-frag-');
      try {
        final diplomacyLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_diplomacy', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(diplomacyLib.path, 'child.dart'),
          "part of 'parent.dart';\nvoid x() {}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckDiplomacyNoPartOf(
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

    test('passes for a diplomacy lib library file with explicit imports', () {
      final temp = Directory.systemTemp.createTempSync('diplo-no-part-ok-');
      try {
        final diplomacyLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_diplomacy', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(diplomacyLib.path, 'lib_file.dart'),
          "import 'helpers.dart';\n\nfinal participants = <String>[];\nvoid x() {}\n",
        );

        final exitCode = runCheckDiplomacyNoPartOf(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('ignores `part of` outside the diplomacy package lib', () {
      final temp = Directory.systemTemp.createTempSync('diplo-no-part-other-');
      try {
        final otherLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_map', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(otherLib.path, 'child.dart'),
          "part of 'parent.dart';\nvoid x() {}\n",
        );

        final exitCode = runCheckDiplomacyNoPartOf(
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

  group('diplomacyNoPartOfLineIsPartDirective', () {
    test('matches part and part of directive forms', () {
      expect(diplomacyNoPartOfLineIsPartDirective("part 'a.dart';"), isTrue);
      expect(
        diplomacyNoPartOfLineIsPartDirective("part of 'a.dart';"),
        isTrue,
      );
      expect(
        diplomacyNoPartOfLineIsPartDirective('part of "a.dart";'),
        isTrue,
      );
    });

    test('does not match identifiers that start with part', () {
      expect(
        diplomacyNoPartOfLineIsPartDirective('participants.add(x);'),
        isFalse,
      );
      expect(
        diplomacyNoPartOfLineIsPartDirective('final partition = 1;'),
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
