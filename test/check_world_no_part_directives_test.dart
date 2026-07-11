import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_world_no_part_directives.dart';

void main() {
  group('runCheckWorldNoPartDirectives', () {
    test('fails for a `part` parent directive in world lib', () {
      final temp = Directory.systemTemp.createTempSync(
        'world-no-part-parent-',
      );
      try {
        final worldLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_world', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(worldLib.path, 'parent.dart'),
          "// header\npart 'child.dart';\nvoid x() {}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckWorldNoPartDirectives(
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

    test('fails for a `part of` fragment directive in world lib', () {
      final temp = Directory.systemTemp.createTempSync('world-no-part-frag-');
      try {
        final worldLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_world', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(worldLib.path, 'child.dart'),
          "part of 'parent.dart';\nvoid x() {}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckWorldNoPartDirectives(
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

    test('passes for a world lib library file with explicit imports', () {
      final temp = Directory.systemTemp.createTempSync('world-no-part-ok-');
      try {
        final worldLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_world', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(worldLib.path, 'lib_file.dart'),
          "import 'helpers.dart';\n\nfinal participants = <String>[];\nvoid x() {}\n",
        );

        final exitCode = runCheckWorldNoPartDirectives(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('ignores `part of` outside the world package lib', () {
      final temp = Directory.systemTemp.createTempSync('world-no-part-other-');
      try {
        final otherLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_map', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(otherLib.path, 'child.dart'),
          "part of 'parent.dart';\nvoid x() {}\n",
        );

        final exitCode = runCheckWorldNoPartDirectives(
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

  group('worldNoPartDirectivesLineIsPartDirective', () {
    test('matches part and part of directive forms', () {
      expect(
        worldNoPartDirectivesLineIsPartDirective("part 'a.dart';"),
        isTrue,
      );
      expect(
        worldNoPartDirectivesLineIsPartDirective("part of 'a.dart';"),
        isTrue,
      );
      expect(
        worldNoPartDirectivesLineIsPartDirective('part of "a.dart";'),
        isTrue,
      );
    });

    test('does not match identifiers that start with part', () {
      expect(
        worldNoPartDirectivesLineIsPartDirective('participants.add(x);'),
        isFalse,
      );
      expect(
        worldNoPartDirectivesLineIsPartDirective('final partition = 1;'),
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
