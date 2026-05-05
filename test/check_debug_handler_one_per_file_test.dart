import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_debug_handler_one_per_file.dart';

void main() {
  test('fails when a debug handler file has multiple applyDebug functions', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_debug_handler_one_per_file_fail_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    final file = File(
      '${temp.path}/app/lib/core/services/app_event_handler_debug_spawn.dart',
    )..createSync(recursive: true);
    file.writeAsStringSync('''
String applyDebugFirst() => 'a';
String applyDebugSecond() => 'b';
''');

    final logs = <String>[];
    final code = runCheckDebugHandlerOnePerFile(
      temp.path,
      info: logs.add,
      err: logs.add,
    );
    expect(code, 1);
    expect(
      logs.join('\n'),
      contains('has 2 top-level applyDebug* function(s)'),
    );
  });

  test('fails when a debug handler file has zero applyDebug functions', () {
    final temp = Directory.systemTemp.createTempSync(
      'check_debug_handler_one_per_file_zero_',
    );
    addTearDown(() => temp.deleteSync(recursive: true));
    final file = File(
      '${temp.path}/app/lib/core/services/app_event_handler_debug_spawn.dart',
    )..createSync(recursive: true);
    file.writeAsStringSync("String helper() => 'noop';\n");

    final code = runCheckDebugHandlerOnePerFile(temp.path);
    expect(code, 1);
  });

  test(
    'passes when each debug handler file has exactly one applyDebug function',
    () {
      final temp = Directory.systemTemp.createTempSync(
        'check_debug_handler_one_per_file_pass_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));
      final servicesDir = Directory('${temp.path}/app/lib/core/services')
        ..createSync(recursive: true);
      File(
        '${servicesDir.path}/app_event_handler_debug_spawn_civilian.dart',
      ).writeAsStringSync("String applyDebugSpawnCivilian() => 'ok';\n");
      File(
        '${servicesDir.path}/app_event_handler_debug_treasury.dart',
      ).writeAsStringSync("String applyDebugTreasury() => 'ok';\n");

      final code = runCheckDebugHandlerOnePerFile(temp.path);
      expect(code, 0);
    },
  );
}
