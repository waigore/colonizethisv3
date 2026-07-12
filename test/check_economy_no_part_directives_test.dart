import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_economy_no_part_directives.dart';

void main() {
  group('runCheckEconomyNoPartDirectives', () {
    test('fails for a `part` parent directive in economy lib', () {
      final temp = Directory.systemTemp.createTempSync(
        'economy-no-part-parent-',
      );
      try {
        final economyLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_economy', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(economyLib.path, 'parent.dart'),
          "// header\npart 'child.dart';\nvoid x() {}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckEconomyNoPartDirectives(
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

    test('fails for a `part of` fragment directive in economy lib', () {
      final temp = Directory.systemTemp.createTempSync('economy-no-part-frag-');
      try {
        final economyLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_economy', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(economyLib.path, 'child.dart'),
          "part of 'parent.dart';\nvoid x() {}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckEconomyNoPartDirectives(
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

    test('passes for an economy lib library file with explicit imports', () {
      final temp = Directory.systemTemp.createTempSync('economy-no-part-ok-');
      try {
        final economyLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_economy', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(economyLib.path, 'lib_file.dart'),
          "import 'helpers.dart';\n\nfinal participants = <String>[];\nvoid x() {}\n",
        );

        final exitCode = runCheckEconomyNoPartDirectives(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('ignores `part of` outside the economy package lib', () {
      final temp = Directory.systemTemp.createTempSync(
        'economy-no-part-other-',
      );
      try {
        final otherLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_map', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(otherLib.path, 'child.dart'),
          "part of 'parent.dart';\nvoid x() {}\n",
        );

        final exitCode = runCheckEconomyNoPartDirectives(
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

  group('economyNoPartDirectivesLineIsPartDirective', () {
    test('matches part and part of directive forms', () {
      expect(
        economyNoPartDirectivesLineIsPartDirective("part 'a.dart';"),
        isTrue,
      );
      expect(
        economyNoPartDirectivesLineIsPartDirective("part of 'a.dart';"),
        isTrue,
      );
      expect(
        economyNoPartDirectivesLineIsPartDirective('part of "a.dart";'),
        isTrue,
      );
    });

    test('does not match identifiers that start with part', () {
      expect(
        economyNoPartDirectivesLineIsPartDirective('participants.add(x);'),
        isFalse,
      );
      expect(
        economyNoPartDirectivesLineIsPartDirective('final partition = 1;'),
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
