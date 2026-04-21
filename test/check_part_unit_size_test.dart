import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_part_unit_size.dart';

void main() {
  group('runCheckPartUnitSize', () {
    test('fails when allowlisted part file grows above max', () {
      final temp = Directory.systemTemp.createTempSync('part-size-allow-fail-');
      try {
        final logicDir = Directory(
          p.join(temp.path, 'packages', 'colonizethis_logic', 'lib', 'src'),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(logicDir.path, 'huge_part.dart'),
          _functionWithStatements(230),
        );
        final toolDir = Directory(p.join(temp.path, 'tool'))
          ..createSync(recursive: true);
        File(
          p.join(toolDir.path, 'part_unit_size_allowlist.yaml'),
        ).writeAsStringSync('''
allowed_part_files:
  - file: packages/colonizethis_logic/lib/src/huge_part.dart
    max_lines: 100
''');

        final errors = <String>[];
        final exitCode = runCheckPartUnitSize(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('huge_part.dart'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('fails when allowlisted parent + part total exceeds max', () {
      final temp = Directory.systemTemp.createTempSync('part-parent-fail-');
      try {
        final setupDir = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_logic',
            'lib',
            'src',
            'setup',
          ),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(setupDir.path, 'game_setup.dart'),
          '''
part 'game_setup_helpers.dart';
${_functionWithStatements(260)}
''',
        );
        _writeDartFile(
          p.join(setupDir.path, 'game_setup_helpers.dart'),
          _functionWithStatements(270),
        );
        final toolDir = Directory(p.join(temp.path, 'tool'))
          ..createSync(recursive: true);
        File(
          p.join(toolDir.path, 'part_unit_size_allowlist.yaml'),
        ).writeAsStringSync('''
allowed_parent_units:
  - file: packages/colonizethis_logic/lib/src/setup/game_setup.dart
    max_lines: 200
''');

        final errors = <String>[];
        final exitCode = runCheckPartUnitSize(
          temp.path,
          info: (_) {},
          err: errors.add,
        );
        expect(exitCode, 1);
        expect(errors.join('\n'), contains('game_setup.dart'));
      } finally {
        temp.deleteSync(recursive: true);
      }
    });

    test('passes when allowlisted maxima are respected', () {
      final temp = Directory.systemTemp.createTempSync('part-allow-pass-');
      try {
        final setupDir = Directory(
          p.join(
            temp.path,
            'packages',
            'colonizethis_logic',
            'lib',
            'src',
            'setup',
          ),
        )..createSync(recursive: true);
        _writeDartFile(
          p.join(setupDir.path, 'game_setup.dart'),
          '''
part 'game_setup_helpers.dart';
${_functionWithStatements(260)}
''',
        );
        _writeDartFile(
          p.join(setupDir.path, 'game_setup_helpers.dart'),
          _functionWithStatements(270),
        );

        final toolDir = Directory(p.join(temp.path, 'tool'))
          ..createSync(recursive: true);
        File(
          p.join(toolDir.path, 'part_unit_size_allowlist.yaml'),
        ).writeAsStringSync('''
allowed_parent_units:
  - file: packages/colonizethis_logic/lib/src/setup/game_setup.dart
    max_lines: 600
allowed_part_files:
  - file: packages/colonizethis_logic/lib/src/setup/game_setup_helpers.dart
    max_lines: 300
''');

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
