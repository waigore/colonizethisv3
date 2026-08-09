import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_ai_no_part_directives.dart';

void main() {
  group('runCheckAiNoPartDirectives', () {
    test('fails for a `part` parent directive in ai lib', () {
      final temp = Directory.systemTemp.createTempSync('ai-no-part-parent-');
      try {
        final aiLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_ai', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(aiLib.path, 'parent.dart'),
          "// header\npart 'child.dart';\nvoid x() {}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckAiNoPartDirectives(
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

    test('fails for a `part of` fragment directive in ai lib', () {
      final temp = Directory.systemTemp.createTempSync('ai-no-part-frag-');
      try {
        final aiLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_ai', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(aiLib.path, 'child.dart'),
          "part of 'parent.dart';\nvoid x() {}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckAiNoPartDirectives(
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

    test('passes for an ai lib library file with explicit imports', () {
      final temp = Directory.systemTemp.createTempSync('ai-no-part-ok-');
      try {
        final aiLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_ai', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(aiLib.path, 'lib_file.dart'),
          "import 'helpers.dart';\n\nfinal participants = <String>[];\nvoid x() {}\n",
        );

        final exitCode = runCheckAiNoPartDirectives(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('ignores `part of` outside the ai package lib', () {
      final temp = Directory.systemTemp.createTempSync('ai-no-part-other-');
      try {
        final otherLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_map', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(otherLib.path, 'child.dart'),
          "part of 'parent.dart';\nvoid x() {}\n",
        );

        final exitCode = runCheckAiNoPartDirectives(
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

  group('runCheckAiContractsNoPartDirectives', () {
    test('fails for a `part` parent directive in ai_contracts lib', () {
      final temp =
          Directory.systemTemp.createTempSync('ai-contracts-no-part-parent-');
      try {
        final lib = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_ai_contracts',
            'lib',
            'src',
          ),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(lib.path, 'parent.dart'),
          "// header\npart 'child.dart';\nvoid x() {}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckAiContractsNoPartDirectives(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('parent.dart:2'));
        expect(errors.join('\n'), contains('#4084'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails for a `part of` fragment in ai_contracts lib', () {
      final temp =
          Directory.systemTemp.createTempSync('ai-contracts-no-part-frag-');
      try {
        final lib = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_ai_contracts',
            'lib',
            'src',
          ),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(lib.path, 'child.dart'),
          "part of 'parent.dart';\nvoid x() {}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckAiContractsNoPartDirectives(
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

    test('passes for a clean ai_contracts lib tree', () {
      final temp =
          Directory.systemTemp.createTempSync('ai-contracts-no-part-ok-');
      try {
        final lib = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_ai_contracts',
            'lib',
            'src',
          ),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(lib.path, 'lib_file.dart'),
          "import 'helpers.dart';\n\nvoid x() {}\n",
        );

        final exitCode = runCheckAiContractsNoPartDirectives(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('ignores `part of` under colonizethis_ai when scanning contracts', () {
      final temp =
          Directory.systemTemp.createTempSync('ai-contracts-no-part-other-');
      try {
        final aiLib = Directory(
          p.join(temp.path, 'packages', 'colonizethis_ai', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(aiLib.path, 'child.dart'),
          "part of 'parent.dart';\nvoid x() {}\n",
        );

        final exitCode = runCheckAiContractsNoPartDirectives(
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

  group('aiNoPartDirectivesLineIsPartDirective', () {
    test('matches part and part of directive forms', () {
      expect(
        aiNoPartDirectivesLineIsPartDirective("part 'a.dart';"),
        isTrue,
      );
      expect(
        aiNoPartDirectivesLineIsPartDirective("part of 'a.dart';"),
        isTrue,
      );
      expect(
        aiNoPartDirectivesLineIsPartDirective('part of "a.dart";'),
        isTrue,
      );
    });

    test('does not match identifiers that start with part', () {
      expect(
        aiNoPartDirectivesLineIsPartDirective('participants.add(x);'),
        isFalse,
      );
      expect(
        aiNoPartDirectivesLineIsPartDirective('final partition = 1;'),
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
