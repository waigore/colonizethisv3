import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Canonical shared support for primary GP blocker tiebreak Game fixtures
/// (Refs #4310 Slice C).
const String primaryGpBlockerTiebreakSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'primary_gp_blocker_tiebreak_test_support.dart';

const String _planningTestDir = 'packages/colonizethis_ai/test/planning/';

/// Adopters that must import shared primary GP blocker tiebreak fixtures.
const Set<String> primaryGpBlockerTiebreakSharedFixtureAdopterBasenames = {
  'primary_gp_blocker_tiebreak_test.dart',
};

final RegExp _localGameForOwBlockerDecl =
    RegExp(r'Game\s+_gameForOwBlocker\b');
final RegExp _localGameForNwBlockerDecl =
    RegExp(r'Game\s+_gameForNwBlocker\b');
final RegExp _localExpandSnapshotForOwDecl =
    RegExp(r'AIWorldSnapshot\s+_expandSnapshotForOw\b');
final RegExp _localColonialSnapshotForNwDecl =
    RegExp(r'AIWorldSnapshot\s+_colonialSnapshotForNw\b');

bool _isPrimaryGpBlockerTiebreakAdopterPath(String normalized) {
  if (!normalized.startsWith(_planningTestDir)) {
    return false;
  }
  return primaryGpBlockerTiebreakSharedFixtureAdopterBasenames
      .contains(p.basename(normalized));
}

/// True when [slashPath] is in scope for the primary GP blocker fixture gate.
bool aiPrimaryGpBlockerTiebreakSharedFixturesPathInScope(String slashPath) {
  return _isPrimaryGpBlockerTiebreakAdopterPath(
    slashPath.replaceAll('\\', '/'),
  );
}

/// Returns a violation when an adopter redeclares a local Game/snapshot
/// factory that must live in shared support.
String? aiPrimaryGpBlockerTiebreakSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!_isPrimaryGpBlockerTiebreakAdopterPath(normalized)) {
    return null;
  }
  if (_localGameForOwBlockerDecl.hasMatch(content)) {
    return 'redeclares local `_gameForOwBlocker`; import '
        '`primaryGpBlockerTiebreakGameForOwBlocker` from '
        '`$primaryGpBlockerTiebreakSharedFixturesSupportFile` (Refs #4310)';
  }
  if (_localGameForNwBlockerDecl.hasMatch(content)) {
    return 'redeclares local `_gameForNwBlocker`; import '
        '`primaryGpBlockerTiebreakGameForNwBlocker` from '
        '`$primaryGpBlockerTiebreakSharedFixturesSupportFile` (Refs #4310)';
  }
  if (_localExpandSnapshotForOwDecl.hasMatch(content)) {
    return 'redeclares local `_expandSnapshotForOw`; import '
        '`primaryGpBlockerTiebreakExpandSnapshotForOw` from '
        '`$primaryGpBlockerTiebreakSharedFixturesSupportFile` (Refs #4310)';
  }
  if (_localColonialSnapshotForNwDecl.hasMatch(content)) {
    return 'redeclares local `_colonialSnapshotForNw`; import '
        '`primaryGpBlockerTiebreakColonialSnapshotForNw` from '
        '`$primaryGpBlockerTiebreakSharedFixturesSupportFile` (Refs #4310)';
  }
  return null;
}

int runCheckAiPrimaryGpBlockerTiebreakTestSharedFixtures(
  String repoRoot, {
  void Function(String line)? info,
  void Function(String line)? err,
}) {
  final logI = info ?? stdout.writeln;
  final logE = err ?? stderr.writeln;

  final supportPath = p.join(
    repoRoot,
    'packages',
    'colonizethis_ai',
    'test',
    'support',
    'primary_gp_blocker_tiebreak_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_primary_gp_blocker_tiebreak_test_shared_fixtures: missing '
      'shared support file '
      '`$primaryGpBlockerTiebreakSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason = aiPrimaryGpBlockerTiebreakSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_primary_gp_blocker_tiebreak_test_shared_fixtures: no local '
      'primary GP blocker tiebreak fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_primary_gp_blocker_tiebreak_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiPrimaryGpBlockerTiebreakTestSharedFixtures(
      Directory.current.path,
    ),
  );
}
