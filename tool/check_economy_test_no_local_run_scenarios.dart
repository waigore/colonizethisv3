import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// SPEC: SPEC/program/repo-lint.md (Refs #4014).
///
/// Forbids local `void Function() run` scenario shells under
/// `packages/colonizethis_economy/test/**` so #4002-style pins stay in
/// `colonizethis_economy_test_support`.

const _economyTestPrefix = 'packages/colonizethis_economy/test/';

/// Permanent micro-exceptions (empty unless a ≤2-file allowlist is documented
/// in `packages/colonizethis_economy/REFACTOR_TRACE.md`).
const _allowlistedRelativePaths = <String>{};

final RegExp _localRunTypedefPattern = RegExp(
  r'void\s+Function\s*\(\s*\)\s+run\b',
);

final RegExp _localRunFieldPattern = RegExp(
  r'\brun\s*:\s*\(\s*\)\s*\{',
);

void main() {
  exit(runCheckEconomyTestNoLocalRunScenarios(Directory.current.path));
}

int runCheckEconomyTestNoLocalRunScenarios(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!rel.startsWith(_economyTestPrefix) || !rel.endsWith('_test.dart')) {
      continue;
    }
    if (_allowlistedRelativePaths.contains(rel)) {
      continue;
    }
    final content = file.readAsStringSync();
    final lines = content.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('//')) {
        continue;
      }
      if (_localRunTypedefPattern.hasMatch(line) ||
          _localRunFieldPattern.hasMatch(line)) {
        violations.add('$rel:${i + 1}: local void Function() run scenario shell');
      }
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_economy_test_no_local_run_scenarios: no local run-shell '
      'violations.',
    );
    return 0;
  }

  logE(
    'check_economy_test_no_local_run_scenarios: ${violations.length} '
    'violation(s) (Refs #4014):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}
