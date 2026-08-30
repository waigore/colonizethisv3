import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix for the models package test tree (Refs #4334).
///
/// Models production code lives under `lib/src/`; the testing rule
/// (`colonizethis-testing.mdc`) mandates that `test/` mirrors `lib/`. This gate
/// keeps the models test tree mirrored by forbidding loose Dart sources at the
/// `test/` root: every models test must live in a subdirectory such as
/// `test/src/` or `test/app_events/` rather than flat in `test/`.
const String _modelsTestRootPrefix = 'packages/colonizethis_models/test/';

/// True when the repo-relative [slashPath] is under the models package `test/`.
bool modelsTestMirrorsLibPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_modelsTestRootPrefix);
}

/// Returns a violation reason when the models test source at repo-relative
/// [slashPath] sits directly in the `test/` root (no mirroring subdirectory),
/// or `null` when the file is nested in a subdirectory (compliant) or out of
/// scope.
String? modelsTestMirrorsLibViolationReason(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_modelsTestRootPrefix)) {
    return null;
  }
  final remainder = normalized.substring(_modelsTestRootPrefix.length);
  if (remainder.isEmpty || remainder.contains('/')) {
    return null;
  }
  return 'lives directly in `test/`; move it under a subdirectory that mirrors '
      '`lib/src/` (for example `test/src/` or `test/app_events/`) per the '
      'testing-rule `test/`-mirrors-`lib/` policy (Refs #4334)';
}

int runCheckModelsTestMirrorsLib(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!modelsTestMirrorsLibPathInScope(rel)) {
      continue;
    }
    final reason = modelsTestMirrorsLibViolationReason(rel);
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI('check_models_test_mirrors_lib: no flat-root models test sources.');
    return 0;
  }
  logE('check_models_test_mirrors_lib: ${violations.length} violation(s):');
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckModelsTestMirrorsLib(Directory.current.path));
}
