import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_game_widgets_file_size.dart';

void main() {
  test('fails when a game widget file exceeds 700 lines', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_game_widgets_file_size_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final violatingFile = File(
      '${temp.path}/app/lib/features/game/widgets/huge_panel.dart',
    )..createSync(recursive: true);
    violatingFile.writeAsStringSync(List.filled(701, '// line').join('\n'));

    final logs = <String>[];
    final code = runCheckGameWidgetsFileSize(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('huge_panel.dart'));
    expect(logs.join('\n'), contains('701 physical lines > 700'));
  });

  test('fails when game widgets directory is missing', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_game_widgets_file_size_no_dir_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final logs = <String>[];
    final code = runCheckGameWidgetsFileSize(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('widgets not found'));
  });

  test('passes when all game widget files are at or below 700 lines', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_game_widgets_file_size_pass_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final okFile = File('${temp.path}/app/lib/features/game/widgets/panel.dart')
      ..createSync(recursive: true);
    okFile.writeAsStringSync(List.filled(700, '// line').join('\n'));

    final code = runCheckGameWidgetsFileSize(temp.path);
    expect(code, 0);
  });

  test(
    'fails on violation; legacy keyed waiver YAML under tool/ is not read',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_game_widgets_file_size_legacy_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final violatingFile = File(
        '${temp.path}/app/lib/features/game/widgets/huge_panel.dart',
      )..createSync(recursive: true);
      violatingFile.writeAsStringSync(List.filled(701, '// line').join('\n'));

      final toolDir = Directory('${temp.path}/tool')
        ..createSync(recursive: true);
      File(
        '${toolDir.path}/legacy_game_widgets_waiver_table.yaml',
      ).writeAsStringSync('''
# Decoy: historical repo-lint keyed waiver shape; checker must not load this.
exempt_files:
  - app/lib/features/game/widgets/huge_panel.dart
''');

      final logs = <String>[];
      final code = runCheckGameWidgetsFileSize(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 1);
      expect(logs.join('\n'), contains('huge_panel.dart'));
      expect(logs.join('\n'), contains('701 physical lines > 700'));
    },
  );
}
