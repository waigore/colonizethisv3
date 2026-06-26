import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix whose test sources must not re-introduce a local
/// copy of the shared game/world test fixtures (Refs #3716). The combat
/// package previously shipped `test/test_fixtures.dart`, a byte-identical
/// subset (modulo two doc-comment lines) of
/// `package:colonizethis_test/game_test_fixtures.dart`. All combat tests now
/// import the shared `TestFixtures`; this gate keeps it that way.
const String _combatTestPathPrefix = 'packages/colonizethis_combat/test/';

/// Canonical shared fixtures import the combat tests must use instead of a
/// local copy.
const String combatTestSharedFixturesImport =
    "package:colonizethis_test/game_test_fixtures.dart";

/// Matches a top-level `TestFixtures` class declaration (optionally
/// `abstract` / `final` / `base` / `sealed` / `interface` / `mixin`
/// modifiers), e.g. `abstract final class TestFixtures {`.
final RegExp _testFixturesClassDeclaration = RegExp(
  r'^\s*(?:abstract\s+|final\s+|base\s+|sealed\s+|interface\s+|mixin\s+)*'
  r'class\s+TestFixtures\b',
  multiLine: true,
);

/// True when the repo-relative [slashPath] is under the combat package `test/`.
bool combatTestNoDuplicateFixturesPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_combatTestPathPrefix);
}

/// Returns a violation reason when the combat test file identified by its
/// basename [fileName] (with [content]) re-introduces the shared fixtures
/// locally, or `null` when the file is compliant.
///
/// Two regressions are blocked:
/// 1. A file named `test_fixtures.dart` (the deleted local copy), and
/// 2. Any test file that redeclares a `TestFixtures` class instead of
///    importing the shared `colonizethis_test` factories.
String? combatTestDuplicateFixturesViolationReason(
  String fileName,
  String content,
) {
  if (fileName == 'test_fixtures.dart') {
    return "re-adds a local `test_fixtures.dart`; import "
        "'$combatTestSharedFixturesImport' instead (Refs #3716)";
  }
  if (_testFixturesClassDeclaration.hasMatch(content)) {
    return "redefines a local `TestFixtures` class; import "
        "'$combatTestSharedFixturesImport' instead (Refs #3716)";
  }
  return null;
}

int runCheckCombatTestNoDuplicateFixtures(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!combatTestNoDuplicateFixturesPathInScope(rel)) {
      continue;
    }
    final reason = combatTestDuplicateFixturesViolationReason(
      p.basename(rel),
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_combat_test_no_duplicate_fixtures: no duplicate-fixture '
      'violations.',
    );
    return 0;
  }
  logE(
    'check_combat_test_no_duplicate_fixtures: ${violations.length} '
    'violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckCombatTestNoDuplicateFixtures(Directory.current.path));
}
