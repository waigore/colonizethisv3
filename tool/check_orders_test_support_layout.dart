import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// SPEC: SPEC/program/repo-lint.md (Refs #3949).
///
/// Non-`*_test.dart` Dart under `packages/colonizethis_orders/test/orders/`
/// must live under `test/orders/support/` so fixtures/helpers/scenario tables
/// stay co-located (wave-3 support consolidation).

const _ordersOrdersTestPrefix = 'packages/colonizethis_orders/test/orders/';
const _ordersSupportPrefix =
    'packages/colonizethis_orders/test/orders/support/';

/// True when [slashPath] is under colonizethis_orders `test/orders/`.
bool ordersTestSupportLayoutPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_ordersOrdersTestPrefix) &&
      normalized.endsWith('.dart');
}

/// Returns a violation reason when a non-test Dart file under `test/orders/`
/// sits outside `support/`, or `null` when compliant / out of scope.
String? ordersTestSupportLayoutViolationReason(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!ordersTestSupportLayoutPathInScope(normalized)) {
    return null;
  }
  final fileName = p.basename(normalized);
  if (fileName.endsWith('_test.dart')) {
    return null;
  }
  if (normalized.startsWith(_ordersSupportPrefix)) {
    return null;
  }
  return 'non-test Dart under `test/orders/` must live under '
      '`test/orders/support/` (Refs #3949)';
}

int runCheckOrdersTestSupportLayout(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = ordersTestSupportLayoutViolationReason(rel);
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_orders_test_support_layout: all non-test orders Dart lives under '
      'test/orders/support/.',
    );
    return 0;
  }
  logE(
    'check_orders_test_support_layout: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckOrdersTestSupportLayout(Directory.current.path));
}
