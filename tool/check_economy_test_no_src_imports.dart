import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// SPEC: SPEC/program/repo-lint.md (Refs #3836).
///
/// Forbid `package:colonizethis_economy/src/` imports in economy tests.
/// Tests must use the public barrel or shared test_support fixtures.
const _economyTestPrefix = 'packages/colonizethis_economy/test/';

final RegExp _forbiddenSrcImport = RegExp(
  r'''import\s+['"]package:colonizethis_economy/src/[^'"]+['"]\s*;''',
);

bool economyTestNoSrcImportsPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_economyTestPrefix) &&
      normalized.endsWith('.dart');
}

String? economyTestNoSrcImportsViolationReason(String content) {
  if (_forbiddenSrcImport.hasMatch(content)) {
    return 'use `package:colonizethis_economy/colonizethis_economy.dart` '
        'or colonizethis_economy_test_support instead of src/ imports '
        '(Refs #3836)';
  }
  return null;
}

int runCheckEconomyTestNoSrcImports(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!economyTestNoSrcImportsPathInScope(rel)) {
      continue;
    }
    final content = file.readAsStringSync();
    final reason = economyTestNoSrcImportsViolationReason(content);
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI('check_economy_test_no_src_imports: no src/ import violations.');
    return 0;
  }
  logE(
    'check_economy_test_no_src_imports: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckEconomyTestNoSrcImports(Directory.current.path));
}
