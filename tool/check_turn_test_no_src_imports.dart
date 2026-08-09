import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// SPEC: SPEC/program/repo-lint.md (Refs #4252).
///
/// Forbid `package:colonizethis_turn/src/` imports under turn tests. Tests must
/// use `colonizethis_turn.dart` or `colonizethis_turn_testing.dart`.
const _turnTestPrefix = 'packages/colonizethis_turn/test/';

final RegExp _forbiddenTurnSrcImport = RegExp(
  r'''import\s+['"]package:colonizethis_turn/src/[^'"]+['"]\s*;''',
);

bool turnTestNoSrcImportsPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_turnTestPrefix) &&
      normalized.endsWith('.dart');
}

String? turnTestNoSrcImportsViolationReason(String content) {
  if (_forbiddenTurnSrcImport.hasMatch(content)) {
    return 'use `package:colonizethis_turn/colonizethis_turn.dart` or '
        '`package:colonizethis_turn/colonizethis_turn_testing.dart` instead of '
        'src/ imports (Refs #4252)';
  }
  return null;
}

int runCheckTurnTestNoSrcImports(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!turnTestNoSrcImportsPathInScope(rel)) {
      continue;
    }
    final content = file.readAsStringSync();
    final reason = turnTestNoSrcImportsViolationReason(content);
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI('check_turn_test_no_src_imports: no src/ import violations.');
    return 0;
  }
  logE(
    'check_turn_test_no_src_imports: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckTurnTestNoSrcImports(Directory.current.path));
}
