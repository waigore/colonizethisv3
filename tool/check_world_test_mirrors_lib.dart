import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix for the world package test tree (Refs #4330).
///
/// World production code lives under `lib/src/{world,trace,...}/`; the testing
/// rule (`colonizethis-testing.mdc`) mandates that `test/` mirrors `lib/`. This
/// gate forbids loose Dart sources at the `test/` root: every world test must
/// live in a subdirectory such as `test/world/`, `test/trace/`, or
/// `test/world_test_support/` rather than flat in `test/`.
const String _worldTestRootPrefix = 'packages/colonizethis_world/test/';

/// True when the repo-relative [slashPath] is under the world package `test/`.
bool worldTestMirrorsLibPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_worldTestRootPrefix);
}

/// Returns a violation reason when the world test source at repo-relative
/// [slashPath] sits directly in the `test/` root, or `null` when nested or
/// out of scope.
String? worldTestMirrorsLibViolationReason(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_worldTestRootPrefix)) {
    return null;
  }
  final remainder = normalized.substring(_worldTestRootPrefix.length);
  if (remainder.isEmpty || remainder.contains('/')) {
    return null;
  }
  return 'lives directly in `test/`; move it under a subdirectory that mirrors '
      '`lib/src/` (for example `test/world/` or `test/trace/`) per the '
      'testing-rule `test/`-mirrors-`lib/` policy (Refs #4330)';
}

int runCheckWorldTestMirrorsLib(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!worldTestMirrorsLibPathInScope(rel)) {
      continue;
    }
    final reason = worldTestMirrorsLibViolationReason(rel);
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI('check_world_test_mirrors_lib: no flat-root world test sources.');
    return 0;
  }
  logE('check_world_test_mirrors_lib: ${violations.length} violation(s):');
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckWorldTestMirrorsLib(Directory.current.path));
}
