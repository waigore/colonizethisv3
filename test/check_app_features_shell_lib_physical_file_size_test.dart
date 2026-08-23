import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_features_shell_lib_physical_file_size.dart';

const _shellRel = 'app/lib/features/shell';

void main() {
  test('wave-21 shell ceiling is 250', () {
    expect(appFeaturesShellLibPhysicalFileSizeCeiling, 250);
    expect(appFeaturesShellLibPhysicalFileSizeGrandfatheredForTests, isEmpty);
  });

  test('passes for the real app feature shell subtree', () {
    final logs = <String>[];
    final code = runCheckAppFeaturesShellLibPhysicalFileSize(
      Directory.current.path,
      info: logs.add,
      err: logs.add,
    );
    expect(
      code,
      0,
      reason:
          'Every non-grandfathered app/lib/features/shell file must stay '
          'at or below '
          '${maxAppFeaturesShellLibPhysicalFileLinesForTests()} physical '
          'lines.\n${logs.join('\n')}',
    );
  });

  test('fails when a non-generated shell file exceeds the cap', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_shell_phys_size_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    Directory('${temp.path}/$_shellRel').createSync(recursive: true);
    File('${temp.path}/$_shellRel/huge.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync(List.filled(251, 'final x = 1;').join('\n'));

    final logs = <String>[];
    final code = runCheckAppFeaturesShellLibPhysicalFileSize(
      temp.path,
      grandfatheredPaths: const [],
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('huge.dart'));
    expect(logs.join('\n'), contains('physical lines > 250'));
  });

  test('fails when the shell directory is missing', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_shell_phys_size_nodir_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final logs = <String>[];
    final code = runCheckAppFeaturesShellLibPhysicalFileSize(
      temp.path,
      grandfatheredPaths: const [],
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('not found'));
  });
}
