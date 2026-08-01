// Refs #4224 — guards `repo.app_core_services_narrow_logic_import`: core
// services must not import the broad colonizethis_logic barrel.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_core_services_narrow_logic_import.dart';

void main() {
  group('repo.app_core_services_narrow_logic_import', () {
    test('passes on real repo workspace', () {
      final repoRoot = Directory.current.path;
      final logs = <String>[];
      final code = runCheckAppCoreServicesNarrowLogicImport(
        repoRoot,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
      expect(
        logs.join('\n'),
        contains(
          'check_app_core_services_narrow_logic_import: no broad logic barrel '
          'imports found.',
        ),
      );
    });

    test('fails when a core service file imports the broad logic barrel', () {
      final temp = Directory.systemTemp.createTempSync(
        'app_core_services_narrow_logic_fail_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final targetDir = Directory(
        p.join(temp.path, 'app', 'lib', 'core', 'services', 'sample'),
      )..createSync(recursive: true);
      File(
        p.join(targetDir.path, 'sample_service.dart'),
      ).writeAsStringSync('''
import 'package:colonizethis_logic/colonizethis_logic.dart';

class SampleService {}
''');

      final errLogs = <String>[];
      final code = runCheckAppCoreServicesNarrowLogicImport(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );

      expect(code, 1);
      expect(
        errLogs.join('\n'),
        contains('broad colonizethis_logic barrel import is disallowed'),
      );
      expect(
        errLogs.join('\n'),
        contains('sample_service.dart:1'),
      );
    });

    test('passes when core services use domain barrels only', () {
      final temp = Directory.systemTemp.createTempSync(
        'app_core_services_narrow_logic_pass_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final targetDir = Directory(
        p.join(temp.path, 'app', 'lib', 'core', 'services', 'sample'),
      )..createSync(recursive: true);
      File(
        p.join(targetDir.path, 'sample_service.dart'),
      ).writeAsStringSync('''
import 'package:colonizethis_turn/colonizethis_turn.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';

class SampleService {}
''');

      final logs = <String>[];
      final code = runCheckAppCoreServicesNarrowLogicImport(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0, reason: logs.join('\n'));
    });
  });
}
