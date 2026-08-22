import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_app_core_services_file_size.dart';

void main() {
  test('wave-20 ceiling is 260', () {
    expect(appCoreServicesFileSizeCeiling, 260);
  });

  test('fails when a core-services file exceeds 260 lines', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_core_services_file_size_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final violatingFile = File(
      '${temp.path}/app/lib/core/services/game_service/too_long.dart',
    )..createSync(recursive: true);
    violatingFile.writeAsStringSync(List.filled(261, '// line').join('\n'));

    final logs = <String>[];
    final code = runCheckAppCoreServicesFileSize(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('too_long.dart'));
    expect(logs.join('\n'), contains('261 physical lines > 260'));
  });

  test('fails when core services directory is missing', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_core_services_file_size_no_dir_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final logs = <String>[];
    final code = runCheckAppCoreServicesFileSize(
      temp.path,
      info: logs.add,
      err: logs.add,
    );

    expect(code, 1);
    expect(logs.join('\n'), contains('core/services not found'));
  });

  test('passes when all core-services files are at or below 260 lines', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_app_core_services_file_size_pass_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));

    final okFile = File(
      '${temp.path}/app/lib/core/services/game_service/ok.dart',
    )..createSync(recursive: true);
    okFile.writeAsStringSync(List.filled(260, '// line').join('\n'));

    final code = runCheckAppCoreServicesFileSize(temp.path);
    expect(code, 0);
  });
}
