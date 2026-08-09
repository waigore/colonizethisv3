import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix for the economy package test tree (Refs #4299).
///
/// Economy production code lives under `lib/src/economy/`; the testing rule
/// (`colonizethis-testing.mdc`) mandates that `test/` mirrors `lib/`. This
/// gate keeps the economy test tree mirrored by forbidding loose Dart sources
/// at the `test/` root: every economy test must live in a subdirectory such as
/// `test/economy/`, `test/economy/world_market/`, or `test/economy/trade_counsel/`
/// rather than flat in `test/`.
const String _economyTestRootPrefix = 'packages/colonizethis_economy/test/';

/// True when the repo-relative [slashPath] is under the economy package `test/`.
bool economyTestMirrorsLibPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_economyTestRootPrefix);
}

/// Returns a violation reason when the economy test source at repo-relative
/// [slashPath] sits directly in the `test/` root (no mirroring subdirectory),
/// or `null` when the file is nested in a subdirectory (compliant) or out of
/// scope.
String? economyTestMirrorsLibViolationReason(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_economyTestRootPrefix)) {
    return null;
  }
  final remainder = normalized.substring(_economyTestRootPrefix.length);
  if (remainder.isEmpty || remainder.contains('/')) {
    return null;
  }
  return 'lives directly in `test/`; move it under a subdirectory that mirrors '
      '`lib/src/economy/` (for example `test/economy/` or '
      '`test/economy/world_market/`) per the testing-rule `test/`-mirrors-`lib/` '
      'policy (Refs #4299)';
}

int runCheckEconomyTestMirrorsLib(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!economyTestMirrorsLibPathInScope(rel)) {
      continue;
    }
    final reason = economyTestMirrorsLibViolationReason(rel);
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI('check_economy_test_mirrors_lib: no flat-root economy test sources.');
    return 0;
  }
  logE('check_economy_test_mirrors_lib: ${violations.length} violation(s):');
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckEconomyTestMirrorsLib(Directory.current.path));
}
