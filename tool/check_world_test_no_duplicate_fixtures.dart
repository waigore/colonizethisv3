import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Repo-relative path prefix whose test sources must not re-introduce a local
/// copy of the shared game/world test fixtures (Refs #3843). The world package
/// previously shipped `test/test_fixtures.dart`, a near-copy of
/// `package:colonizethis_test/game_test_fixtures.dart`. All world tests now
/// import the shared `TestFixtures`; this gate keeps it that way.
const String _worldTestPathPrefix = 'packages/colonizethis_world/test/';

/// Canonical shared fixtures import the world tests must use instead of a
/// local copy.
const String worldTestSharedFixturesImport =
    "package:colonizethis_test/game_test_fixtures.dart";

/// Matches a top-level `TestFixtures` class declaration (optionally
/// `abstract` / `final` / `base` / `sealed` modifiers).
final RegExp _testFixturesClassDeclaration = RegExp(
  r'^\s*(?:abstract\s+|final\s+|base\s+|sealed\s+|interface\s+|mixin\s+)*'
  r'class\s+TestFixtures\b',
  multiLine: true,
);

/// True when the repo-relative [slashPath] is under the world package `test/`.
bool worldTestNoDuplicateFixturesPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  return normalized.startsWith(_worldTestPathPrefix);
}

/// Returns a violation reason when the world test file identified by its
/// basename [fileName] (with [content]) re-introduces the shared fixtures
/// locally, or `null` when the file is compliant.
String? worldTestDuplicateFixturesViolationReason(
  String fileName,
  String content,
) {
  if (fileName == 'test_fixtures.dart') {
    return "re-adds a local `test_fixtures.dart`; import "
        "'$worldTestSharedFixturesImport' instead (Refs #3843)";
  }
  if (_testFixturesClassDeclaration.hasMatch(content)) {
    return "redefines a local `TestFixtures` class; import "
        "'$worldTestSharedFixturesImport' instead (Refs #3843)";
  }
  return null;
}

int runCheckWorldTestNoDuplicateFixtures(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!worldTestNoDuplicateFixturesPathInScope(rel)) {
      continue;
    }
    final reason = worldTestDuplicateFixturesViolationReason(
      p.basename(rel),
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_world_test_no_duplicate_fixtures: no duplicate-fixture '
      'violations.',
    );
    return 0;
  }
  logE(
    'check_world_test_no_duplicate_fixtures: ${violations.length} '
    'violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckWorldTestNoDuplicateFixtures(Directory.current.path));
}
