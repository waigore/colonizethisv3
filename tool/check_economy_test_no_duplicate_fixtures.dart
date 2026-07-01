import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix whose test sources must not re-introduce a local
/// copy of the shared game/world test fixtures (Refs #3823). The economy
/// package previously shipped `test/test_fixtures.dart`, a near-copy of
/// `package:colonizethis_test/game_test_fixtures.dart`. All economy tests now
/// import the shared `TestFixtures`; this gate keeps it that way.
const String _economyTestPathPrefix = 'packages/colonizethis_economy/test/';

/// Canonical shared fixtures import the economy tests must use instead of a
/// local copy.
const String economyTestSharedFixturesImport =
    "package:colonizethis_test/game_test_fixtures.dart";

/// Matches a top-level `TestFixtures` class declaration (optionally
/// `abstract` / `final` / `base` / `sealed` modifiers).
final RegExp _testFixturesClassDeclaration = RegExp(
  r'^\s*(?:abstract\s+|final\s+|base\s+|sealed\s+|interface\s+|mixin\s+)*'
  r'class\s+TestFixtures\b',
  multiLine: true,
);

/// True when the repo-relative [slashPath] is under the economy package `test/`.
bool economyTestNoDuplicateFixturesPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_economyTestPathPrefix);
}

/// Returns a violation reason when the economy test file identified by its
/// basename [fileName] (with [content]) re-introduces the shared fixtures
/// locally, or `null` when the file is compliant.
String? economyTestDuplicateFixturesViolationReason(
  String fileName,
  String content,
) {
  if (fileName == 'test_fixtures.dart') {
    return "re-adds a local `test_fixtures.dart`; import "
        "'$economyTestSharedFixturesImport' instead (Refs #3823)";
  }
  if (_testFixturesClassDeclaration.hasMatch(content)) {
    return "redefines a local `TestFixtures` class; import "
        "'$economyTestSharedFixturesImport' instead (Refs #3823)";
  }
  return null;
}

int runCheckEconomyTestNoDuplicateFixtures(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!economyTestNoDuplicateFixturesPathInScope(rel)) {
      continue;
    }
    final reason = economyTestDuplicateFixturesViolationReason(
      p.basename(rel),
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_economy_test_no_duplicate_fixtures: no duplicate-fixture '
      'violations.',
    );
    return 0;
  }
  logE(
    'check_economy_test_no_duplicate_fixtures: ${violations.length} '
    'violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckEconomyTestNoDuplicateFixtures(Directory.current.path));
}
