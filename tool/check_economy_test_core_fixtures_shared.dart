import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// SPEC: SPEC/program/repo-lint.md (Refs #3836, #3856).
///
/// Forbid inline `Game(` construction under `packages/colonizethis_economy/test/**`.
/// Economy tests must use shared builders from `colonizethis_economy_test_support`.
const _economyTestPrefix = 'packages/colonizethis_economy/test/';

final RegExp _inlineGameConstructor = RegExp(r'\bGame\s*\(');

bool economyTestCoreFixturesSharedPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_economyTestPrefix) &&
      normalized.endsWith('_test.dart');
}

String? economyTestCoreFixturesSharedViolationReason(String content) {
  if (_inlineGameConstructor.hasMatch(content)) {
    return 'use shared game builders from colonizethis_economy_test_support '
        'instead of inline Game(...) (Refs #3836, #3856)';
  }
  return null;
}

int runCheckEconomyTestCoreFixturesShared(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!economyTestCoreFixturesSharedPathInScope(rel)) {
      continue;
    }
    final reason = economyTestCoreFixturesSharedViolationReason(
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI('check_economy_test_core_fixtures_shared: no inline Game(...) violations.');
    return 0;
  }

  logE(
    'check_economy_test_core_fixtures_shared: ${violations.length} '
    'violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckEconomyTestCoreFixturesShared(Directory.current.path));
}
