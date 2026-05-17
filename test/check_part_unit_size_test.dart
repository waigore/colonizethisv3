import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_part_unit_size.dart';

void main() {
  group('runCheckPartUnitSize', () {
    test('fails when part fragment exceeds max physical lines', () {
      final temp = Directory.systemTemp.createTempSync('part-size-over-');
      try {
        final logicDir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_logic', 'lib', 'src'),
        )..createSync(recursive: true);
        final body = List.generate(1002, (_) => '  final _ = 0;').join('\n');
        _writeDartFile(
          p.join(logicDir.path, 'huge_part.dart'),
          "part of 'parent.dart';\nvoid _x() {\n$body\n}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckPartUnitSize(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('huge_part.dart'));
        expect(errors.join('\n'), contains('max=1000'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test(
      'fails when part over max; legacy keyed waiver YAML under tool/ is not read',
      () {
        final temp = Directory.systemTemp.createTempSync('part-size-legacy-');
        try {
          final logicDir = Directory(
            p.join(temp.path, 'packages', 'colonizethis_logic', 'lib', 'src'),
          )..createSync(recursive: true);
          final body = List.generate(1002, (_) => '  final _ = 0;').join('\n');
          _writeDartFile(
            p.join(logicDir.path, 'huge_part.dart'),
            "part of 'parent.dart';\nvoid _x() {\n$body\n}\n",
          );
          final toolDir = Directory(p.join(temp.path, 'tool'))
            ..createSync(recursive: true);
          File(
            p.join(toolDir.path, 'legacy_part_unit_waiver_table.yaml'),
          ).writeAsStringSync('''
# Decoy: historical repo-lint keyed waiver shape; checker must not load this.
exempt_files:
  - packages/colonizethis_logic/lib/src/huge_part.dart
  max_physical_lines: 2000
''');

          final errors = <String>[];
          final exitCode = runCheckPartUnitSize(
            temp.path,
            info: (_) {},
            err: errors.add,
          );
          expect(exitCode, 1);
          expect(errors.join('\n'), contains('huge_part.dart'));
          expect(errors.join('\n'), contains('max=1000'));
        } finally {
          temp.deleteSync(recursive: true);
        }
      },
    );

    test('passes when part fragment is within max physical lines', () {
      final temp = Directory.systemTemp.createTempSync('part-size-ok-');
      try {
        final logicDir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_logic', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(logicDir.path, 'small_part.dart'),
          "part of 'parent.dart';\n${_functionWithStatements(20)}\n",
        );

        final exitCode = runCheckPartUnitSize(
          temp.path,
          info: (_) {},
          err: (_) {},
        );
        expect(exitCode, 0);
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails for oversized part fragments outside logic package', () {
      final temp = Directory.systemTemp.createTempSync('part-size-map-over-');
      try {
        final mapDir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_map', 'lib', 'src'),
        )..createSync(recursive: true);
        final body = List.generate(1002, (_) => '  final _ = 0;').join('\n');
        _writeDartFile(
          p.join(mapDir.path, 'huge_part.dart'),
          "part of 'parent.dart';\nvoid _x() {\n$body\n}\n",
        );

        final errors = <String>[];
        final exitCode = runCheckPartUnitSize(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(
          errors.join('\n'),
          contains('colonizethis_map/lib/src/huge_part.dart'),
        );
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('ignores library files that are not part fragments', () {
      final temp = Directory.systemTemp.createTempSync('part-size-lib-');
      try {
        final logicDir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_logic', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(logicDir.path, 'big_lib.dart'),
          _functionWithStatements(1200),
        );

        final exitCode = runCheckPartUnitSize(
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

void _writeDartFile(String path, String content) {
  File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(content);
}

String _functionWithStatements(int statementCount) {
  final lines = <String>['int measured() {'];
  for (var i = 0; i < statementCount; i++) {
    lines.add('  final v$i = $i;');
  }
  lines.add('  return 1;');
  lines.add('}');
  return '${lines.join('\n')}\n';
}
