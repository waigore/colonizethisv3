import 'dart:io';

import 'package:path/path.dart' as p;

import 'ct_repo_lint_scan_contract.dart';

/// Canonical shared support for observer-phase NW-suppression predicate matrix
/// Game / snapshot fixtures (Refs #4310 Slice C).
const String
    observerGoalPhaseNwSuppressionPredicateMatrixSharedFixturesSupportFile =
    'packages/colonizethis_ai/test/support/'
    'observer_goal_phase_nw_suppression_predicate_matrix_test_support.dart';

const String _planningTestDir = 'packages/colonizethis_ai/test/planning/';

const Set<String>
    observerGoalPhaseNwSuppressionPredicateMatrixSharedFixtureAdopterBasenames =
    {
  'observer_goal_phase_nw_suppression_predicate_game_matrix_test.dart',
};

final RegExp _localGameWithTribeNwDecl =
    RegExp(r'Game\s+_gameWithTribeNw\b');
final RegExp _localGameWithGpOwnedNwDecl =
    RegExp(r'Game\s+_gameWithGpOwnedNw\b');
final RegExp _localExpandSnapshotDecl =
    RegExp(r'AIWorldSnapshot\s+_expandSnapshot\b');
final RegExp _localColonialLiteSnapshotDecl =
    RegExp(r'AIWorldSnapshot\s+_colonialLiteSnapshot\b');
final RegExp _localColonialSnapshotDecl =
    RegExp(r'AIWorldSnapshot\s+_colonialSnapshot\b');
final RegExp _localDevelopSnapshotDecl =
    RegExp(r'AIWorldSnapshot\s+_developSnapshot\b');

bool _isAdopterPath(String normalized) {
  if (!normalized.startsWith(_planningTestDir)) {
    return false;
  }
  return observerGoalPhaseNwSuppressionPredicateMatrixSharedFixtureAdopterBasenames
      .contains(p.basename(normalized));
}

bool aiObserverGoalPhaseNwSuppressionPredicateMatrixSharedFixturesPathInScope(
  String slashPath,
) {
  return _isAdopterPath(slashPath.replaceAll('\\', '/'));
}

String?
    aiObserverGoalPhaseNwSuppressionPredicateMatrixSharedFixturesViolationReason(
  String slashPath,
  String content,
) {
  final normalized = slashPath.replaceAll('\\', '/');
  if (!_isAdopterPath(normalized)) {
    return null;
  }
  if (_localGameWithTribeNwDecl.hasMatch(content)) {
    return 'redeclares local `_gameWithTribeNw`; import '
        '`observerGoalPhaseNwSuppressionMatrixGameWithTribeNw` from '
        '`$observerGoalPhaseNwSuppressionPredicateMatrixSharedFixturesSupportFile` '
        '(Refs #4310)';
  }
  if (_localGameWithGpOwnedNwDecl.hasMatch(content)) {
    return 'redeclares local `_gameWithGpOwnedNw`; import '
        '`observerGoalPhaseNwSuppressionMatrixGameWithGpOwnedNw` from '
        '`$observerGoalPhaseNwSuppressionPredicateMatrixSharedFixturesSupportFile` '
        '(Refs #4310)';
  }
  if (_localExpandSnapshotDecl.hasMatch(content)) {
    return 'redeclares local `_expandSnapshot`; import '
        '`kObserverGoalPhaseNwSuppressionMatrixExpandSnapshot` from '
        '`$observerGoalPhaseNwSuppressionPredicateMatrixSharedFixturesSupportFile` '
        '(Refs #4310)';
  }
  if (_localColonialLiteSnapshotDecl.hasMatch(content)) {
    return 'redeclares local `_colonialLiteSnapshot`; import '
        '`kObserverGoalPhaseNwSuppressionMatrixColonialLiteSnapshot` from '
        '`$observerGoalPhaseNwSuppressionPredicateMatrixSharedFixturesSupportFile` '
        '(Refs #4310)';
  }
  if (_localColonialSnapshotDecl.hasMatch(content)) {
    return 'redeclares local `_colonialSnapshot`; import '
        '`kObserverGoalPhaseNwSuppressionMatrixColonialSnapshot` from '
        '`$observerGoalPhaseNwSuppressionPredicateMatrixSharedFixturesSupportFile` '
        '(Refs #4310)';
  }
  if (_localDevelopSnapshotDecl.hasMatch(content)) {
    return 'redeclares local `_developSnapshot`; import '
        '`kObserverGoalPhaseNwSuppressionMatrixDevelopSnapshot` from '
        '`$observerGoalPhaseNwSuppressionPredicateMatrixSharedFixturesSupportFile` '
        '(Refs #4310)';
  }
  return null;
}

int runCheckAiObserverGoalPhaseNwSuppressionPredicateMatrixTestSharedFixtures(
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
    'observer_goal_phase_nw_suppression_predicate_matrix_test_support.dart',
  );
  if (!File(supportPath).existsSync()) {
    logE(
      'check_ai_observer_goal_phase_nw_suppression_predicate_matrix_test_shared_fixtures: '
      'missing shared support file '
      '`$observerGoalPhaseNwSuppressionPredicateMatrixSharedFixturesSupportFile`.',
    );
    return 1;
  }

  final violations = <String>[];
  for (final file in collectRepoLintDomainDartFiles(repoRoot)) {
    final rel = p.relative(file.path, from: repoRoot).replaceAll('\\', '/');
    final reason =
        aiObserverGoalPhaseNwSuppressionPredicateMatrixSharedFixturesViolationReason(
      rel,
      file.readAsStringSync(),
    );
    if (reason != null) {
      violations.add('$rel: $reason');
    }
  }

  if (violations.isEmpty) {
    logI(
      'check_ai_observer_goal_phase_nw_suppression_predicate_matrix_test_shared_fixtures: '
      'no local NW-suppression predicate matrix fixture redeclarations.',
    );
    return 0;
  }
  logE(
    'check_ai_observer_goal_phase_nw_suppression_predicate_matrix_test_shared_fixtures: '
    '${violations.length} violation(s):',
  );
  for (final violation in violations) {
    logE(' - $violation');
  }
  return 1;
}

void main() {
  exit(
    runCheckAiObserverGoalPhaseNwSuppressionPredicateMatrixTestSharedFixtures(
      Directory.current.path,
    ),
  );
}
