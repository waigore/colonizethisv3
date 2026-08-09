import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix for the setup package test tree (Refs #4273).
///
/// Setup production code lives under `lib/src/setup/`; the testing rule
/// (`colonizethis-testing.mdc`) mandates that `test/` mirrors `lib/`. This gate
/// keeps the setup test tree mirrored by forbidding loose Dart sources at the
/// `test/` root: every setup test (and its co-located support helper) must live
/// in a subdirectory such as `test/setup/` rather than flat in `test/`.
const String _setupTestRootPrefix = 'packages/colonizethis_setup/test/';

/// True when the repo-relative [slashPath] is under the setup package `test/`.
bool setupTestMirrorsLibPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_setupTestRootPrefix);
}

/// Returns a violation reason when the setup test source at repo-relative
/// [slashPath] sits directly in the `test/` root (no mirroring subdirectory),
/// or `null` when the file is nested in a subdirectory (compliant) or out of
/// scope.
///
/// A loose root file is one whose remainder after the
/// `packages/colonizethis_setup/test/` prefix contains no further path
/// separator (for example `test/validation_exceptions_test.dart`). Nested files
/// such as `test/setup/validation_exceptions_test.dart` are compliant.
String? setupTestMirrorsLibViolationReason(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_setupTestRootPrefix)) {
    return null;
  }
  final remainder = normalized.substring(_setupTestRootPrefix.length);
  if (remainder.isEmpty || remainder.contains('/')) {
    return null;
  }
  return 'lives directly in `test/`; move it under a subdirectory that mirrors '
      '`lib/src/` (for example `test/setup/`) per the testing-rule '
      '`test/`-mirrors-`lib/` policy (Refs #4273)';
}

int runCheckColonizethisSetupTestMirrorsLib(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!setupTestMirrorsLibPathInScope(rel)) {
      continue;
    }
    final reason = setupTestMirrorsLibViolationReason(rel);
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_colonizethis_setup_test_mirrors_lib: no flat-root setup test sources.',
    );
    return 0;
  }
  logE(
    'check_colonizethis_setup_test_mirrors_lib: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckColonizethisSetupTestMirrorsLib(Directory.current.path));
}
