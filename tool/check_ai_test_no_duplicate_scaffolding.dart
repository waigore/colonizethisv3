import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix whose test sources must keep shared scaffolding
/// coherent (Refs #3717). The AI package previously shipped an AI-local
/// `test/planning/test_fixtures.dart` (confusingly named identically to the
/// shared `colonizethis_test` `TestFixtures`) and kept a `_test.dart` inside
/// the `test/support/` scaffolding directory. This gate keeps both regressions
/// from returning.
const String _aiTestPathPrefix = 'packages/colonizethis_ai/test/';

/// Canonical shared fixtures import. AI tests must never redeclare a top-level
/// `TestFixtures` class; AI-specific fixtures use a disambiguated name (e.g.
/// `ai_planner_fixtures.dart`).
const String aiTestSharedFixturesImport =
    "package:colonizethis_test/game_test_fixtures.dart";

/// `test/support/` segment (POSIX) under the AI package; `_test.dart` files
/// must not live here — scaffolding only.
const String _aiTestSupportDirFragment =
    'packages/colonizethis_ai/test/support/';

/// Matches a top-level `TestFixtures` class declaration (optionally
/// `abstract` / `final` / `base` / `sealed` / `interface` / `mixin`
/// modifiers), e.g. `abstract final class TestFixtures {`.
final RegExp _testFixturesClassDeclaration = RegExp(
  r'^\s*(?:abstract\s+|final\s+|base\s+|sealed\s+|interface\s+|mixin\s+)*'
  r'class\s+TestFixtures\b',
  multiLine: true,
);

/// True when the repo-relative [slashPath] is under the AI package `test/`.
bool aiTestNoDuplicateScaffoldingPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_aiTestPathPrefix);
}

/// Returns a violation reason when the in-scope AI test file at repo-relative
/// [slashPath] (with basename [fileName] and [content]) re-introduces
/// fragmented/duplicate scaffolding, or `null` when compliant.
///
/// Three regressions are blocked:
/// 1. A `_test.dart` living inside `test/support/` (scaffolding dir),
/// 2. A file named `test_fixtures.dart` (confusing shadow of the shared
///    `TestFixtures`; AI fixtures must use a disambiguated name), and
/// 3. Any AI test file that redeclares a top-level `TestFixtures` class
///    instead of importing the shared `colonizethis_test` factories.
String? aiTestDuplicateScaffoldingViolationReason(
  String slashPath,
  String fileName,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (normalized.startsWith(_aiTestSupportDirFragment) &&
      fileName.endsWith('_test.dart')) {
    return "lives inside `test/support/`; move test files out of the "
        "scaffolding directory (e.g. `test/support_test/`) (Refs #3717)";
  }
  if (fileName == 'test_fixtures.dart') {
    return "uses the confusing `test_fixtures.dart` name (shadows the shared "
        "`TestFixtures`); use an AI-specific name such as "
        "`ai_planner_fixtures.dart` (Refs #3717)";
  }
  if (_testFixturesClassDeclaration.hasMatch(content)) {
    return "redefines a local `TestFixtures` class; import "
        "'$aiTestSharedFixturesImport' instead (Refs #3717)";
  }
  return null;
}

int runCheckAiTestNoDuplicateScaffolding(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!aiTestNoDuplicateScaffoldingPathInScope(rel)) {
      continue;
    }
    final reason = aiTestDuplicateScaffoldingViolationReason(
      rel,
      p.basename(rel),
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_test_no_duplicate_scaffolding: no duplicate-scaffolding '
      'violations.',
    );
    return 0;
  }
  logE(
    'check_ai_test_no_duplicate_scaffolding: ${violations.length} '
    'violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckAiTestNoDuplicateScaffolding(Directory.current.path));
}
