import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Canonical shared support for COLONIAL-lite precondition Game fixtures
/// (Refs #4310 Slice C).
const String observerGoalPhaseColonialLitePreconditionsSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'observer_goal_phase_colonial_lite_preconditions_test_support.dart';

const String _planningTestDir = 'packages/colonizethis_ai/test/planning/';

const Set<String>
    observerGoalPhaseColonialLitePreconditionsSharedFixtureAdopterBasenames = {
  'observer_goal_phase_colonial_lite_preconditions_test.dart',
};

final RegExp _localSnapshotOwDecl = RegExp(r'AIWorldSnapshot\s+_snapshotOw\b');
final RegExp _localGameWithNwOwnerDecl =
    RegExp(r'Game\s+_gameWithNwOwner\b');
final RegExp _localGameWithNwOwnersDecl =
    RegExp(r'Game\s+_gameWithNwOwners\b');

bool _isAdopterPath(String normalized) {
  if (!normalized.startsWith(_planningTestDir)) {
    return false;
  }
  return observerGoalPhaseColonialLitePreconditionsSharedFixtureAdopterBasenames
      .contains(p.basename(normalized));
}

bool aiObserverGoalPhaseColonialLitePreconditionsSharedFixturesPathInScope(
  String slashPath,
) {
  return _isAdopterPath(slashPath.replaceAll('\\', '/'));
}

String? aiObserverGoalPhaseColonialLitePreconditionsSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!_isAdopterPath(normalized)) {
    return null;
  }
  if (_localSnapshotOwDecl.hasMatch(content)) {
    return 'redeclares local `_snapshotOw`; import '
        '`observerGoalPhaseColonialLiteSnapshotOw` from '
        '`$observerGoalPhaseColonialLitePreconditionsSharedFixturesSupportFile` '
        '(Refs #4310)';
  }
  if (_localGameWithNwOwnerDecl.hasMatch(content)) {
    return 'redeclares local `_gameWithNwOwner`; import '
        '`observerGoalPhaseColonialLiteGameWithNwOwner` from '
        '`$observerGoalPhaseColonialLitePreconditionsSharedFixturesSupportFile` '
        '(Refs #4310)';
  }
  if (_localGameWithNwOwnersDecl.hasMatch(content)) {
    return 'redeclares local `_gameWithNwOwners`; import '
        '`observerGoalPhaseColonialLiteGameWithNwOwners` from '
        '`$observerGoalPhaseColonialLitePreconditionsSharedFixturesSupportFile` '
        '(Refs #4310)';
  }
  return null;
}

int runCheckAiObserverGoalPhaseColonialLitePreconditionsTestSharedFixtures(
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
    'observer_goal_phase_colonial_lite_preconditions_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_observer_goal_phase_colonial_lite_preconditions_test_shared_fixtures: '
      'missing shared support file '
      '`$observerGoalPhaseColonialLitePreconditionsSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason =
        aiObserverGoalPhaseColonialLitePreconditionsSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_observer_goal_phase_colonial_lite_preconditions_test_shared_fixtures: '
      'no local COLONIAL-lite precondition fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_observer_goal_phase_colonial_lite_preconditions_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiObserverGoalPhaseColonialLitePreconditionsTestSharedFixtures(
      Directory.current.path,
    ),
  );
}
