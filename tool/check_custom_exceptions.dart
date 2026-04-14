import 'dart:io';

import 'package:colonizethis_exception_lint/exception_enforcement.dart';
import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// PR-blocking check for generic exception throws in runtime domain code.
///
/// SPEC: SPEC/program/exception-enforcement.md
///
/// Used by `ct_repo_lint` in-process; [info] / [err] default to stdout/stderr.
int runCheckCustomExceptions(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;
  final dartFiles = collectRepoLintDomainDartFiles(repoRoot);
  final violations = <CustomExceptionViolation>[];

  for (final file in dartFiles) {
    final relativePath = p.relative(file.path, from: repoRoot);
    final content = file.readAsStringSync();
    violations.addAll(findCustomExceptionViolations(relativePath, content));
  }

  if (violations.isEmpty) {
    logI('check_custom_exceptions: no violations found.');
    return 0;
  }

  logE('check_custom_exceptions: found ${violations.length} violation(s):');
  for (final violation in violations) {
    logE(
      ' - ${violation.path}:${violation.line}: '
      'throwing ${violation.exceptionType} is forbidden; use a domain-specific exception type',
    );
  }
  return 1;
}

void main() {
  exit(runCheckCustomExceptions(Directory.current.path));
}
