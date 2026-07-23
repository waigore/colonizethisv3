import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_data_no_part_directives.dart';

void main() {
  group('runCheckDataNoPartDirectives', () {
    test('fails for a `part` parent directive outside the grandfather', () {
      final temp = Directory.systemTemp.createTempSync('data-no-part-parent-');
      try {
        final dataLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_data', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(dataLib.path, 'parent.dart'),
          "// header\npart 'child.dart';\nvoid x() {}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckDataNoPartDirectives(
          temp.path,
          grandfatheredPaths: const [],
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('parent.dart:2'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes for a grandfathered file with part directives', () {
      final temp = Directory.systemTemp.createTempSync('data-no-part-grand-');
      try {
        final dataLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_data', 'lib', 'src'),
        )..createSync(recursive: true);
        final rel =
            'packages/colonizethis_data/lib/src/grandfathered.dart';
        _writeDartFile(
          p.join(dataLib.path, 'grandfathered.dart'),
          "part of 'parent.dart';\nvoid x() {}\n",
        );

        final exitCode = runCheckDataNoPartDirectives(
          temp.path,
          grandfatheredPaths: [rel],
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when grandfather entry no longer has part directives', () {
      final temp = Directory.systemTemp.createTempSync('data-no-part-stale-');
      try {
        final dataLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_data', 'lib', 'src'),
        )..createSync(recursive: true);
        final rel = 'packages/colonizethis_data/lib/src/clean.dart';
        _writeDartFile(
          p.join(dataLib.path, 'clean.dart'),
          "import 'dart:core';\nvoid x() {}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckDataNoPartDirectives(
          temp.path,
          grandfatheredPaths: [rel],
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('stale grandfather'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes for a data lib library file with explicit imports', () {
      final temp = Directory.systemTemp.createTempSync('data-no-part-ok-');
      try {
        final dataLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_data', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(dataLib.path, 'lib_file.dart'),
          "import 'helpers.dart';\n\nfinal participants = <String>[];\nvoid x() {}\n",
        );

        final exitCode = runCheckDataNoPartDirectives(
          temp.path,
          grandfatheredPaths: const [],
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('ignores `part of` outside the data package lib', () {
      final temp = Directory.systemTemp.createTempSync('data-no-part-other-');
      try {
        final otherLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_map', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(otherLib.path, 'child.dart'),
          "part of 'parent.dart';\nvoid x() {}\n",
        );

        final exitCode = runCheckDataNoPartDirectives(
          temp.path,
          grandfatheredPaths: const [],
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });
  });

  group('dataNoPartDirectivesLineIsPartDirective', () {
    test('matches part and part of directive forms', () {
      expect(
        dataNoPartDirectivesLineIsPartDirective("part 'a.dart';"),
        isTrue,
      );
      expect(
        dataNoPartDirectivesLineIsPartDirective("part of 'a.dart';"),
        isTrue,
      );
      expect(
        dataNoPartDirectivesLineIsPartDirective('part of "a.dart";'),
        isTrue,
      );
    });

    test('does not match identifiers that start with part', () {
      expect(
        dataNoPartDirectivesLineIsPartDirective('participants.add(x);'),
        isFalse,
      );
      expect(
        dataNoPartDirectivesLineIsPartDirective('final partition = 1;'),
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
