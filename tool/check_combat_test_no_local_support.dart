import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// SPEC: SPEC/program/repo-lint.md (Refs #3865).
///
/// Forbid package-local combat test-support files under
/// `packages/colonizethis_combat/test/**`. Canonical home is
/// `colonizethis_combat_test_support`.
const String _combatTestPathPrefix = 'packages/colonizethis_combat/test/';

final RegExp _forbiddenSupportBasename = RegExp(r'.*_test_support\.dart$');

bool combatTestNoLocalSupportPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_combatTestPathPrefix);
}

String? combatTestLocalSupportViolationReason(String fileName) {
  if (_forbiddenSupportBasename.hasMatch(fileName)) {
    return 'package-local `$fileName` must live in '
        '`colonizethis_combat_test_support` instead (Refs #3865)';
  }
  return null;
}

int runCheckCombatTestNoLocalSupport(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!combatTestNoLocalSupportPathInScope(rel)) {
      continue;
    }
    final reason = combatTestLocalSupportViolationReason(p.basename(rel));
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_combat_test_no_local_support: no local support violations.',
    );
    return 0;
  }
  logE(
    'check_combat_test_no_local_support: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckCombatTestNoLocalSupport(Directory.current.path));
}
