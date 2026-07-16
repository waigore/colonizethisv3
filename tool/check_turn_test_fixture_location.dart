import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Fixture / test-support modules for `colonizethis_turn` must live under
/// `packages/colonizethis_turn/test/support/` (Refs #4039).
const _testRoot = 'packages/colonizethis_turn/test/';
const _supportRoot = 'packages/colonizethis_turn/test/support/';

bool _isFixtureOrSupportBasename(String fileName) {
  return fileName.endsWith('_fixtures.dart') ||
      fileName.endsWith('_test_support.dart');
}

bool turnTestFixtureLocationPathInScope(String slashPath) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!normalized.startsWith(_testRoot)) {
    return false;
  }
  if (normalized.startsWith(_supportRoot)) {
    return false;
  }
  return _isFixtureOrSupportBasename(p.basename(normalized));
}

String? turnTestFixtureLocationViolationReason(String relPath) {
  return '$relPath: fixture/support module must live under '
      '`packages/colonizethis_turn/test/support/` (Refs #4039)';
}

int runCheckTurnTestFixtureLocation(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    if (!turnTestFixtureLocationPathInScope(rel)) {
      continue;
    }
    violations.add(turnTestFixtureLocationViolationReason(rel)!);
  }

  if (violations.isEmpty) {
    logI('check_turn_test_fixture_location: no misplaced fixture modules.');
    return 0;
  }
  logE('check_turn_test_fixture_location: ${violations.length} violation(s):');
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(runCheckTurnTestFixtureLocation(Directory.current.path));
}
