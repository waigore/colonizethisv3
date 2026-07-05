import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// SPEC: SPEC/program/repo-lint.md (Refs #3877).
///
/// Forbid cross-package `package:colonizethis_<pkg>/src/` imports in orders
/// tests. Self-imports of `package:colonizethis_orders/src/...` remain allowed.
const _ordersTestPrefix = 'packages/colonizethis_orders/test/';

final RegExp _forbiddenCrossPackageSrcImport = RegExp(
  r'''import\s+['"]package:colonizethis_([a-z_]+)/src/[^'"]+['"]\s*;''',
);

bool ordersTestNoSrcImportsPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_ordersTestPrefix) &&
      normalized.endsWith('.dart');
}

String? ordersTestNoSrcImportsViolationReason(
  String slashPath,
  String content,
) {
  for (final match in _forbiddenCrossPackageSrcImport.allMatches(content)) {
    final pkg = match.group(1)!;
    if (pkg == 'orders') continue;
    return 'use the owning package barrel instead of '
        'package:colonizethis_$pkg/src/ imports (Refs #3877)';
  }
  return null;
}

int runCheckOrdersTestNoSrcImports(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!ordersTestNoSrcImportsPathInScope(rel)) {
      continue;
    }
    final content = file.readAsStringSync();
    final reason = ordersTestNoSrcImportsViolationReason(rel, content);
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI('check_orders_test_no_src_imports: no cross-package src/ import violations.');
    return 0;
  }
  logE(
    'check_orders_test_no_src_imports: ${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckOrdersTestNoSrcImports(Directory.current.path));
}
