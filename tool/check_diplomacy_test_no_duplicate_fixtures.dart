import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix whose test sources must not re-introduce a local
/// copy of the shared game/world test fixtures (Refs #3715). The diplomacy
/// package previously shipped `test/test_fixtures.dart`, a byte-identical
/// subset of `package:colonizethis_test/game_test_fixtures.dart`. All diplomacy
/// tests now import the shared `TestFixtures`; this gate keeps it that way.
const String _diplomacyTestPathPrefix = 'packages/colonizethis_diplomacy/test/';

/// Canonical shared fixtures import the diplomacy tests must use instead of a
/// local copy.
const String diplomacyTestSharedFixturesImport =
    "package:colonizethis_test/game_test_fixtures.dart";

/// Matches a top-level `TestFixtures` class declaration (optionally
/// `abstract` / `final` / `base` / `sealed` modifiers), e.g.
/// `abstract final class TestFixtures {`.
final RegExp _testFixturesClassDeclaration = RegExp(
  r'^\s*(?:abstract\s+|final\s+|base\s+|sealed\s+|interface\s+|mixin\s+)*'
  r'class\s+TestFixtures\b',
  multiLine: true,
);

/// True when the repo-relative [slashPath] is under the diplomacy package `test/`.
bool diplomacyTestNoDuplicateFixturesPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_diplomacyTestPathPrefix);
}

/// Returns a violation reason when the diplomacy test file identified by its
/// basename [fileName] (with [content]) re-introduces the shared fixtures
/// locally, or `null` when the file is compliant.
///
/// Two regressions are blocked:
/// 1. A file named `test_fixtures.dart` (the deleted local copy), and
/// 2. Any test file that redeclares a `TestFixtures` class instead of
///    importing the shared `colonizethis_test` factories.
String? diplomacyTestDuplicateFixturesViolationReason(
  String fileName,
  String content,
) {
  if (fileName == 'test_fixtures.dart') {
    return "re-adds a local `test_fixtures.dart`; import "
        "'$diplomacyTestSharedFixturesImport' instead (Refs #3715)";
  }
  if (_testFixturesClassDeclaration.hasMatch(content)) {
    return "redefines a local `TestFixtures` class; import "
        "'$diplomacyTestSharedFixturesImport' instead (Refs #3715)";
  }
  return null;
}

int runCheckDiplomacyTestNoDuplicateFixtures(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!diplomacyTestNoDuplicateFixturesPathInScope(rel)) {
      continue;
    }
    final reason = diplomacyTestDuplicateFixturesViolationReason(
      p.basename(rel),
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_diplomacy_test_no_duplicate_fixtures: no duplicate-fixture '
      'violations.',
    );
    return 0;
  }
  logE(
    'check_diplomacy_test_no_duplicate_fixtures: ${violations.length} '
    'violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckDiplomacyTestNoDuplicateFixtures(Directory.current.path));
}
