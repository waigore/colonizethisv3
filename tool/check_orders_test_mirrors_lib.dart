import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix for the orders package test tree (Refs #3714).
///
/// Orders production code lives under `lib/src/orders/`; the testing rule
/// (`colonizethis-testing.mdc`) mandates that `test/` mirrors `lib/`. This gate
/// keeps the orders test tree mirrored by forbidding loose Dart sources at the
/// `test/` root: every orders test (and its co-located support helper) must
/// live in a subdirectory such as `test/orders/` rather than flat in `test/`.
const String _ordersTestRootPrefix = 'packages/colonizethis_orders/test/';

/// True when the repo-relative [slashPath] is under the orders package `test/`.
bool ordersTestMirrorsLibPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_ordersTestRootPrefix);
}

/// Returns a violation reason when the orders test source at repo-relative
/// [slashPath] sits directly in the `test/` root (no mirroring subdirectory),
/// or `null` when the file is nested in a subdirectory (compliant) or out of
/// scope.
///
/// A loose root file is one whose remainder after the
/// `packages/colonizethis_orders/test/` prefix contains no further path
/// separator (for example `test/order_merge_part1_test.dart`). Nested files
/// such as `test/orders/order_merge_part1_test.dart` are compliant.
String? ordersTestMirrorsLibViolationReason(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_ordersTestRootPrefix)) {
    return null;
  }
  final remainder = normalized.substring(_ordersTestRootPrefix.length);
  if (remainder.isEmpty || remainder.contains('/')) {
    return null;
  }
  return 'lives directly in `test/`; move it under a subdirectory that mirrors '
      '`lib/src/` (for example `test/orders/`) per the testing-rule '
      '`test/`-mirrors-`lib/` policy (Refs #3714)';
}

int runCheckOrdersTestMirrorsLib(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!ordersTestMirrorsLibPathInScope(rel)) {
      continue;
    }
    final reason = ordersTestMirrorsLibViolationReason(rel);
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI('check_orders_test_mirrors_lib: no flat-root orders test sources.');
    return 0;
  }
  logE('check_orders_test_mirrors_lib: ${violations.length} violation(s):');
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckOrdersTestMirrorsLib(Directory.current.path));
}
