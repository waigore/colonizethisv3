import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_flame_lib_physical_file_size.dart';

const _flameRel = 'app/lib/features/game/flame';

void main() {
  test('passes for the real app flame subtree with grandfather allowlist', () {
    final logs = <String>[];
    final code = runCheckAppFlameLibPhysicalFileSize(
      Directory.current.path,
      info: logs.add,
      err: logs.add,
    );
    expect(
      code,
      0,
      reason:
          'Every non-grandfathered app/lib/features/game/flame file must stay '
          'at or below ${maxAppFlameLibPhysicalFileLinesForTests()} physical '
          'lines.\n${logs.join('\n')}',
    );
  });

  test('fails when a non-generated flame file exceeds the cap', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_flame_phys_size_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    Directory('${temp.path}/$_flameRel').createSync(recursive: true);
    File('${temp.path}/$_flameRel/huge.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(List.filled(301, 'final x = 1;').join('\n'));

    final logs = <String>[];
    final code = runCheckAppFlameLibPhysicalFileSize(
      temp.path,
      grandfatheredPaths: const [],
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('huge.dart'));
    expect(logs.join('\n'), contains('physical lines > 300'));
  });

  test('fails when the flame directory is missing', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_flame_phys_size_nodir_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final logs = <String>[];
    final code = runCheckAppFlameLibPhysicalFileSize(
      temp.path,
      grandfatheredPaths: const [],
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('not found'));
  });
}
