import 'dart:io';

import 'package:colonizethis_exception_lint/exception_enforcement.dart';
import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// PR-blocking check for generic exception throws in runtime domain code.
///
/// SPEC: SPEC/program/exception-enforcement.md
void main() {
  final repoRoot = Directory.current.path;
  final dartFiles = collectRepoLintDomainDartFiles(repoRoot);
  final violations = <CustomExceptionViolation>[];

  for (final file in dartFiles) {
    final relativePath = p.relative(file.path, from: repoRoot);
    final content = file.readAsStringSync();
    violations.addAll(findCustomExceptionViolations(relativePath, content));
  }

  if (violations.isEmpty) {
    stdout.writeln('check_custom_exceptions: no violations found.');
    return;
  }

  stderr.writeln(
    'check_custom_exceptions: found ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    stderr.writeln(
      ' - ${violation.path}:${violation.line}: '
      'throwing ${violation.exceptionType} is forbidden; use a domain-specific exception type',
    );
  }
  exitCode = 1;
}
