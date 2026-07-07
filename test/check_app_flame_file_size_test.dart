import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_flame_file_size.dart';

const _flameRel = 'app/lib/features/game/flame';

void main() {
  test('passes for the real app flame subtree', () {
    final logs = <String>[];
    final code = runCheckAppFlameFileSize(
      Directory.current.path,
      info: logs.add,
      err: logs.add,
    );
    expect(
      code,
      0,
      reason:
          'Every app/lib/features/game/flame file must stay at or below '
          '${maxAppFlameFileNonCommentLinesForTests()} non-comment lines.\n'
          '${logs.join('\n')}',
    );
  });

  test('fails when a non-generated flame file exceeds the cap', () {
    final temp = Directory.systemTemp.createTempSync('check_flame_size_fail_');
    addTearDown(() => temp.deleteSync(recursive: true));

    Directory('${temp.path}/$_flameRel').createSync(recursive: true);
    File('${temp.path}/$_flameRel/huge.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(List.filled(601, 'final x = 1;').join('\n'));

    final logs = <String>[];
    final code = runCheckAppFlameFileSize(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('huge.dart'));
    expect(logs.join('\n'), contains('non-comment lines > 600'));
  });

  test('fails when the flame directory is missing', () {
    final temp = Directory.systemTemp.createTempSync('check_flame_size_nodir_');
    addTearDown(() => temp.deleteSync(recursive: true));

    final logs = <String>[];
    final code = runCheckAppFlameFileSize(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('not found'));
  });
}
