import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// SPEC: SPEC/program/repo-lint.md (Refs #3865).
///
/// Forbid inline `Game(` construction under `packages/colonizethis_combat/test/**`.
/// Combat tests must use shared builders from `colonizethis_combat_test_support`.
const _combatTestPrefix = 'packages/colonizethis_combat/test/';

final RegExp _inlineGameConstructor = RegExp(r'\bGame\s*\(');

bool combatTestCoreFixturesSharedPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_combatTestPrefix) &&
      normalized.endsWith('_test.dart');
}

String? combatTestCoreFixturesSharedViolationReason(String content) {
  if (_inlineGameConstructor.hasMatch(content)) {
    return 'use shared game builders from colonizethis_combat_test_support '
        'instead of inline Game(...) (Refs #3865)';
  }
  return null;
}

int runCheckCombatTestCoreFixturesShared(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!combatTestCoreFixturesSharedPathInScope(rel)) {
      continue;
    }
    final reason = combatTestCoreFixturesSharedViolationReason(
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_combat_test_core_fixtures_shared: no inline Game(...) violations.',
    );
    return 0;
  }

  logE(
    'check_combat_test_core_fixtures_shared: ${violations.length} '
    'violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckCombatTestCoreFixturesShared(Directory.current.path));
}
