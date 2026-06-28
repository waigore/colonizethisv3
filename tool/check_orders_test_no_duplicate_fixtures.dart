import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix whose test sources must not re-introduce a local
/// copy of the shared game/world test fixtures (Refs #3714). The orders package
/// previously shipped `test/test_fixtures.dart`, a near-byte-identical copy of
/// `package:colonizethis_test/game_test_fixtures.dart`. All orders tests now
/// import the shared `TestFixtures`; this gate keeps it that way.
const String _ordersTestPathPrefix = 'packages/colonizethis_orders/test/';

/// Canonical shared fixtures import the orders tests must use instead of a
/// local copy.
const String ordersTestSharedFixturesImport =
    "package:colonizethis_test/game_test_fixtures.dart";

/// Matches a top-level `TestFixtures` class declaration (optionally
/// `abstract` / `final` / `base` / `sealed` modifiers), e.g.
/// `abstract final class TestFixtures {`.
final RegExp _testFixturesClassDeclaration = RegExp(
  r'^\s*(?:abstract\s+|final\s+|base\s+|sealed\s+|interface\s+|mixin\s+)*'
  r'class\s+TestFixtures\b',
  multiLine: true,
);

/// True when the repo-relative [slashPath] is under the orders package `test/`.
bool ordersTestNoDuplicateFixturesPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_ordersTestPathPrefix);
}

/// Returns a violation reason when the orders test file identified by its
/// basename [fileName] (with [content]) re-introduces the shared fixtures
/// locally, or `null` when the file is compliant.
///
/// Two regressions are blocked:
/// 1. A file named `test_fixtures.dart` (the deleted local copy), and
/// 2. Any test file that redeclares a `TestFixtures` class instead of
///    importing the shared `colonizethis_test` factories.
String? ordersTestDuplicateFixturesViolationReason(
  String fileName,
  String content,
) {
  if (fileName == 'test_fixtures.dart') {
    return "re-adds a local `test_fixtures.dart`; import "
        "'$ordersTestSharedFixturesImport' instead (Refs #3714)";
  }
  if (_testFixturesClassDeclaration.hasMatch(content)) {
    return "redefines a local `TestFixtures` class; import "
        "'$ordersTestSharedFixturesImport' instead (Refs #3714)";
  }
  return null;
}

int runCheckOrdersTestNoDuplicateFixtures(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!ordersTestNoDuplicateFixturesPathInScope(rel)) {
      continue;
    }
    final reason = ordersTestDuplicateFixturesViolationReason(
      p.basename(rel),
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_orders_test_no_duplicate_fixtures: no duplicate-fixture '
      'violations.',
    );
    return 0;
  }
  logE(
    'check_orders_test_no_duplicate_fixtures: ${violations.length} '
    'violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckOrdersTestNoDuplicateFixtures(Directory.current.path));
}
