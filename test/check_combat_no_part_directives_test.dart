import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_combat_no_part_directives.dart';

void main() {
  group('runCheckCombatNoPartDirectives', () {
    test('fails for a `part` parent directive in combat lib', () {
      final temp = Directory.systemTemp.createTempSync(
        'combat-no-part-parent-',
      );
      try {
        final combatLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_combat', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(combatLib.path, 'parent.dart'),
          "// header\npart 'child.dart';\nvoid x() {}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckCombatNoPartDirectives(
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

    test('fails for a `part of` fragment directive in combat lib', () {
      final temp = Directory.systemTemp.createTempSync('combat-no-part-frag-');
      try {
        final combatLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_combat', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(combatLib.path, 'child.dart'),
          "part of 'parent.dart';\nvoid x() {}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckCombatNoPartDirectives(
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

    test('passes for a combat lib library file with explicit imports', () {
      final temp = Directory.systemTemp.createTempSync('combat-no-part-ok-');
      try {
        final combatLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_combat', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(combatLib.path, 'lib_file.dart'),
          "import 'helpers.dart';\n\nfinal participants = <String>[];\nvoid x() {}\n",
        );

        final exitCode = runCheckCombatNoPartDirectives(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('ignores `part of` outside the combat package lib', () {
      final temp = Directory.systemTemp.createTempSync('combat-no-part-other-');
      try {
        final otherLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_map', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(otherLib.path, 'child.dart'),
          "part of 'parent.dart';\nvoid x() {}\n",
        );

        final exitCode = runCheckCombatNoPartDirectives(
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

  group('combatNoPartDirectivesLineIsPartDirective', () {
    test('matches part and part of directive forms', () {
      expect(
        combatNoPartDirectivesLineIsPartDirective("part 'a.dart';"),
        isTrue,
      );
      expect(
        combatNoPartDirectivesLineIsPartDirective("part of 'a.dart';"),
        isTrue,
      );
      expect(
        combatNoPartDirectivesLineIsPartDirective('part of "a.dart";'),
        isTrue,
      );
    });

    test('does not match identifiers that start with part', () {
      expect(
        combatNoPartDirectivesLineIsPartDirective('participants.add(x);'),
        isFalse,
      );
      expect(
        combatNoPartDirectivesLineIsPartDirective('final partition = 1;'),
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
