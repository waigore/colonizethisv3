// Refs #4269 — guards `repo.app_lib_no_src_imports`: app/lib must not deep-import
// package src/ trees.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_lib_no_src_imports.dart';

void main() {
  group('repo.app_lib_no_src_imports', () {
    test('passes on real repo workspace', () {
      final repoRoot = Directory.current.path;
      final logs = <String>[];
      final code = runCheckAppLibNoSrcImports(
        repoRoot,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
      expect(
        logs.join('\n'),
        contains('check_app_lib_no_src_imports: no src/ import violations.'),
      );
    });

    test('fails when app/lib imports a package src/ path', () {
      final temp = Directory.systemTemp.createTempSync('app_lib_no_src_fail_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final targetDir = Directory(p.join(temp.path, 'app', 'lib', 'features'))
        ..createSync(recursive: true);
      File(p.join(targetDir.path, 'sample.dart')).writeAsStringSync('''
import 'package:colonizethis_orders/src/orders/diplomatic_panel_actions.dart';

class Sample {}
''');

      final errLogs = <String>[];
      final code = runCheckAppLibNoSrcImports(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );

      expect(code, 1);
      expect(
        errLogs.join('\n'),
        contains('sample.dart'),
      );
      expect(
        errLogs.join('\n'),
        contains('src/ imports'),
      );
    });

    test('passes when app/lib uses domain barrels only', () {
      final temp = Directory.systemTemp.createTempSync('app_lib_no_src_pass_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final targetDir = Directory(p.join(temp.path, 'app', 'lib', 'widgets'))
        ..createSync(recursive: true);
      File(p.join(targetDir.path, 'sample.dart')).writeAsStringSync('''
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_logic/turn_time_api.dart';

class Sample {}
''');

      final logs = <String>[];
      final code = runCheckAppLibNoSrcImports(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0, reason: logs.join('\n'));
    });
  });
}
