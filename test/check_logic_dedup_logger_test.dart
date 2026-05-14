// Refs #2391, Pattern 1 — guards `repo.logic_dedup_logger` enforcement.

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

    test('fails when a lib/src file declares `final _log = packageLogger();`',
        () {
      final temp = Directory.systemTemp
          .createTempSync('logic_dedup_logger_fail_');
      addTearDown(() => temp.deleteSync(recursive: true));

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
      expect(errLogs.join('\n'), contains('logicLog'));
    });

    test('passes when files use shared logicLog instead', () {
      final temp = Directory.systemTemp
          .createTempSync('logic_dedup_logger_pass_');
      addTearDown(() => temp.deleteSync(recursive: true));

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
