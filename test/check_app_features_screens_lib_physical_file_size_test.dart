import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_features_screens_lib_physical_file_size.dart';

const _screensRel = 'app/lib/features/game/screens';

void main() {
  test('passes for the real app feature screens subtree', () {
    final logs = <String>[];
    final code = runCheckAppFeaturesScreensLibPhysicalFileSize(
      Directory.current.path,
      info: logs.add,
      err: logs.add,
    );
    expect(
      code,
      0,
      reason:
          'Every non-grandfathered app/lib/features/game/screens file must stay '
          'at or below '
          '${maxAppFeaturesScreensLibPhysicalFileLinesForTests()} physical '
          'lines.\n${logs.join('\n')}',
    );
  });

  test('fails when a non-generated screens file exceeds the cap', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_screens_phys_size_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    Directory('${temp.path}/$_screensRel').createSync(recursive: true);
    File('${temp.path}/$_screensRel/huge.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(List.filled(301, 'final x = 1;').join('\n'));

    final logs = <String>[];
    final code = runCheckAppFeaturesScreensLibPhysicalFileSize(
      temp.path,
      grandfatheredPaths: const [],
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('huge.dart'));
    expect(logs.join('\n'), contains('physical lines > 300'));
  });

  test('fails when the screens directory is missing', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_screens_phys_size_nodir_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final logs = <String>[];
    final code = runCheckAppFeaturesScreensLibPhysicalFileSize(
      temp.path,
      grandfatheredPaths: const [],
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('not found'));
  });
}
