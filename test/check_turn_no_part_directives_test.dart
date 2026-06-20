import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_turn_no_part_directives.dart';

void main() {
  group('runCheckTurnNoPartDirectives', () {
    test('fails for a `part` parent directive in turn lib', () {
      final temp = Directory.systemTemp.createTempSync('turn-no-part-parent-');
      try {
        final turnLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_turn', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(turnLib.path, 'parent.dart'),
          "// header\npart 'child.dart';\nvoid x() {}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckTurnNoPartDirectives(
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

    test('fails for a `part of` fragment directive in turn lib', () {
      final temp = Directory.systemTemp.createTempSync('turn-no-part-frag-');
      try {
        final turnLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_turn', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(turnLib.path, 'child.dart'),
          "part of 'parent.dart';\nvoid x() {}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckTurnNoPartDirectives(
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

    test('passes for a turn lib library file with explicit imports', () {
      final temp = Directory.systemTemp.createTempSync('turn-no-part-ok-');
      try {
        final turnLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_turn', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(turnLib.path, 'lib_file.dart'),
          "import 'helpers.dart';\n\nfinal participants = <String>[];\nvoid x() {}\n",
        );

        final exitCode = runCheckTurnNoPartDirectives(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('ignores `part of` outside the turn package lib', () {
      final temp = Directory.systemTemp.createTempSync('turn-no-part-other-');
      try {
        final otherLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_map', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(otherLib.path, 'child.dart'),
          "part of 'parent.dart';\nvoid x() {}\n",
        );

        final exitCode = runCheckTurnNoPartDirectives(
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

  group('turnNoPartDirectivesLineIsPartDirective', () {
    test('matches part and part of directive forms', () {
      expect(turnNoPartDirectivesLineIsPartDirective("part 'a.dart';"), isTrue);
      expect(
        turnNoPartDirectivesLineIsPartDirective("part of 'a.dart';"),
        isTrue,
      );
      expect(
        turnNoPartDirectivesLineIsPartDirective('part of "a.dart";'),
        isTrue,
      );
    });

    test('does not match identifiers that start with part', () {
      expect(
        turnNoPartDirectivesLineIsPartDirective('participants.add(x);'),
        isFalse,
      );
      expect(
        turnNoPartDirectivesLineIsPartDirective('final partition = 1;'),
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
