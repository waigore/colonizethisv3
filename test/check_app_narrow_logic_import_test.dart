// Refs #4240 — guards `repo.app_narrow_logic_import`: scoped app trees must not
// import the broad colonizethis_logic barrel.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_app_narrow_logic_import.dart';

void main() {
  group('repo.app_narrow_logic_import', () {
    test('passes on real repo workspace', () {
      final repoRoot = Directory.current.path;
      final logs = <String>[];
      final code = runCheckAppNarrowLogicImport(
        repoRoot,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
      expect(
        logs.join('\n'),
        contains(
          'check_app_narrow_logic_import: no broad logic barrel imports found.',
        ),
      );
    });

    test('fails when a scoped file imports the broad logic barrel', () {
      final temp = Directory.systemTemp.createTempSync(
        'app_narrow_logic_import_fail_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final targetDir = Directory(
        p.join(temp.path, 'app', 'lib', 'providers'),
      )..createSync(recursive: true);
      File(
        p.join(targetDir.path, 'sample_provider.dart'),
      ).writeAsStringSync('''
import 'package:colonizethis_logic/colonizethis_logic.dart';

class SampleProvider {}
''');

      for (final relativeDir in scopedRelativeDirs) {
        if (relativeDir == 'app/lib/providers') {
          continue;
        }
        Directory(p.join(temp.path, relativeDir)).createSync(recursive: true);
      }

      final errLogs = <String>[];
      final code = runCheckAppNarrowLogicImport(
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
        contains('sample_provider.dart:1'),
      );
    });

    test('passes when scoped files use domain barrels only', () {
      final temp = Directory.systemTemp.createTempSync(
        'app_narrow_logic_import_pass_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      for (final relativeDir in scopedRelativeDirs) {
        final targetDir = Directory(p.join(temp.path, relativeDir))
          ..createSync(recursive: true);
        if (relativeDir != 'app/lib/providers') {
          continue;
        }
        File(
          p.join(targetDir.path, 'sample_provider.dart'),
        ).writeAsStringSync('''
import 'package:colonizethis_turn/colonizethis_turn.dart';
import 'package:colonizethis_logic/order_suggestion_api.dart';

class SampleProvider {}
''');
      }

      final logs = <String>[];
      final code = runCheckAppNarrowLogicImport(
        temp.path,
        info: logs.add,
        err: logs.add,
      );

      expect(code, 0, reason: logs.join('\n'));
    });
  });
}
