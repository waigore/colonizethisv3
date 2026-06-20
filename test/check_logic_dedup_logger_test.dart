// Refs #2391, Pattern 1 — guards `repo.logic_dedup_logger` enforcement.
// Refs #3290 — post-split scan roots span the eight split logic-domain
// packages plus the thin `colonizethis_logic` core.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_logic_dedup_logger.dart';

void main() {
  group('repo.logic_dedup_logger', () {
    test('passes on real repo workspace', () {
      final repoRoot = Directory.current.path;
      final logs = <String>[];
      final code = runCheckLogicDedupLogger(
        repoRoot,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
      expect(
        logs.join('\n'),
        contains('check_logic_dedup_logger: no violations found.'),
      );
    });

    test('scan roots cover all split domain packages plus the thin core', () {
      final dirs = logicDedupLoggerScanDirsForTests();
      expect(
        dirs,
        containsAll(<String>[
          'packages/colonizethis_world/lib/src',
          'packages/colonizethis_combat/lib/src',
          'packages/colonizethis_economy/lib/src',
          'packages/colonizethis_diplomacy/lib/src',
          'packages/colonizethis_setup/lib/src',
          'packages/colonizethis_orders/lib/src',
          'packages/colonizethis_turn/lib/src',
          'packages/colonizethis_ai_contracts/lib/src',
          'packages/colonizethis_logic/lib/src',
        ]),
      );
    });

    test('fails when a thin-core lib/src file declares `final _log = '
        'packageLogger();`', () {
      final temp = Directory.systemTemp
          .createTempSync('logic_dedup_logger_fail_');
      addTearDown(() => temp.deleteSync(recursive: true));

      _seedAllScanRoots(temp.path);
      final logicSrc = Directory(
        p.join(temp.path, 'packages/colonizethis_logic/lib/src/example'),
      )..createSync(recursive: true);

      File(p.join(logicSrc.path, 'has_local_logger.dart')).writeAsStringSync(
        "import 'package:colonizethis_logic/package_logger.dart';\n"
        '\n'
        'final _log = packageLogger();\n'
        '\n'
        'void use() => _log.i("hello");\n',
      );

      final infoLogs = <String>[];
      final errLogs = <String>[];
      final code = runCheckLogicDedupLogger(
        temp.path,
        info: infoLogs.add,
        err: errLogs.add,
      );

      expect(code, 1);
      expect(errLogs.join('\n'), contains('has_local_logger.dart'));
      expect(errLogs.join('\n'), contains('package logger'));
    });

    test('fails when a split-domain package declares `final _log = '
        'packageLogger();` (post-split scope)', () {
      final temp = Directory.systemTemp
          .createTempSync('logic_dedup_logger_domain_fail_');
      addTearDown(() => temp.deleteSync(recursive: true));

      _seedAllScanRoots(temp.path);
      final ordersSrc = Directory(
        p.join(temp.path, 'packages/colonizethis_orders/lib/src/example'),
      )..createSync(recursive: true);

      File(p.join(ordersSrc.path, 'has_local_logger.dart')).writeAsStringSync(
        "import 'package:colonizethis_orders/package_logger.dart';\n"
        '\n'
        'final _log = packageLogger();\n'
        '\n'
        'void use() => _log.i("hello");\n',
      );

      final errLogs = <String>[];
      final code = runCheckLogicDedupLogger(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );

      expect(code, 1);
      expect(
        errLogs.join('\n'),
        contains('packages/colonizethis_orders/lib/src/example/'
            'has_local_logger.dart'),
      );
    });

    test('fails when a scan-root lib/src tree is missing', () {
      final temp = Directory.systemTemp
          .createTempSync('logic_dedup_logger_missing_');
      addTearDown(() => temp.deleteSync(recursive: true));

      // Seed every scan root except one to exercise the missing-tree guard.
      _seedAllScanRoots(temp.path);
      Directory(p.join(temp.path, 'packages/colonizethis_turn/lib/src'))
          .deleteSync(recursive: true);

      final errLogs = <String>[];
      final code = runCheckLogicDedupLogger(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );

      expect(code, 1);
      expect(
        errLogs.join('\n'),
        contains('Missing logic src directory: '
            'packages/colonizethis_turn/lib/src'),
      );
    });

    test('passes when files use a shared named logger instead', () {
      final temp = Directory.systemTemp
          .createTempSync('logic_dedup_logger_pass_');
      addTearDown(() => temp.deleteSync(recursive: true));

      _seedAllScanRoots(temp.path);
      final logicSrc = Directory(
        p.join(temp.path, 'packages/colonizethis_logic/lib/src/example'),
      )..createSync(recursive: true);

      File(p.join(logicSrc.path, 'uses_shared.dart')).writeAsStringSync(
        "import 'package:colonizethis_logic/package_logger.dart';\n"
        '\n'
        'void use() => logicLog.i("hello");\n',
      );

      final code = runCheckLogicDedupLogger(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });

    test('does not flag named sub-prefix loggers', () {
      final temp = Directory.systemTemp
          .createTempSync('logic_dedup_logger_named_');
      addTearDown(() => temp.deleteSync(recursive: true));

      _seedAllScanRoots(temp.path);
      final logicSrc = Directory(
        p.join(temp.path, 'packages/colonizethis_logic/lib/src/example'),
      )..createSync(recursive: true);

      File(p.join(logicSrc.path, 'named_log.dart')).writeAsStringSync(
        "import 'package:colonizethis_logic/package_logger.dart';\n"
        '\n'
        "final orderSuggestionLog = packageLogger('order_suggestion');\n"
        "final _gameEventLog = packageLogger();\n"
        '\n'
        'void use() => orderSuggestionLog.i("hello");\n',
      );

      final code = runCheckLogicDedupLogger(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });
  });
}

/// Creates every scan-root `lib/src` directory under [repoRoot] so the
/// checker's missing-tree guard does not short-circuit before scanning.
void _seedAllScanRoots(String repoRoot) {
  for (final relative in logicDedupLoggerScanDirsForTests()) {
    Directory(p.join(repoRoot, relative)).createSync(recursive: true);
  }
}
