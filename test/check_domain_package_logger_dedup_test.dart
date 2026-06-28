// Refs #3393, Phase 2 — guards `repo.domain_package_logger_dedup` enforcement:
// every packages/*/lib/package_logger.dart must delegate to the shared
// domainPackageLogger factory instead of copy-pasting the CtLogger(...) body.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../tool/check_domain_package_logger_dedup.dart';

void main() {
  group('repo.domain_package_logger_dedup', () {
    test('passes on real repo workspace', () {
      final repoRoot = Directory.current.path;
      final logs = <String>[];
      final code = runCheckDomainPackageLoggerDedup(
        repoRoot,
        info: logs.add,
        err: logs.add,
      );
      expect(code, 0, reason: logs.join('\n'));
      expect(
        logs.join('\n'),
        contains('check_domain_package_logger_dedup: no violations found.'),
      );
    });

    test('passes when a package delegates to the shared factory', () {
      final temp = Directory.systemTemp.createTempSync(
        'domain_logger_dedup_pass_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeLoggerFile(
        temp.path,
        'colonizethis_world',
        "import 'package:colonizethis_logger/colonizethis_logger.dart';\n"
            "\n"
            "import 'package_log_prefix.dart';\n"
            "\n"
            "export 'package:colonizethis_logger/colonizethis_logger.dart' "
            "show CtLogger;\n"
            "\n"
            "CtLogger packageLogger([String? subPrefix]) =>\n"
            "    domainPackageLogger(kPackageLogPrefix, subPrefix);\n"
            "\n"
            "final worldLog = packageLogger();\n",
      );

      final code = runCheckDomainPackageLoggerDedup(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });

    test('fails when a package_logger.dart constructs CtLogger inline', () {
      final temp = Directory.systemTemp.createTempSync(
        'domain_logger_dedup_fail_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      // One compliant package and one copy-paste offender.
      _writeLoggerFile(
        temp.path,
        'colonizethis_world',
        "import 'package:colonizethis_logger/colonizethis_logger.dart';\n"
            "import 'package_log_prefix.dart';\n"
            "CtLogger packageLogger([String? subPrefix]) =>\n"
            "    domainPackageLogger(kPackageLogPrefix, subPrefix);\n",
      );
      _writeLoggerFile(
        temp.path,
        'colonizethis_combat',
        "import 'package_log_prefix.dart';\n"
            "export 'package:colonizethis_logger/colonizethis_logger.dart' "
            "show CtLogger;\n"
            "import 'package:colonizethis_logger/colonizethis_logger.dart';\n"
            "\n"
            "CtLogger packageLogger([String? subPrefix]) {\n"
            "  if (subPrefix == null || subPrefix.isEmpty) {\n"
            "    return CtLogger(kPackageLogPrefix);\n"
            "  }\n"
            "  return CtLogger('\$kPackageLogPrefix.\$subPrefix');\n"
            "}\n",
      );

      final errLogs = <String>[];
      final code = runCheckDomainPackageLoggerDedup(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );

      expect(code, 1);
      expect(
        errLogs.join('\n'),
        contains('packages/colonizethis_combat/lib/package_logger.dart'),
      );
      expect(
        errLogs.join('\n'),
        isNot(contains('packages/colonizethis_world/lib/package_logger.dart')),
      );
    });

    test('does not flag the show-CtLogger export or return-type annotation', () {
      final temp = Directory.systemTemp.createTempSync(
        'domain_logger_dedup_export_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      _writeLoggerFile(
        temp.path,
        'colonizethis_models',
        "import 'package:colonizethis_logger/colonizethis_logger.dart';\n"
            "import 'package_log_prefix.dart';\n"
            "export 'package:colonizethis_logger/colonizethis_logger.dart' "
            "show CtLogger;\n"
            "CtLogger packageLogger([String? subPrefix]) =>\n"
            "    domainPackageLogger(kPackageLogPrefix, subPrefix);\n",
      );

      final code = runCheckDomainPackageLoggerDedup(
        temp.path,
        info: (_) {},
        err: (_) {},
      );
      expect(code, 0);
    });

    test('fails when the packages directory is missing', () {
      final temp = Directory.systemTemp.createTempSync(
        'domain_logger_dedup_missing_',
      );
      addTearDown(() => temp.deleteSync(recursive: true));

      final errLogs = <String>[];
      final code = runCheckDomainPackageLoggerDedup(
        temp.path,
        info: (_) {},
        err: errLogs.add,
      );

      expect(code, 1);
      expect(
        errLogs.join('\n'),
        contains('Missing packages directory'),
      );
    });
  });
}

void _writeLoggerFile(String repoRoot, String packageName, String content) {
  final dir = Directory(p.join(repoRoot, 'packages', packageName, 'lib'))
    ..createSync(recursive: true);
  File(p.join(dir.path, 'package_logger.dart')).writeAsStringSync(content);
}
